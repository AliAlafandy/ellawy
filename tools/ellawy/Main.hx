package tools.ellawy;

import ellawy.Compiler;

class Main {
    public static function main():Void {
        var args = Sys.args();

        if (args.length == 0 || args[0] == "help" || args[0] == "--help") {
            usage();
            return;
        }

        if (args[0] == "version" || args[0] == "--version") {
            Sys.println("Ellawy " + ellawy.Version.STRING);
            return;
        }

        var input = args[0];
        var output = args.length >= 2 ? args[1] : defaultOutput(input);

        try {
            Compiler.compileFile(input, output);
            Sys.println("Ellawy: generated " + output);
        } catch (e:ellawy.EllawyError) {
            Sys.stderr().writeString(e.message + "\n");
            Sys.exit(1);
        } catch (e:haxe.Exception) {
            Sys.stderr().writeString("Ellawy: " + e.message + "\n");
            Sys.exit(1);
        }
    }

    static function defaultOutput(input:String):String {
        return StringTools.endsWith(input, ".ellawy")
            ? input.substr(0, input.length - ".ellawy".length) + ".hx"
            : input + ".hx";
    }

    static function usage():Void {
        Sys.println("Ellawy " + ellawy.Version.STRING);
        Sys.println("Usage:");
        Sys.println("  haxelib run ellawy <input.ellawy> [output.hx]");
        Sys.println("  haxelib run ellawy version");
    }
}
