package flump.util {

import aspire.error.XmlReadError;

public class XmlUtil
{

    /**
     * Call toXMLString() on the specified XML object safely. This is equivalent to
     * <code>xml.toXMLString()</code> but offers protection from other code that may have changed
     * the default settings used for stringing XML. Also, if you would like to use the
     * non-standard printing settings this method will protect other code from being
     * broken by you.
     *
     * @param xml the xml value to Stringify.
     * @param settings an Object containing your desired XML settings, or null (or omitted) to
     * use the default settings.
     * @see XML#toXMLString()
     * @see XML#setSettings()
     */
    public static function toXMLString (xml :XML, settings :Object = null) :String {
        return safeOp(function () :* {
                    return xml.toXMLString();
                }, settings) as String;
    }

    /**
     * Perform an operation on XML that takes place using the specified settings, and
     * restores the XML settings to their previous values.
     *
     * @param fn a function to be called with no arguments.
     * @param settings an Object containing your desired XML settings, or null (or omitted) to
     * use the default settings.
     *
     * @return the return value of your function, if any.
     * @see XML#setSettings()
     * @see XML#settings()
     */
    public static function safeOp (fn :Function, settings :Object = null) :* {
        var oldSettings :Object = XML.settings();
        try {
            XML.setSettings(settings); // setting to null resets to all the defaults
            return fn();
        } finally {
            XML.setSettings(oldSettings);
        }
    }

    public static function map (xs :XMLList, f :Function) :Array {
        const result :Array = [];
        for each (var node :XML in xs) {
            result.push(f(node));
        }
        return result;
    }

    public static function hasAttr (xml :XML, name :String) :Boolean {
        return (null != xml.attribute(name)[0]);
    }

    public static function getIntAttr (xml :XML, name :String, defaultValue :* = undefined) :int {
        return getAttr(xml, name, defaultValue, parseInt);
    }

    public static function getNumberAttr (xml :XML, name :String, defaultValue :* = undefined) :Number {
        return getAttr(xml, name, defaultValue, parseFloat);
    }

    public static function getBooleanAttr (xml :XML, name :String, defaultValue :* = undefined) :Boolean {
        return getAttr(xml, name, defaultValue, StringUtil.parseBoolean);
    }

    public static function getStringAttr(xml :XML, name :String, defaultValue :* = undefined) :String {
        // read the attribute; throw an error if it doesn't exist (unless we have a default value)
        var attr :XML = xml.attribute(name)[0];
        if (attr == null) {
            if (undefined !== defaultValue) {
                return defaultValue;
            } else {
                throw new XmlReadError("error reading attribute '" + name + "': attribute does not exist", xml);
            }
        }
        return ("_" + attr).substr(1); //this trick fixes the memory leak caused by the master string
    }

    public static function getAttr(xml :XML, name :String, defaultValue :*, parseFunction :Function) :* {
        var value :*;
        // read the attribute; throw an error if it doesn't exist (unless we have a default value)
        var attr :XML = xml.attribute(name)[0];
        if (attr == null) {
            if (undefined !== defaultValue) {
                return defaultValue;
            } else {
                throw new XmlReadError("error reading attribute '" + name + "': attribute does not exist", xml);
            }
        }
        // try to parse the attribute
        try {
            value = parseFunction(attr);
        } catch (e :ArgumentError) {
            throw new XmlReadError("error reading attribute '" + name + "'", xml).initCause(e);
        }
        return value;
    }

}
}