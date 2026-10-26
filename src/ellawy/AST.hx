package ellawy;

import ellawy.AST;
import ellawy.EllawyError;

class Interpreter {
    var environment:Map<String, Dynamic>;
    var file:String;

    public function new(file:String = null) {
        this.environment = new Map();
        this.file = file;
        
        environment.set("print", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
            Sys.println(args.map(Std.string).join("\t"));
        }));
        
        environment.set("type", Reflect.makeVarArgs(function(args:Array<Dynamic>) {
            if (args.length == 0) return "null";
            return Type.typeof(args[0]).getName();
        }));
    }

    public function interpret(statements:Array<Stmt>):Dynamic {
        for (stmt in statements) {
            var result = execute(stmt);
            if (result != null && result.isReturn) {
                return result.value;
            }
        }
        return null;
    }

    function execute(stmt:Stmt):Dynamic {
        return switch stmt {
            case Local(name, typeName, initializer):
                var value = initializer != null ? evaluate(initializer) : null;
                environment.set(name, value);
                null;
                
            case Expression(expr):
                evaluate(expr);
                null;
                
            case Return(value):
                { isReturn: true, value: value != null ? evaluate(value) : null };
                
            case Block(statements):
                for (s in statements) {
                    var res = execute(s);
                    if (res != null && res.isReturn) return res;
                }
                null;
                
            case If(condition, thenBranch, elseBranch):
                if (isTruthy(evaluate(condition))) {
                    for (s in thenBranch) {
                        var res = execute(s);
                        if (res != null && res.isReturn) return res;
                    }
                } else if (elseBranch != null) {
                    for (s in elseBranch) {
                        var res = execute(s);
                        if (res != null && res.isReturn) return res;
                    }
                }
                null;
                
            case While(condition, body):
                while (isTruthy(evaluate(condition))) {
                    for (s in body) {
                        var res = execute(s);
                        if (res != null && res.isReturn) return res;
                    }
                }
                null;
                
            case Function(decl):
                var func = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                    var prevEnv = environment;
                    environment = new Map();
                    for (k in prevEnv.keys()) environment.set(k, prevEnv.get(k));
                    
                    for (i in 0...Math.min(args.length, decl.parameters.length)) {
                        environment.set(decl.parameters[i].name, args[i]);
                    }
                    
                    var result:Dynamic = null;
                    for (s in decl.body) {
                        var res = execute(s);
                        if (res != null && res.isReturn) {
                            result = res.value;
                            break;
                        }
                    }
                    environment = prevEnv;
                    return result;
                });
                environment.set(decl.name, func);
                null;
                
            case Class(decl):
                var cls = Reflect.makeVarArgs(function(args:Array<Dynamic>) {
                    var obj = {};
                    for (member in decl.members) {
                        switch member {
                            case Local(name, _, initializer):
                                Reflect.setField(obj, name, initializer != null ? evaluate(initializer) : null);
                            case Function(fDecl):
                                if (!fDecl.isStatic) {
                                    Reflect.setField(obj, fDecl.name, Reflect.makeVarArgs(function(mArgs:Array<Dynamic>) {
                                        var prevEnv = environment;
                                        environment = new Map();
                                        for (k in prevEnv.keys()) environment.set(k, prevEnv.get(k));
                                        environment.set("self", obj);
                                        
                                        for (i in 0...Math.min(mArgs.length, fDecl.parameters.length)) {
                                            environment.set(fDecl.parameters[i].name, mArgs[i]);
                                        }
                                        
                                        var result:Dynamic = null;
                                        for (s in fDecl.body) {
                                            var res = execute(s);
                                            if (res != null && res.isReturn) {
                                                result = res.value;
                                                break;
                                            }
                                        }
                                        environment = prevEnv;
                                        return result;
                                    }));
                                }
                            default:
                        }
                    }
                    return obj;
                });
                environment.set(decl.name, cls);
                null;
                
            case Import(path):
                var possiblePath = path.split(".").join("/") + ".ellawy";
                if (sys.FileSystem.exists(possiblePath)) {
                    var source = sys.io.File.getContent(possiblePath);
                    var ast = ellawy.Ellawy.parse(source, possiblePath);
                    for (stmt in ast) {
                        var res = execute(stmt);
                        if (res != null && res.isReturn) return res;
                    }
                }
                null;
        }
    }

    function evaluate(expr:Expr):Dynamic {
        return switch expr {
            case Literal(value): value;
                
            case Identifier(name):
                if (environment.exists(name)) environment.get(name) 
                else throw error('Undefined variable "$name".');
                
            case Unary(op, right):
                var r = evaluate(right);
                switch op {
                    case "-": return -r;
                    case "not": return !isTruthy(r);
                    default: throw error('Unknown unary operator "$op".');
                }
                
            case Binary(left, op, right):
                var l = evaluate(left);
                var r = evaluate(right);
                switch op {
                    case "+": return l + r;
                    case "-": return l - r;
                    case "*": return l * r;
                    case "/": return l / r;
                    case "%": return l % r;
                    case "==": return l == r;
                    case "!=": return l != r;
                    case "<": return l < r;
                    case "<=": return l <= r;
                    case ">": return l > r;
                    case ">=": return l >= r;
                    case "&&": return isTruthy(l) && isTruthy(r);
                    case "||": return isTruthy(l) || isTruthy(r);
                    default: throw error('Unknown binary operator "$op".');
                }
                
            case Call(callee, arguments):
                var target = evaluate(callee);
                var args = arguments.map(evaluate);
                if (Reflect.isFunction(target)) {
                    return (cast target : Array<Dynamic> -> Dynamic)(args);
                }
                throw error('Can only call functions and classes.');
                
            case Member(object, name):
                var obj = evaluate(object);
                if (obj == null) throw error('Cannot access "$name" on null.');
                if (Reflect.hasField(obj, name)) return Reflect.field(obj, name);
                throw error('Undefined property "$name".');
                
            case ArrayLiteral(items):
                items.map(evaluate);
                
            case ObjectLiteral(fields):
                var obj = {};
                for (f in fields) Reflect.setField(obj, f.name, evaluate(f.value));
                obj;
                
            case NewObject(className, arguments):
                var cls = evaluate(Identifier(className));
                if (!Reflect.isFunction(cls)) throw error('"$className" is not a class.');
                var args = arguments.map(evaluate);
                return (cast cls : Array<Dynamic> -> Dynamic)(args);
        }
    }

    function isTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (value == false) return false;
        return true;
    }

    function error(message:String):EllawyError {
        return new EllawyError(message, 0, 0, file);
    }
}
