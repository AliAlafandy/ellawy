package bin;

import haxe.ds.StringMap;

import bin.BINValue;

class BINObject {
    private var fields:StringMap<BINValue>;
    private final order:Array<String>;

    public var length(get, never):Int;

    public function new() {
        fields = new StringMap<BINValue>();
        order = [];
    }

    private inline function get_length():Int {
        return order.length;
    }

    public function set(key:String, value:BINValue):BINObject {
        if (key == null || key.length == 0)
            throw new BINException(
                "BINObject keys cannot be null or empty."
            );

        if (value == null)
            throw new BINException(
                "BINObject values cannot be null. " +
                "Use BINValue.nullValue()."
            );

        if (!fields.exists(key))
            order.push(key);

        fields.set(key, value);

        return this;
    }

    public function setDynamic(
        key:String,
        value:Dynamic
    ):BINObject {
        return set(key, BINValue.fromDynamic(value));
    }

    public inline function exists(key:String):Bool {
        return fields.exists(key);
    }

    public inline function get(key:String):BINValue {
        return fields.get(key);
    }

    public function remove(key:String):Bool {
        if (!fields.exists(key))
            return false;

        fields.remove(key);

        var index = order.indexOf(key);

        if (index >= 0)
            order.splice(index, 1);

        return true;
    }

    public function clear():Void {
        fields = new StringMap<BINValue>();
        order.resize(0);
    }

    public function keys():Array<String> {
        return order.copy();
    }

    public function iterator():Iterator<String> {
        return order.iterator();
    }

    public function clone():BINObject {
        var result = new BINObject();

        for (key in order)
            result.set(
                key,
                BINParser.cloneValue(fields.get(key))
            );

        return result;
    }

    public function toString():String {
        var out = new StringBuf();

        out.add("{");

        for (i in 0...order.length) {
            if (i > 0)
                out.add(", ");

            var key = order[i];

            out.add(key);
            out.add(": ");
            out.add(fields.get(key).toString());
        }

        out.add("}");

        return out.toString();
    }
}
