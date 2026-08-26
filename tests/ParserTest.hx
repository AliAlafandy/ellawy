package tests;

import ellawy.Compiler;

class ParserTest {
    static function main():Void {
        var output = Compiler.compileSource(
            'local name: String = "Ali"\nreturn name'
        );
        if (output.indexOf("var name:String") < 0) throw "ParserTest failed";
        if (output.indexOf("return name;") < 0) throw "ParserTest failed";
        trace("ParserTest passed");
    }
}
