//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;
import flump.util.XmlUtil;

public class XflMovie extends XflSymbol
{
    use namespace xflns;

    /** Returns true if the given movie symbol is marked for "Export for ActionScript" */
    public static function isExported (xml :XML) :Boolean {
        return XmlUtil.hasAttr(xml, EXPORT_CLASS_NAME);
    }

    /** Returns the library name of the given movie */
    public static function getName (xml :XML) :String {
        return XmlUtil.getStringAttr(xml, NAME);
    }

    /** Return a Vector of all the symbols this movie references. */
    public static function getSymbolNames(mold : MovieMold) : Vector.<String> {
        var names : Vector.<String> = new Vector.<String>();
        for each (var layer :LayerMold in mold.layers) {
            for each (var kf :KeyframeMold in layer.keyframes) {
                if (kf.ref != null) names.push(kf.ref);
            }
        }
        return names;
    }

    public static function parse (lib :XflLibrary, xml :XML, movie: MovieMold) :MovieMold {
        const location :String = lib.location + ":" + movie.id;

        const layerEls :XMLList = xml.timeline.DOMTimeline[0].layers.DOMLayer;
        for each (var layerEl :XML in layerEls) {
            var layerType :String = XmlUtil.getStringAttr(layerEl, XflLayer.TYPE, "");
            if ((layerType != XflLayer.TYPE_GUIDE) && (layerType != XflLayer.TYPE_FOLDER)) {
                movie.layers.unshift(XflLayer.parse(lib, location, layerEl));
            }
        }
        movie.fillLabels();

        if (movie.layers.length == 0) {
            lib.addError(location, ParseError.CRIT, "Movies must have at least one layer");
        }

        return movie;
    }
}
}
