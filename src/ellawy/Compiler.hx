package ellawy;

class Compiler {
    public static inline final VERSION:String = "1.0.0";

    public static function tokenize(source:String, file:String = null):Array<Token> {
        return new Lexer(source, file).tokenize();
    }

    public static function parse(source:String, file:String = null):Array<Stmt> {
        var tokens = tokenize(source, file);
        return new Parser(tokens, file).parse();
    }

    public static function compileSource(source:String, file:String = null):String {
        return HaxeGenerator.generate(parse(source, file));
    }

    public static function compileFile(inputPath:String, outputPath:String = null):String {
        var source = sys.io.File.getContent(inputPath);
        var generated = compileSource(source, inputPath);
        if (outputPath != null) sys.io.File.saveContent(outputPath, generated);
        return generated;
    }
}
