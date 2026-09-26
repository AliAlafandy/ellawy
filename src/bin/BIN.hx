package bin;

import haxe.io.Bytes;

import bin.BINArray;
import bin.BINObject;
import bin.BINParser;
import bin.BINValue;
import bin.BINWriter;

/**
 * Public API for Ellawy's portable .bin format.
 *
 * BIN v1 layout:
 *
 *   8 bytes  magic: "BIN"
 *   2 bytes  version
 *   2 bytes  flags
 *   4 bytes  payload length
 *   N bytes  root value
 */
class BIN {
    public static inline final MAGIC:String = "BIN";
    public static inline final VERSION:Int = 1;
    public static inline final HEADER_SIZE:Int = 16;
    public static inline final FLAG_NONE:Int = 0;

    public static inline final TAG_NULL:Int = 0x00;
    public static inline final TAG_FALSE:Int = 0x01;
    public static inline final TAG_TRUE:Int = 0x02;
    public static inline final TAG_INT:Int = 0x03;
    public static inline final TAG_FLOAT64:Int = 0x04;
    public static inline final TAG_STRING:Int = 0x05;
    public static inline final TAG_ARRAY:Int = 0x06;
    public static inline final TAG_OBJECT:Int = 0x07;
    public static inline final TAG_BYTES:Int = 0x08;

    public static function parse(
        bytes:Bytes,
        maxDepth:Int = BINParser.DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = BINParser.DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = BINParser.DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = BINParser.DEFAULT_MAX_TOTAL_BYTES
    ):BINValue {
        return BINParser.parse(
            bytes,
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        );
    }

    public static inline function parseBytes(
        bytes:Bytes,
        maxDepth:Int = BINParser.DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = BINParser.DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = BINParser.DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = BINParser.DEFAULT_MAX_TOTAL_BYTES
    ):BINValue {
        return parse(
            bytes,
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        );
    }

    public static function write(
        value:BINValue,
        maxDepth:Int = BINWriter.DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = BINWriter.DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = BINWriter.DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = BINWriter.DEFAULT_MAX_TOTAL_BYTES
    ):Bytes {
        return BINWriter.write(
            value,
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        );
    }

    public static inline function encode(
        value:BINValue,
        maxDepth:Int = BINWriter.DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = BINWriter.DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = BINWriter.DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = BINWriter.DEFAULT_MAX_TOTAL_BYTES
    ):Bytes {
        return write(
            value,
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        );
    }

    public static function fromDynamic(value:Dynamic):Bytes {
        return write(BINValue.fromDynamic(value));
    }

    #if sys

    public static function read(
        path:String,
        maxDepth:Int = BINParser.DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = BINParser.DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = BINParser.DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = BINParser.DEFAULT_MAX_TOTAL_BYTES
    ):BINValue {
        if (path == null || path.length == 0)
            throw new BINException("BIN path cannot be empty.");

        return parse(
            sys.io.File.getBytes(path),
            maxDepth,
            maxStringBytes,
            maxContainerItems,
            maxTotalBytes
        );
    }

    public static function save(
        path:String,
        value:BINValue,
        maxDepth:Int = BINWriter.DEFAULT_MAX_DEPTH,
        maxStringBytes:Int = BINWriter.DEFAULT_MAX_STRING_BYTES,
        maxContainerItems:Int = BINWriter.DEFAULT_MAX_CONTAINER_ITEMS,
        maxTotalBytes:Int = BINWriter.DEFAULT_MAX_TOTAL_BYTES
    ):Void {
        if (path == null || path.length == 0)
            throw new BINException("BIN path cannot be empty.");

        sys.io.File.saveBytes(
            path,
            write(
                value,
                maxDepth,
                maxStringBytes,
                maxContainerItems,
                maxTotalBytes
            )
        );
    }

    #end

    public static function isBIN(bytes:Bytes):Bool {
        if (bytes == null || bytes.length < MAGIC.length)
            return false;

        var magic = Bytes.ofString(MAGIC);

        for (i in 0...magic.length) {
            if (bytes.get(i) != magic.get(i))
                return false;
        }

        return true;
    }

    public static function version(bytes:Bytes):Int {
        if (!isBIN(bytes))
            throw new BINException("Invalid BIN magic header.");

        if (bytes.length < HEADER_SIZE)
            throw new BINException("BIN file is truncated.");

        return (bytes.get(8) << 8) | bytes.get(9);
    }

    public static function clone(value:BINValue):BINValue {
        return BINParser.cloneValue(value);
    }
}
