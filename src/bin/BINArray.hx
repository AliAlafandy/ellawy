package bin;

import bin.BINValue;

class BINArray {
    private final values:Array<BINValue>;

    public var length(get, never):Int;

    public function new(?values:Array<BINValue>) {
        this.values = values == null ? [] : values.copy();
    }

    private inline function get_length():Int {
        return values.length;
    }

    public function push(value:BINValue):Int {
        if (value == null)
            throw new BINException(
                "BINArray cannot contain a null BINValue. " +
                "Use BINValue.nullValue()."
            );

        return values.push(value);
    }

    public inline function add(value:BINValue):Int {
        return push(value);
    }

    public function get(index:Int):BINValue {
        checkIndex(index);
        return values[index];
    }

    public function set(index:Int, value:BINValue):BINValue {
        checkIndex(index);

        if (value == null)
            throw new BINException(
                "BINArray cannot contain a null BINValue."
            );

        values[index] = value;
        return value;
    }

    public function remove(index:Int):BINValue {
        checkIndex(index);
        return values.splice(index, 1)[0];
    }

    public function clear():Void {
        values.resize(0);
    }

    public function iterator():Iterator<BINValue> {
        return values.iterator();
    }

    public function toArray():Array<BINValue> {
        return values.copy();
    }

    public function clone():BINArray {
        var result = new BINArray();

        for (value in values)
            result.push(BINParser.cloneValue(value));

        return result;
    }

    public function toString():String {
        var out = new StringBuf();

        out.add("[");

        for (i in 0...values.length) {
            if (i > 0)
                out.add(", ");

            out.add(values[i].toString());
        }

        out.add("]");

        return out.toString();
    }

    private inline function checkIndex(index:Int):Void {
        if (index < 0 || index >= values.length)
            throw new BINException(
                "Array index out of bounds: " + index
            );
    }
}
