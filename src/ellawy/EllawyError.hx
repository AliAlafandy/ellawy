package ellawy;

class EllawyError extends haxe.Exception {
    public final line:Int;
    public final column:Int;
    public final file:String;

    public function new(message:String, line:Int = 0, column:Int = 0, file:String = null) {
        var location = "";
        if (file != null && file.length > 0) location += file + ":";
        if (line > 0) {
            location += Std.string(line);
            if (column > 0) location += ":" + Std.string(column);
            location += ": ";
        }
        super(location + message);
        this.line = line;
        this.column = column;
        this.file = file;
    }
}
