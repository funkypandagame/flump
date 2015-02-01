//
// Flump - Copyright 2013 Flump Authors

package flump.xfl {
import flash.utils.Dictionary;

public class XflTexture
{

    public var symbol :String;
    public var scale : Number;
    public const keyframes : Dictionary = new Dictionary();

    public function XflTexture (_symbol : String) {
        symbol = _symbol;
        scale = 1;
    }

}
}
