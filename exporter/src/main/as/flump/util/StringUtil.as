// Copied from aspire 1.1 on GitHub
package flump.util {

import aspire.util.ClassUtil;
import aspire.util.Joiner;
import flash.utils.Dictionary;

/**
 * Contains useful static function for performing operations on Strings.
 */
public class StringUtil
{

    /**
     * Does the specified string end with any of the specified substrings.
     */
    public static function endsWith (str :String, substr :String, ... additionalSubstrs) :Boolean {
        var startDex :int = str.length - substr.length;
        if ((startDex >= 0) && (str.indexOf(substr, startDex) >= 0)) {
            return true;
        }
        for each (var additional :String in additionalSubstrs) {
            if (endsWith(str, additional)) {
                // Call the non-vararg version of ourselves to keep from repeating the logic
                return true;
            }
        }
        return false;
    }

    /**
     * Does the specified string start with any of the specified substrings.
     */
    public static function startsWith (str :String, substr :String, ... additionalSubstrs) :Boolean {
        if (str.lastIndexOf(substr, 0) == 0) {
            return true;
        }
        for each (var additional :String in additionalSubstrs) {
            if (str.lastIndexOf(additional, 0) == 0) {
                return true;
            }
        }
        return false;
    }


    /**
     * Parse an integer more anally than the built-in parseInt() function,
     * throwing an ArgumentError if there are any invalid characters.
     *
     * The built-in parseInt() will ignore trailing non-integer characters.
     *
     * @param str The string to parse.
     * @param radix The radix to use, from 2 to 16. If not specified the radix will be 10,
     *        unless the String begins with "0x" in which case it will be 16,
     *        or the String begins with "0" in which case it will be 8.
     */
    public static function parseUnsignedInteger (str :String, radix :uint = 0) :uint {
        var result :Number = parseInt0(str, radix, false);
        if (result < 0) {
            throw new ArgumentError(
                    Joiner.pairs("parseUnsignedInteger parsed negative value", "value", str));
        }
        return uint(result);
    }

    /**
     * Parse a Boolean from a String, throwing an ArgumentError if the String
     * contains invalid characters.
     *
     * "1", "0", and any capitalization variation of "true" and "false" are
     * the only valid input values.
     *
     * @param str the String to parse.
     */
    public static function parseBoolean (str :String) :Boolean {
        var originalString :String = str;

        if (str != null) {
            str = str.toLowerCase();
            if (str == "true" || str == "1") {
                return true;
            } else if (str == "false" || str == "0") {
                return false;
            }
        }

        throw new ArgumentError(Joiner.args("Could not convert to Boolean", originalString));
    }

    /**
     * Utility function that strips whitespace from the beginning and end of a String.
     */
    public static function trim (str :String) :String {
        return trimEnd(trimBeginning(str));
    }

    /**
     * Utility function that strips whitespace from the beginning of a String.
     */
    public static function trimBeginning (str :String) :String {
        if (str == null) {
            return null;
        }

        var startIdx :int = 0;
        // this works because charAt() with an invalid index returns "", which is not whitespace
        while (isWhitespace(str.charAt(startIdx))) {
            startIdx++;
        }

        // TODO: is this optimization necessary? It's possible that str.slice() does the same
        // check and just returns 'str' if it's the full length
        return (startIdx > 0) ? str.slice(startIdx, str.length) : str;
    }

    /**
     * Utility function that strips whitespace from the end of a String.
     */
    public static function trimEnd (str :String) :String {
        if (str == null) {
            return null;
        }

        var endIdx :int = str.length;
        // this works because charAt() with an invalid index returns "", which is not whitespace
        while (isWhitespace(str.charAt(endIdx - 1))) {
            endIdx--;
        }

        // TODO: is this optimization necessary? It's possible that str.slice() does the same
        // check and just returns 'str' if it's the full length
        return (endIdx < str.length) ? str.slice(0, endIdx) : str;
    }

    /**
     * @return true if the specified String is == to a single whitespace character.
     */
    public static function isWhitespace (character :String) :Boolean {
        switch (character) {
            case " ":
            case "\t":
            case "\r":
            case "\n":
            case "\f":
                return true;

            default:
                return false;
        }
    }

    /**
     * Nicely format the specified object into a String.
     */
    public static function toString (obj :*, refs :Dictionary = null) :String {
        if (obj == null) { // checks null or undefined
            return String(obj);
        }

        var isDictionary :Boolean = obj is Dictionary;
        if (obj is Array || isDictionary || ClassUtil.isPlainObject(obj)) {
            if (refs == null) {
                refs = new Dictionary();

            } else if (refs[obj] !== undefined) {
                return "[cyclic reference]";
            }
            refs[obj] = true;

            var s :String;
            if (obj is Array) {
                var arr :Array = (obj as Array);
                s = "";
                for (var ii :int = 0; ii < arr.length; ii++) {
                    if (ii > 0) {
                        s += ", ";
                    }
                    s += (ii + ": " + toString(arr[ii], refs));
                }
                return "Array(" + s + ")";

            } else {
                // TODO: maybe do this for any dynamic object? (would have to use describeType)
                s = "";
                for (var prop :String in obj) {
                    if (s.length > 0) {
                        s += ", ";
                    }
                    s += prop + "=>" + toString(obj[prop], refs);
                }
                return (isDictionary ? "Dictionary" : "Object") + "(" + s + ")";
            }

        } else if (obj is XML) {
            return XmlUtil.toXMLString(obj as XML);
        }

        return String(obj);
    }

    /**
     * Internal helper function for parseInteger and parseUnsignedInteger.
     */
    protected static function parseInt0 (str :String, radix :uint, allowNegative :Boolean) :Number {
        if (str == null) {
            throw new ArgumentError("Cannot parseInt(null)");
        }

        var negative :Boolean = (str.charAt(0) == "-");
        if (negative) {
            str = str.substring(1);
        }

        // handle this special case immediately, to prevent confusion about
        // a leading 0 meaning "parse as octal"
        if (str == "0") {
            return 0;
        }

        if (radix == 0) {
            if (startsWith(str, "0x")) {
                str = str.substring(2);
                radix = 16;

            } else if (startsWith(str, "0")) {
                str = str.substring(1);
                radix = 8;

            } else {
                radix = 10;
            }

        } else if (radix == 16 && startsWith(str, "0x")) {
            str = str.substring(2);

        } else if (radix < 2 || radix > 16) {
            throw new ArgumentError(Joiner.args("Radix out of range", radix));
        }

        // now verify that str only contains valid chars for the radix
        for (var ii :int = 0; ii < str.length; ii++) {
            var dex :int = HEX.indexOf(str.charAt(ii).toLowerCase());
            if (dex == -1 || dex >= radix) {
                throw new ArgumentError(Joiner.pairs("Invalid characters in String",
                        "string", arguments[0], "radix", radix));
            }
        }

        var result :Number = parseInt(str, radix);
        if (isNaN(result)) {
            // this shouldn't happen..
            throw new ArgumentError(Joiner.args("Could not parseInt", arguments[0]));
        }
        if (negative) {
            result *= -1;
        }
        return result;
    }

    /** Hexidecimal digits. */
    protected static const HEX :Array = [ "0", "1", "2", "3", "4",
        "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" ];

}
}