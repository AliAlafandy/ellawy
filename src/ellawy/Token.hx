package ellawy;

class Token {
    public final type:TokenType;
    public final lexeme:String;
    public final literal:Dynamic;
    public final line:Int;
    public final column:Int;

    public function new(type:TokenType, lexeme:String, literal:Dynamic = null, line:Int = 1, column:Int = 1) {
        this.type = type;
        this.lexeme = lexeme;
        this.literal = literal;
        this.line = line;
        this.column = column;
    }

    public function toString():String {
        return '${type}("${lexeme}") at ${line}:${column}';
    }
}
