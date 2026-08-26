package tests;

import ellawy.Compiler;

class CompilerTest {
    static function main():Void {
        var source = '
            local a: Int = 10
            local b: Int = 20
            if a < b
                return a + b
            else
                return 0
            end
        ';
        var hx = Compiler.compileSource(source);
        if (hx.indexOf("if ((a < b))") < 0) throw "CompilerTest failed";
        if (hx.indexOf("return (a + b);") < 0) throw "CompilerTest failed";
        trace("CompilerTest passed");
    }
}
