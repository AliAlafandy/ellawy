package ellawy;

import ellawy.AST;
import ellawy.Token;
import ellawy.Lexer;
import ellawy.Parser;
import ellawy.HaxeGenerator;
import ellawy.Compiler;

class Ellawy {
    public static inline final VERSION:String = Version.STRING;

    public static function tokenize(source:String, file:String = null):Array<Token> {
        return new Lexer(source, file).tokenize();
    }

    public static function parse(source:String, file:String = null):Array<Stmt> {
        var tokens = tokenize(source, file);
        return new Parser(tokens, file).parse();
    }

    public static function compile(source:String, file:String = null):String {
        return HaxeGenerator.generate(parse(source, file));
    }

    public static function compileSource(source:String, file:String = null):String {
        return compile(source, file);
    }

    public static function compileFile(
        inputPath:String,
        outputPath:String = null
    ):String {
        return Compiler.compileFile(inputPath, outputPath);
    }

    public static function generate(ast:Array<Stmt>):String {
        return HaxeGenerator.generate(ast);
    }

    public static function version():String {
        return Version.STRING;
    }

    public static function majorVersion():Int {
        return Version.MAJOR;
    }

    public static function minorVersion():Int {
        return Version.MINOR;
    }

    public static function patchVersion():Int {
        return Version.PATCH;
    }

    public static function isValid(source:String, file:String = null):Bool {
        try {
            parse(source, file);
            return true;
        } catch (e:EllawyError) {
            return false;
        }
    }

    public static function validate(
        source:String,
        file:String = null
    ):Null<EllawyError> {
        try {
            parse(source, file);
            return null;
        } catch (e:EllawyError) {
            return e;
        }
    }

    public static function tryCompile(
        source:String,
        file:String = null
    ):Null<String> {
        try {
            return compile(source, file);
        } catch (e:EllawyError) {
            return null;
        }
    }

    public static function compileSafe(
        source:String,
        onSuccess:String->Void,
        onError:EllawyError->Void,
        file:String = null
    ):Void {
        try {
            var result = compile(source, file);
            onSuccess(result);
        } catch (e:EllawyError) {
            onError(e);
        }
    }

    public static function createLexer(
        source:String,
        file:String = null
    ):Lexer {
        return new Lexer(source, file);
    }

    public static function createParser(
        source:String,
        file:String = null
    ):Parser {
        return new Parser(tokenize(source, file), file);
    }

    public static function createParserFromTokens(
        tokens:Array<Token>,
        file:String = null
    ):Parser {
        return new Parser(tokens, file);
    }

    public static function compilerName():String {
        return "Ellawy Compiler";
    }

    public static function info():EllawyInfo {
        return {
            name: "Ellawy",
            version: Version.STRING,
            languageId: "ellawy",
            extension: ".ellawy",
            target: "Haxe"
        };
    }
}

typedef EllawyInfo = {
    name:String,
    version:String,
    languageId:String,
    extension:String,
    target:String
};
