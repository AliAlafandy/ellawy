package tests;

import ellawy.Lexer;
import ellawy.TokenType;

class LexerTest {
    static function main():Void {
        var tokens = new Lexer('local x: Int = 10').tokenize();
        assert(tokens[0].type == Local);
        assert(tokens[1].type == Identifier);
        assert(tokens[2].type == Colon);
        assert(tokens[3].type == Identifier);
        assert(tokens[4].type == Equal);
        assert(tokens[5].type == NumberLiteral);
        trace("LexerTest passed");
    }

    static function assert(value:Bool):Void {
        if (!value) throw "Assertion failed";
    }
}
