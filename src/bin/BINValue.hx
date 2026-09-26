package bin;

import haxe.io.Bytes;

enum abstract BINValueType(Int) from Int to Int {
    var NULL = 0;
    var BOOL = 1;
    var INT = 2;
    var FLOAT = 3;
    var STRING = 4;
    var ARRAY = 5;
    var OBJECT = 6;
    var BYTES = 7;
}

class BINValue {
    public final type:BINValueType;

    private final value:Dynamic;

    public function new(type:BINValueType, value:Dynamic = null) {
        this.type = type;
        this.value = value;
    }

    public static function nullValue():BINValue {
        return new BINValue(BINValueType.NULL);
    }

    public static function bool(value:Bool):BINValue {
        return new BINValue(BINValueType.BOOL, value);
    }

    public static function int(value:Int):BINValue {
        return new BINValue(BINValueType.INT, value);
    }

    public static function float(value:Float):BINValue {
        return new BINValue(BINValueType.FLOAT, value);
    }

    public static function string(value:String):BINValue {
        return new BINValue(
            BINValueType.STRING,
            value == null ? "" : value
        );
    }

    public static function array(value:BINArray):BINValue {
        return new BINValue(
            BINValueType.ARRAY,
            value == null ? new BINArray() : value
        );
    }

    public static function object(value:BINObject):BINValue {
        return new BINValue(
            BINValueType.OBJECT,
            value == null ? new BINObject() : value
        );
    }

    public static function bytes(value:Bytes):BINValue {
        return new BINValue(
            BINValueType.BYTES,
            value == null ? Bytes.alloc(0) : value
        );
    }

    public static function fromDynamic(value:Dynamic):BINValue {
        if (value == null)
            return nullValue();

        if (Std.isOfType(value, BINValue))
            return cast value;

        if (Std.isOfType(value, Bool))
            return bool(cast value);

        if (Std.isOfType(value, Int))
            return int(cast value);

        if (Std.isOfType(value, Float))
            return float(cast value);

        if (Std.isOfType(value, String))
            return string(cast value);

        if (Std.isOfType(value, Bytes))
            return bytes(cast value);

        if (Std.isOfType(value, BINArray))
            return array(cast value);

        if (Std.isOfType(value, BINObject))
            return object(cast value);

        if (Std.isOfType(value, Array)) {
            var result = new BINArray();

            for (item in (cast value:Array<Dynamic>))
                result.push(fromDynamic(item));

            return array(result);
        }

        throw new BINException(
            "Unsupported dynamic value type: " + Type.typeof(value)
        );
    }

    public inline function isNull():Bool {
        return type == BINValueType.NULL;
    }

    public inline function isBool():Bool {
        return type == BINValueType.BOOL;
    }

    public inline function isInt():Bool {
        return type == BINValueType.INT;
    }

    public inline function isFloat():Bool {
        return type == BINValueType.FLOAT;
    }

    public inline function isNumber():Bool {
        return isInt() || isFloat();
    }

    public inline function isString():Bool {
        return type == BINValueType.STRING;
    }

    public inline function isArray():Bool {
        return type == BINValueType.ARRAY;
    }

    public inline function isObject():Bool {
        return type == BINValueType.OBJECT;
    }

    public inline function isBytes():Bool {
        return type == BINValueType.BYTES;
    }

    public function asBool(defaultValue:Bool = false):Bool {
        return isBool() ? cast value : defaultValue;
    }

    public function asInt(defaultValue:Int = 0):Int {
        if (isInt())
            return cast value;

        if (isFloat())
            return Std.int(cast value);

        return defaultValue;
    }

    public function asFloat(defaultValue:Float = 0.0):Float {
        if (isFloat())
            return cast value;

        if (isInt())
            return cast value;

        return defaultValue;
    }

    public function asString(defaultValue:String = null):String {
        return isString() ? cast value : defaultValue;
    }

    public function asArray():BINArray {
        return isArray() ? cast value : null;
    }

    public function asObject():BINObject {
        return isObject() ? cast value : null;
    }

    public function asBytes():Bytes {
        return isBytes() ? cast value : null;
    }

    public function raw():Dynamic {
        return value;
    }

    public function toDynamic():Dynamic {
        return switch (type) {
            case BINValueType.NULL:
                null;

            case BINValueType.BOOL:
                asBool();

            case BINValueType.INT:
                asInt();

            case BINValueType.FLOAT:
                asFloat();

            case BINValueType.STRING:
                asString();

            case BINValueType.BYTES:
                asBytes();

            case BINValueType.ARRAY:
                var result:Array<Dynamic> = [];

                for (item in asArray())
                    result.push(item.toDynamic());

                result;

            case BINValueType.OBJECT:
                var result:Dynamic = {};
                var object = asObject();

                for (key in object.keys())
                    Reflect.setField(
                        result,
                        key,
                        object.get(key).toDynamic()
                    );

                result;

            default:
                null;
        };
    }

    public function toString():String {
        return switch (type) {
            case BINValueType.NULL:
                "null";

            case BINValueType.BOOL:
                Std.string(asBool());

            case BINValueType.INT:
                Std.string(asInt());

            case BINValueType.FLOAT:
                Std.string(asFloat());

            case BINValueType.STRING:
                '"' + asString() + '"';

            case BINValueType.BYTES:
                "<bytes:" + asBytes().length + ">";

            case BINValueType.ARRAY:
                asArray().toString();

            case BINValueType.OBJECT:
                asObject().toString();

            default:
                "<invalid>";
        };
    }
}
