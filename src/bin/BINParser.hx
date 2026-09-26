package bin;

import haxe.io.Bytes;

import bin.BINValue;

class BINParser {
    public static inline var DEFAULT_MAX_DEPTH:Int = 256;
    public static inline var DEFAULT_MAX_STRING_BYTES:Int = 16 * 1024 * 1024;
    public static inline var DEFAULT_MAX_CONTAINER_ITEMS:Int = 1000000;
    public static inline var DEFAULT_MAX_TOTAL_BYTES:Int = 256 * 1024 * 1024;

    public var maxDepth:Int;
    public var maxStringBytes:Int;
    public var maxContainerItems:Int;
    public var maxTotalBytes:Int;

    private var data:Bytes;
    private var offset:Int;

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

    public static function parse(
        data:Bytes,
        maxDepth:Int = DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = DEFAULT_MAX_TOTAL_BYTES
    ):BINValue {
        return new BINParser(
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        ).parseBytes(data);
    }

    public function parseBytes(bytes:Bytes):BINValue {
        if (bytes == null)
            throw new BINException(
                "Cannot parse null bytes."
            );

        if (bytes.length > maxTotalBytes)
            throw new BINException(
                "BIN file exceeds configured maximum size."
            );

        if (bytes.length < BIN.HEADER_SIZE)
            throw new BINException(
                "BIN file is truncated: missing header."
            );

        data = bytes;
        offset = 0;

        readMagic();

        var version = readUInt16();

        if (version != BIN.VERSION)
            throw new BINException(
                "Unsupported BIN version: " +
                version +
                ". Expected " +
                BIN.VERSION +
                "."
            );

        var flags = readUInt16();

        if ((flags & ~BIN.FLAG_NONE) != 0)
            throw new BINException(
                "Unsupported BIN flags: 0x" +
                StringTools.hex(flags, 4)
            );

        var payloadLength = readUInt32();

        var actualLength =
            data.length - BIN.HEADER_SIZE;

        if (payloadLength != actualLength)
            throw new BINException(
                "Invalid BIN payload length. Header says " +
                payloadLength +
                " bytes, file contains " +
                actualLength +
                "."
            );

        var value = readNode(0);

        if (offset != data.length)
            throw new BINException(
                "Trailing bytes after root BIN value at offset " +
                offset +
                "."
            );

        return value;
    }

    private function readMagic():Void {
        var magic = Bytes.ofString(BIN.MAGIC);

        ensure(magic.length);

        for (i in 0...magic.length) {
            if (data.get(offset + i) != magic.get(i))
                throw new BINException(
                    "Invalid BIN magic header."
                );
        }

        offset += magic.length;
    }

    private function readNode(depth:Int):BINValue {
        if (depth > maxDepth)
            throw new BINException(
                "Maximum BIN nesting depth exceeded."
            );

        var tag = readByte();

        return switch (tag) {
            case BIN.TAG_NULL:
                BINValue.nullValue();

            case BIN.TAG_FALSE:
                BINValue.bool(false);

            case BIN.TAG_TRUE:
                BINValue.bool(true);

            case BIN.TAG_INT:
                BINValue.int(readInt32());

            case BIN.TAG_FLOAT64:
                var number = readFloat64();

                if (Math.isNaN(number) || !Math.isFinite(number))
                    throw new BINException(
                        "BIN contains NaN or Infinity."
                    );

                BINValue.float(number);

            case BIN.TAG_STRING:
                var length = readLength("string");

                if (length > maxStringBytes)
                    throw new BINException(
                        "BIN string exceeds configured maximum size."
                    );

                BINValue.string(
                    readString(length)
                );

            case BIN.TAG_ARRAY:
                var count = readCount("array");
                var array = new BINArray();

                for (i in 0...count)
                    array.push(readNode(depth + 1));

                BINValue.array(array);

            case BIN.TAG_OBJECT:
                var count = readCount("object");
                var object = new BINObject();

                for (i in 0...count) {
                    var keyLength =
                        readLength("object key");

                    if (keyLength > maxStringBytes)
                        throw new BINException(
                            "BIN object key exceeds configured maximum size."
                        );

                    var key = readString(keyLength);

                    if (key.length == 0)
                        throw new BINException(
                            "BIN object key cannot be empty."
                        );

                    if (object.exists(key))
                        throw new BINException(
                            "Duplicate BIN object key: " + key
                        );

                    object.set(
                        key,
                        readNode(depth + 1)
                    );
                }

                BINValue.object(object);

            case BIN.TAG_BYTES:
                var byteLength = readLength("bytes");

                ensure(byteLength);

                var result =
                    data.sub(offset, byteLength);

                offset += byteLength;

                BINValue.bytes(result);

            default:
                throw new BINException(
                    "Unknown BIN type tag 0x" +
                    StringTools.hex(tag, 2) +
                    " at offset " +
                    (offset - 1) +
                    "."
                );
        };
    }

    private inline function readByte():Int {
        ensure(1);
        return data.get(offset++);
    }

    private inline function readUInt16():Int {
        ensure(2);

        var value =
            (data.get(offset) << 8) |
            data.get(offset + 1);

        offset += 2;

        return value;
    }

    private inline function readUInt32():Int {
        ensure(4);

        var value =
            (data.get(offset) * 0x1000000) +
            (data.get(offset + 1) * 0x10000) +
            (data.get(offset + 2) * 0x100) +
            data.get(offset + 3);

        offset += 4;

        return value;
    }

    private inline function readInt32():Int {
        ensure(4);

        var value =
            (data.get(offset) * 0x1000000) +
            (data.get(offset + 1) * 0x10000) +
            (data.get(offset + 2) * 0x100) +
            data.get(offset + 3);

        offset += 4;

        if (value >= 0x80000000)
            value -= 4294967296;

        return value;
    }

    private function readFloat64():Float {
        ensure(8);

        var value = data.getDouble(offset);

        offset += 8;

        return value;
    }

    private function readString(length:Int):String {
        ensure(length);

        var value =
            data.getString(offset, length);

        offset += length;

        return value;
    }

    private function readLength(kind:String):Int {
        var length = readUInt32();

        if (length > maxTotalBytes)
            throw new BINException(
                "BIN " +
                kind +
                " length exceeds configured maximum."
            );

        return length;
    }

    private function readCount(kind:String):Int {
        var count = readUInt32();

        if (count > maxContainerItems)
            throw new BINException(
                "BIN " +
                kind +
                " item count exceeds configured maximum."
            );

        return count;
    }

    private inline function ensure(bytes:Int):Void {
        if (
            bytes < 0 ||
            offset < 0 ||
            offset > data.length - bytes
        ) {
            throw new BINException(
                "Unexpected end of BIN data at offset " +
                offset +
                "."
            );
        }
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

    public static function cloneValue(
        value:BINValue
    ):BINValue {
        if (value == null)
            throw new BINException(
                "Cannot clone null BINValue."
            );

        return switch (value.type) {
            case BINValueType.NULL:
                BINValue.nullValue();

            case BINValueType.BOOL:
                BINValue.bool(value.asBool());

            case BINValueType.INT:
                BINValue.int(value.asInt());

            case BINValueType.FLOAT:
                BINValue.float(value.asFloat());

            case BINValueType.STRING:
                BINValue.string(value.asString());

            case BINValueType.BYTES:
                var source = value.asBytes();
                var copy = Bytes.alloc(source.length);

                copy.blit(
                    0,
                    source,
                    0,
                    source.length
                );

                BINValue.bytes(copy);

            case BINValueType.ARRAY:
                BINValue.array(
                    value.asArray().clone()
                );

            case BINValueType.OBJECT:
                BINValue.object(
                    value.asObject().clone()
                );

            default:
                throw new BINException(
                    "Unsupported BIN value type."
                );
        };
    }
}
