package ellawy;

import ellawy.AST;
import ellawy.Token;
import ellawy.Parser;
import ellawy.Compiler;
import ellawy.Ellawy;

class Lexer {
    static final keywords:Map<String, TokenType> = [
        "local" => Local, "function" => Function, "return" => Return, "end" => End,
        "class" => Class, "import" => Import, "true" => True, "false" => False,
        "null" => Null, "if" => If, "else" => Else, "while" => While,
        "for" => For, "in" => In, "new" => New, "public" => Public,
        "private" => Private, "static" => Static, "extends" => Extends,
        "and" => And, "or" => Or, "not" => Not
    ];

    final source:String;
    final file:String;
    var current:Int = 0;
    var start:Int = 0;
    var line:Int = 1;
    var column:Int = 1;
    var tokenColumn:Int = 1;

    public function new(source:String, file:String = null) {
        this.source = source == null ? "" : source;
        this.file = file;
    }

    public function tokenize():Array<Token> {
        var result:Array<Token> = [];
        while (!isAtEnd()) {
            start = current;
            tokenColumn = column;
            scan(result);
        }
        result.push(new Token(EOF, "", null, line, column));
        return result;
    }

    function scan(out:Array<Token>):Void {
        var c = advance();
        switch (c) {
            case " ", "\r", "\t": {}
            case "\n": line++; column = 1;
            case "#":
                while (!isAtEnd() && peek() != "\n") advance();
            case "/":
                if (match("/")) {
                    while (!isAtEnd() && peek() != "\n") advance();
                } else add(out, Slash);
            case '"': string(out);
            case "'": stringSingle(out);
            case "+": add(out, Plus);
            case "-": if (match(">")) add(out, Arrow) else add(out, Minus);
            case "*": add(out, Star);
            case "%": add(out, Percent);
            case "=": add(out, match("=") ? EqualEqual : Equal);
            case "!": add(out, match("=") ? NotEqual : Not);
            case "<": add(out, match("=") ? LessEqual : Less);
            case ">": add(out, match("=") ? GreaterEqual : Greater);
            case ".": add(out, Dot);
            case ",": add(out, Comma);
            case ":": add(out, Colon);
            case ";": add(out, Semicolon);
            case "(": add(out, LeftParen);
            case ")": add(out, RightParen);
            case "{": add(out, LeftBrace);
            case "}": add(out, RightBrace);
            case "[": add(out, LeftBracket);
            case "]": add(out, RightBracket);
            default:
                if (isDigit(c)) number(out);
                else if (isAlpha(c)) identifier(out);
                else error('Unexpected character "$c".');
        }
    }

    function string(out:Array<Token>):Void {
        var value = new StringBuf();
        while (!isAtEnd() && peek() != '"') {
            if (peek() == "\n") {
                line++;
                column = 1;
                value.add(advance());
                continue;
            }
            if (peek() == "\\") {
                advance();
                if (isAtEnd()) break;
                var e = advance();
                switch (e) {
                    case "n": value.add("\n");
                    case "r": value.add("\r");
                    case "t": value.add("\t");
                    case "\\": value.add("\\");
                    case '"': value.add('"');
                    default: value.add(e);
                }
            } else value.add(advance());
        }
        if (isAtEnd()) error("Unterminated string.");
        advance();
        out.push(new Token(StringLiteral, source.substring(start, current), value.toString(), line, tokenColumn));
    }

    function stringSingle(out:Array<Token>):Void {
        var value = new StringBuf();
        while (!isAtEnd() && peek() != "'") {
            if (peek() == "\\") {
                advance();
                if (isAtEnd()) break;
                var e = advance();
                switch (e) {
                    case "n": value.add("\n");
                    case "r": value.add("\r");
                    case "t": value.add("\t");
                    case "\\": value.add("\\");
                    case "'": value.add("'");
                    default: value.add(e);
                }
            } else value.add(advance());
        }
        if (isAtEnd()) error("Unterminated string.");
        advance();
        out.push(new Token(StringLiteral, source.substring(start, current), value.toString(), line, tokenColumn));
    }

    function number(out:Array<Token>):Void {
        while (isDigit(peek())) advance();
        if (peek() == "." && isDigit(peekNext())) {
            advance();
            while (isDigit(peek())) advance();
        }
        var text = source.substring(start, current);
        out.push(new Token(NumberLiteral, text, Std.parseFloat(text), line, tokenColumn));
    }

    function identifier(out:Array<Token>):Void {
        while (isAlphaNumeric(peek())) advance();
        var text = source.substring(start, current);
        var type = keywords.exists(text) ? keywords.get(text) : TokenType.Identifier;
        out.push(new Token(type, text, null, line, tokenColumn));
    }

    inline function isAtEnd():Bool return current >= source.length;
	inline function peek():String return isAtEnd() ? "" : source.charAt(current);
	inline function peekNext():String return current + 1 >= source.length ? "" : source.charAt(current + 1);

	function advance():String {
		var c = source.charAt(current++);
		if (c != "\n") column++; else column = 1;
		return c;
	}

	function match(expected:String):Bool {
		if (isAtEnd() || source.charAt(current) != expected) return false;
		advance();
		return true;
	}

	function add(out:Array<Token>, type:TokenType):Void {
		out.push(new Token(type, source.substring(start, current), null, line, tokenColumn));
	}

	function error(message:String):Void {
		throw new EllawyError(message, line, tokenColumn, file);
	}

	static inline function isDigit(c:String):Bool return c >= "0" && c <= "9";
	static inline function isAlpha(c:String):Bool return (c >= "a" && c <= "z") || (c >= "A" && c <= "Z") || c == "_";
	static inline function isAlphaNumeric(c:String):Bool return isAlpha(c) || isDigit(c);
}
