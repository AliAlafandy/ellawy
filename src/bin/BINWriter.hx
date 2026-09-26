package bin;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;

import bin.BINValue;

class BINWriter {
    public static inline var DEFAULT_MAX_DEPTH:Int = 256;
    public static inline var DEFAULT_MAX_STRING_BYTES:Int = 16 * 1024 * 1024;
    public static inline var DEFAULT_MAX_CONTAINER_ITEMS:Int = 1000000;
    public static inline var DEFAULT_MAX_TOTAL_BYTES:Int = 256 * 1024 * 1024;

    public var maxDepth:Int;
    public var maxStringBytes:Int;
    public var maxContainerItems:Int;
    public var maxTotalBytes:Int;

    public function new(
        maxDepth:Int = DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = DEFAULT_MAX_TOTAL_BYTES
    ) {
        this.maxDepth = maxDepth;
        this.maxStringBytes = maxStringBytes;
        this.maxContainerItems = maxContainerItems;
        this.maxTotalBytes = maxTotalBytes;

        validateLimits();
    }

    public static function write(
        value:BINValue,
        maxDepth:Int = DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = DEFAULT_MAX_TOTAL_BYTES
    ):Bytes {
        return new BINWriter(
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        ).writeValue(value);
    }

    public function writeValue(value:BINValue):Bytes {
        if (value == null)
            throw new BINException(
                "Cannot write a null BINValue."
            );

        var payload = new BytesBuffer();

        writeNode(payload, value, 0);

        var body = payload.getBytes();

        if (body.length > maxTotalBytes - BIN.HEADER_SIZE)
            throw new BINException(
                "BIN payload exceeds configured maximum size."
            );

        var output = new BytesBuffer();

        var magic = Bytes.ofString(BIN.MAGIC);

        output.addBytes(magic, 0, magic.length);

        addUInt16(output, BIN.VERSION);
        addUInt16(output, BIN.FLAG_NONE);
        addUInt32(output, body.length);

        output.addBytes(body, 0, body.length);

        var result = output.getBytes();

        if (result.length > maxTotalBytes)
            throw new BINException(
                "BIN output exceeds configured maximum size."
            );

        return result;
    }

    private function writeNode(
        out:BytesBuffer,
        value:BINValue,
        depth:Int
    ):Void {
        if (depth > maxDepth)
            throw new BINException(
                "Maximum BIN nesting depth exceeded."
            );

        switch (value.type) {
            case BINValueType.NULL:
                out.addByte(BIN.TAG_NULL);

            case BINValueType.BOOL:
                out.addByte(
                    value.asBool()
                        ? BIN.TAG_TRUE
                        : BIN.TAG_FALSE
                );

            case BINValueType.INT:
                out.addByte(BIN.TAG_INT);
                addInt32(out, value.asInt());

            case BINValueType.FLOAT:
                var number = value.asFloat();

                if (Math.isNaN(number) || !Math.isFinite(number))
                    throw new BINException(
                        "BIN does not allow NaN or Infinity."
                    );

                out.addByte(BIN.TAG_FLOAT64);
                addFloat64(out, number);

            case BINValueType.STRING:
                var stringBytes = Bytes.ofString(
                    value.asString()
                );

                if (stringBytes.length > maxStringBytes)
                    throw new BINException(
                        "BIN string exceeds configured maximum size."
                    );

                out.addByte(BIN.TAG_STRING);

                addUInt32(
                    out,
                    stringBytes.length
                );

                out.addBytes(
                    stringBytes,
                    0,
                    stringBytes.length
                );

            case BINValueType.ARRAY:
                var array = value.asArray();

                if (array.length > maxContainerItems)
                    throw new BINException(
                        "BIN array exceeds configured item limit."
                    );

                out.addByte(BIN.TAG_ARRAY);
                addUInt32(out, array.length);

                for (item in array)
                    writeNode(out, item, depth + 1);

            case BINValueType.OBJECT:
                var object = value.asObject();

                if (object.length > maxContainerItems)
                    throw new BINException(
                        "BIN object exceeds configured item limit."
                    );

                out.addByte(BIN.TAG_OBJECT);
                addUInt32(out, object.length);

                for (key in object.keys()) {
                    var keyBytes = Bytes.ofString(key);

                    if (keyBytes.length > maxStringBytes)
                        throw new BINException(
                            "BIN object key exceeds configured maximum size."
                        );

                    addUInt32(out, keyBytes.length);

                    out.addBytes(
                        keyBytes,
                        0,
                        keyBytes.length
                    );

                    writeNode(
                        out,
                        object.get(key),
                        depth + 1
                    );
                }

            case BINValueType.BYTES:
                var bytes = value.asBytes();

                if (bytes.length > maxTotalBytes)
                    throw new BINException(
                        "BIN byte value exceeds configured maximum size."
                    );

                out.addByte(BIN.TAG_BYTES);
                addUInt32(out, bytes.length);

                out.addBytes(
                    bytes,
                    0,
                    bytes.length
                );

            default:
                throw new BINException(
                    "Unsupported BIN value type."
                );
        }
    }

    private static inline function addUInt16(
        out:BytesBuffer,
        value:Int
    ):Void {
        if (value < 0 || value > 0xFFFF)
            throw new BINException(
                "UInt16 value out of range: " + value
            );

        out.addByte((value >>> 8) & 0xFF);
        out.addByte(value & 0xFF);
    }

    private static inline function addUInt32(
        out:BytesBuffer,
        value:Int
    ):Void {
        if (value < 0)
            throw new BINException(
                "UInt32 value cannot be negative."
            );

        out.addByte((value >>> 24) & 0xFF);
        out.addByte((value >>> 16) & 0xFF);
        out.addByte((value >>> 8) & 0xFF);
        out.addByte(value & 0xFF);
    }

    private static inline function addInt32(
        out:BytesBuffer,
        value:Int
    ):Void {
        out.addByte((value >>> 24) & 0xFF);
        out.addByte((value >>> 16) & 0xFF);
        out.addByte((value >>> 8) & 0xFF);
        out.addByte(value & 0xFF);
    }

    private static function addFloat64(
        out:BytesBuffer,
        value:Float
    ):Void {
        var bytes = Bytes.alloc(8);

        bytes.setDouble(0, value);

        out.addBytes(bytes, 0, 8);
    }

    private function validateLimits():Void {
        if (maxDepth < 0)
            throw new BINException("maxDepth must be >= 0.");

        if (maxStringBytes < 0)
            throw new BINException(
                "maxStringBytes must be >= 0."
            );

        if (maxContainerItems < 0)
            throw new BINException(
                "maxContainerItems must be >= 0."
            );

        if (maxTotalBytes < BIN.HEADER_SIZE)
            throw new BINException(
                "maxTotalBytes is too small."
            );
    }
}
