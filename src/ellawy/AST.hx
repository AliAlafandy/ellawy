package ellawy;

enum Expr {
    Literal(value:Dynamic);
    Identifier(name:String);
    Unary(operator:String, right:Expr);
    Binary(left:Expr, operator:String, right:Expr);
    Call(callee:Expr, arguments:Array<Expr>);
    Member(object:Expr, name:String);
    ArrayLiteral(items:Array<Expr>);
    ObjectLiteral(fields:Array<ObjectField>);
    NewObject(className:String, arguments:Array<Expr>);
}

typedef ObjectField = {
    name:String,
    value:Expr
};

enum Stmt {
    Local(name:String, typeName:Null<String>, initializer:Null<Expr>);
    Expression(expression:Expr);
    Return(value:Null<Expr>);
    Block(statements:Array<Stmt>);
    If(condition:Expr, thenBranch:Array<Stmt>, elseBranch:Null<Array<Stmt>>);
    While(condition:Expr, body:Array<Stmt>);
    Function(declaration:FunctionDecl);
    Class(declaration:ClassDecl);
    Import(path:String);
}

typedef Parameter = {
    name:String,
    typeName:Null<String>,
    defaultValue:Null<Expr>
};

typedef FunctionDecl = {
    name:String,
    parameters:Array<Parameter>,
    returnType:Null<String>,
    body:Array<Stmt>,
    isStatic:Bool,
    visibility:String
};

typedef ClassDecl = {
    name:String,
    extendsName:Null<String>,
    members:Array<Stmt>
};
