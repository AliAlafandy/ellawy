package ellawy;

import ellawy.AST;
import ellawy.Token;
import ellawy.Lexer;
import ellawy.Compiler;
import ellawy.Ellawy;

class Parser {
    final tokens:Array<Token>;
    final file:String;
    var current:Int = 0;

    public function new(tokens:Array<Token>, file:String = null) {
        this.tokens = tokens;
        this.file = file;
    }

    public function parse():Array<Stmt> {
        var result:Array<Stmt> = [];
        while (!check(EOF)) {
            result.push(statement());
        }
        return result;
    }

    function statement():Stmt {
        if (match(Import)) return importStatement();
        if (match(Local)) return localStatement();
        if (match(Return)) return Return(check(End) || check(Else) || check(EOF) ? null : expression());
        if (match(Function)) return Function(functionDeclaration(false, "public"));
        if (match(Class)) return Class(classDeclaration());
        if (match(If)) return ifStatement();
        if (match(While)) return whileStatement();
        if (match(Semicolon)) return Block([]);
        return Expression(expression());
    }

    function importStatement():Stmt {
        var path = consume(TokenType.Identifier, "Expected import path.").lexeme;
        while (match(Dot)) path += "." + consume(TokenType.Identifier, "Expected identifier after '.'.").lexeme;
        optional(Semicolon);
        return Import(path);
    }

    function localStatement():Stmt {
        var name = consume(TokenType.Identifier, "Expected variable name.");
        var typeName:Null<String> = null;
        if (match(Colon)) typeName = typeNameParser();
        var value:Null<Expr> = null;
        if (match(Equal)) value = expression();
        optional(Semicolon);
        return Local(name.lexeme, typeName, value);
    }

    function functionDeclaration(isStatic:Bool, visibility:String):FunctionDecl {
        var name = consume(TokenType.Identifier, "Expected function name.").lexeme;
        consume(LeftParen, "Expected '('.");
        var parameters:Array<Parameter> = [];
        if (!check(RightParen)) {
            do {
                var pName = consume(TokenType.Identifier, "Expected parameter name.").lexeme;
                var pType:Null<String> = null;
                var defaultValue:Null<Expr> = null;
                if (match(Colon)) pType = typeNameParser();
                if (match(Equal)) defaultValue = expression();
                parameters.push({name:pName, typeName:pType, defaultValue:defaultValue});
            } while (match(Comma));
        }
        consume(RightParen, "Expected ')'.");
        var returnType:Null<String> = null;
        if (match(Colon)) returnType = typeNameParser();
        var body = parseUntil([End]);
        consume(End, "Expected 'end' after function.");
        optional(Semicolon);
        return {
            name:name, parameters:parameters, returnType:returnType, body:body,
            isStatic:isStatic, visibility:visibility
        };
    }

    function classDeclaration():ClassDecl {
        var name = consume(TokenType.Identifier, "Expected class name.").lexeme;
        var extendsName:Null<String> = null;
        if (match(Extends)) extendsName = typeNameParser();
        var members:Array<Stmt> = [];
        while (!check(End) && !check(EOF)) {
            var visibility = "public";
            var isStatic = false;
            if (match(Public)) visibility = "public";
            else if (match(Private)) visibility = "private";
            if (match(Static)) isStatic = true;

            if (match(Function)) {
                members.push(Function(functionDeclaration(isStatic, visibility)));
            } else if (match(Local)) {
                var local = localStatement();
                members.push(local);
            } else {
                throw error("Expected class member.");
            }
        }
        consume(End, "Expected 'end' after class.");
        optional(Semicolon);
        return {name:name, extendsName:extendsName, members:members};
    }

    function ifStatement():Stmt {
        var condition = expression();
        var thenBranch = parseUntil([Else, End]);
        var elseBranch:Null<Array<Stmt>> = null;
        if (match(Else)) elseBranch = parseUntil([End]);
        consume(End, "Expected 'end' after if.");
        optional(Semicolon);
        return If(condition, thenBranch, elseBranch);
    }

    function whileStatement():Stmt {
        var condition = expression();
        var body = parseUntil([End]);
        consume(End, "Expected 'end' after while.");
        optional(Semicolon);
        return While(condition, body);
    }

    function parseUntil(stop:Array<TokenType>):Array<Stmt> {
        var result:Array<Stmt> = [];
        while (!check(EOF) && !contains(stop, peek().type)) result.push(statement());
        return result;
    }

    function expression():Expr return or();

    function or():Expr {
        var e = and();
        while (match(Or)) e = Binary(e, "||", and());
        return e;
    }

    function and():Expr {
        var e = equality();
        while (match(And)) e = Binary(e, "&&", equality());
        return e;
    }

    function equality():Expr {
        var e = comparison();
        while (match(EqualEqual, NotEqual)) e = Binary(e, previous().lexeme, comparison());
        return e;
    }

    function comparison():Expr {
        var e = term();
        while (match(Less, LessEqual, Greater, GreaterEqual)) e = Binary(e, previous().lexeme, term());
        return e;
    }

    function term():Expr {
        var e = factor();
        while (match(Plus, Minus)) e = Binary(e, previous().lexeme, factor());
        return e;
    }

    function factor():Expr {
        var e = unary();
        while (match(Star, Slash, Percent)) e = Binary(e, previous().lexeme, unary());
        return e;
    }

    function unary():Expr {
        if (match(Not, Minus, Plus)) return Unary(previous().lexeme, unary());
        return postfix(primary());
    }

    function postfix(e:Expr):Expr {
        while (true) {
            if (match(LeftParen)) {
                var args:Array<Expr> = [];
                if (!check(RightParen)) {
                    do args.push(expression()) while (match(Comma));
                }
                consume(RightParen, "Expected ')'.");
                e = Call(e, args);
            } else if (match(Dot)) {
                e = Member(e, consume(TokenType.Identifier, "Expected member name.").lexeme);
            } else break;
        }
        return e;
    }

    function primary():Expr {
        if (match(NumberLiteral)) return Literal(previous().literal);
        if (match(StringLiteral)) return Literal(previous().literal);
        if (match(True)) return Literal(true);
        if (match(False)) return Literal(false);
        if (match(Null)) return Literal(null);
        if (match(New)) {
            var className = typeNameParser();
            consume(LeftParen, "Expected '(' after class name.");
            var args:Array<Expr> = [];
            if (!check(RightParen)) do args.push(expression()) while (match(Comma));
            consume(RightParen, "Expected ')'.");
            return NewObject(className, args);
        }
        if (match(TokenType.Identifier)) return Identifier(previous().lexeme);
        if (match(LeftParen)) {
            var e = expression();
            consume(RightParen, "Expected ')'.");
            return e;
        }
        if (match(LeftBracket)) {
            var items:Array<Expr> = [];
            if (!check(RightBracket)) do items.push(expression()) while (match(Comma));
            consume(RightBracket, "Expected ']'.");
            return ArrayLiteral(items);
        }
        if (match(LeftBrace)) return objectLiteral();
        throw error("Expected expression.");
    }

    function objectLiteral():Expr {
        var fields:Array<ObjectField> = [];
        if (!check(RightBrace)) {
            do {
                var name = consume(TokenType.Identifier, "Expected object field name.").lexeme;
                consume(Colon, "Expected ':' after object field name.");
                fields.push({name:name, value:expression()});
            } while (match(Comma));
        }
        consume(RightBrace, "Expected '}'.");
        return ObjectLiteral(fields);
    }

    function typeNameParser():String {
        var result = consume(TokenType.Identifier, "Expected type name.").lexeme;
        while (match(Dot)) result += "." + consume(TokenType.Identifier, "Expected type name.").lexeme;
        return result;
    }

    function consume(type:TokenType, message:String):Token {
        if (check(type)) return advance();
        throw error(message);
    }

    function error(message:String):EllawyError {
        var t = peek();
        return new EllawyError(message, t.line, t.column, file);
    }

    function match(...types:TokenType):Bool {
        for (type in types) if (check(type)) { advance(); return true; }
        return false;
    }

    inline function check(type:TokenType):Bool return peek().type == type;
    inline function peek():Token return tokens[current];
    inline function previous():Token return tokens[current - 1];
    inline function advance():Token return tokens[current++];
    inline function contains(a:Array<TokenType>, t:TokenType):Bool return Lambda.has(a, t);
    inline function optional(type:TokenType):Void if (match(type)) {}
}
