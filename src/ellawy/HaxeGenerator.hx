package ellawy;

class HaxeGenerator {
    final out:StringBuf = new StringBuf();
    var indent:Int = 0;

    public static function generate(statements:Array<Stmt>):String {
        var g = new HaxeGenerator();
        g.writeStatements(statements);
        return g.out.toString();
    }

    function new() {}

    function writeStatements(statements:Array<Stmt>):Void {
        for (s in statements) writeStmt(s);
    }

    function writeStmt(s:Stmt):Void {
        switch (s) {
            case Import(path):
                line("import " + path + ";");
            case Local(name, typeName, initializer):
                var text = "var " + name;
                if (typeName != null) text += ":" + typeName;
                if (initializer != null) text += " = " + expr(initializer);
                line(text + ";");
            case Expression(e):
                line(expr(e) + ";");
            case Return(e):
                line(e == null ? "return;" : "return " + expr(e) + ";");
            case Block(statements):
                line("{");
                indent++;
                writeStatements(statements);
                indent--;
                line("}");
            case If(condition, thenBranch, elseBranch):
                line("if (" + expr(condition) + ") {");
                indent++;
                writeStatements(thenBranch);
                indent--;
                line("}");
                if (elseBranch != null) {
                    line("else {");
                    indent++;
                    writeStatements(elseBranch);
                    indent--;
                    line("}");
                }
            case While(condition, body):
                line("while (" + expr(condition) + ") {");
                indent++;
                writeStatements(body);
                indent--;
                line("}");
            case Function(decl):
                writeFunction(decl);
            case Class(decl):
                writeClass(decl);
        }
    }

    function writeFunction(d:FunctionDecl):Void {
        var prefix = d.visibility + " ";
        if (d.isStatic) prefix += "static ";
        var params = new Array<String>();
        for (p in d.parameters) {
            var v = p.name;
            if (p.typeName != null) v += ":" + p.typeName;
            if (p.defaultValue != null) v += " = " + expr(p.defaultValue);
            params.push(v);
        }
        var ret = d.returnType == null ? "" : ":" + d.returnType;
        line(prefix + "function " + d.name + "(" + params.join(", ") + ")" + ret + " {");
        indent++;
        writeStatements(d.body);
        indent--;
        line("}");
    }

    function writeClass(d:ClassDecl):Void {
        var header = "class " + d.name;
        if (d.extendsName != null) header += " extends " + d.extendsName;
        line(header + " {");
        indent++;
        for (m in d.members) {
            switch (m) {
                case Local(name, typeName, initializer):
                    var v = "public var " + name;
                    if (typeName != null) v += ":" + typeName;
                    if (initializer != null) v += " = " + expr(initializer);
                    line(v + ";");
                case Function(f): writeFunction(f);
                default: throw new EllawyError("Unsupported class member.");
            }
        }
        indent--;
        line("}");
    }

    function expr(e:Expr):String {
        return switch (e) {
            case Literal(v): literal(v);
            case Identifier(name): name;
            case Unary(op, right): op + expr(right);
            case Binary(left, op, right): "(" + expr(left) + " " + op + " " + expr(right) + ")";
            case Call(callee, args): expr(callee) + "(" + joinExpr(args) + ")";
            case Member(object, name): expr(object) + "." + name;
            case ArrayLiteral(items): "[" + joinExpr(items) + "]";
            case ObjectLiteral(fields):
                "{" + fields.map(function(f) return f.name + ": " + expr(f.value)).join(", ") + "}";
            case NewObject(name, args): "new " + name + "(" + joinExpr(args) + ")";
        };
    }

    function joinExpr(a:Array<Expr>):String {
        return a.map(expr).join(", ");
    }

    function literal(v:Dynamic):String {
        if (v == null) return "null";
        if (Std.isOfType(v, String)) return '"' + escape(Std.string(v)) + '"';
        if (Std.isOfType(v, Bool)) return v ? "true" : "false";
        return Std.string(v);
    }

    function escape(s:String):String {
        return s.split("\\").join("\\\\").split('"').join('\\"')
            .split("\n").join("\\n").split("\r").join("\\r").split("\t").join("\\t");
    }

    function line(s:String):Void {
        for (_ in 0...indent) out.add("    ");
        out.add(s);
        out.add("\n");
    }
}
