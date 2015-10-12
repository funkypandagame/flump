//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.Map;
import aspire.util.maps.ValueComputingMap;

import flash.utils.Dictionary;

import flump.display.Library;
import flump.display.Movie;
import flump.mold.AtlasMold;
import flump.mold.AtlasTextureMold;
import flump.mold.KeyframeMold;
import flump.mold.LayerMold;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

public class DisplayCreator implements Library
{
    private const _maxDrawn :Map = ValueComputingMap.newMapOf(String, calcMaxDrawn);
    private var _baseTextures :Vector.<Texture> = new <Texture>[];
    private var _imageCreators :Dictionary = new Dictionary(); //<name, ImageCreator>
    private var _lib :XflLibrary;
    private var _scale : Number;

    public function DisplayCreator (lib :XflLibrary, atlases : Vector.<Atlas>, scale : Number) {
        _lib = lib;
        _scale = scale;

        for each (var atlas :Atlas in atlases) {
            var mold :AtlasMold = atlas.toMold();
            var baseTexture :Texture = AtlasUtil.toTexture(atlas);
            _baseTextures.push(baseTexture);
            for each (var atlasTexture :AtlasTextureMold in mold.textures) {
                var tex :Texture = Texture.fromTexture(baseTexture, atlasTexture.bounds);
                var creator :ImageCreator =
                    new ImageCreator(tex, atlasTexture.origin, atlasTexture.symbol);
                _imageCreators[atlasTexture.symbol] = creator;
            }
        }
    }

    public function get imageSymbols () :Vector.<String> {
        // Vector.map can't be used to create a Vector of a new type
        const symbols :Vector.<String> = new <String>[];
        for each (var tex :XflTexture in _lib.textures) {
            symbols.push(tex.symbol);
        }
        return symbols;
    }

    public function get movieSymbols () :Vector.<String> {
        // Vector.map can't be used to create a Vector of a new type
        const symbols :Vector.<String> = new <String>[];
        for each (var movie :MovieMold in _lib.movies) {
            symbols.push(movie.id);
        }
        return symbols;
    }

    public function get isNamespaced () :Boolean {
        return false;
    }

    public function createDisplayObject (id :String) :DisplayObject {
        const imageCreator :ImageCreator = ImageCreator(_imageCreators[id]);
        return (imageCreator != null ? imageCreator.create() : createMovie(id));
    }

    public function createImage (id :String) :Image {
        return Image(createDisplayObject(id));
    }

    public function getImageTexture (id :String) :Texture {
        return ImageCreator(_imageCreators[id]).texture;
    }

    public function createMovie (name :String) :Movie {
        var mold :MovieMold = _lib.getMovieMold(name);
        if (_scale != 1) //TODO optimize better. Could create a new library when scale changes
        {
            mold = mold.clone();
            mold.scale(_scale);
            mold.fillLabels();
        }
        return new Movie(mold, _lib.frameRate, this);
    }

    public function dispose () :void {
        if (_baseTextures != null) {
            for each (var tex :Texture in _baseTextures) {
                tex.dispose();
            }
            _baseTextures = null;
            _imageCreators = null;
        }
    }

    /**
     * Gets the maximum number of pixels drawn in a single frame by the given id. If it's
     * a texture, that's just the number of pixels in the texture. For a movie, it's the frame with
     * the largest set of textures present in its keyframe. For movies inside movies, the frame
     * drawn usage is the maximum that movie can draw. We're trying to get the worst case here.
     */
    public function getMaxDrawn (id :String) :int { return _maxDrawn.get(id); }

    // TODO recalc when scale changes
    protected function calcMaxDrawn (id :String) :int {
        if (id == null) return 0;

        const tex :Texture = getStarlingTexture(id);
        if (tex != null) return tex.width * tex.height;

        var mold :MovieMold = _lib.getMovieMold(id);
        if (_scale != 1)
        {
            mold = mold.clone();
            mold.scale(_scale);
            mold.fillLabels();
        }
        var maxDrawn :int = 0;
        for (var ii :int = 0; ii < mold.frames; ii++) {
            var drawn :int = 0;
            for each (var layer :LayerMold in mold.layers) {
                var kf :KeyframeMold = layer.keyframeForFrame(ii);
                drawn += kf.visible ? getMaxDrawn(kf.ref) : 0;
            }
            maxDrawn = Math.max(maxDrawn, drawn);
        }
        return maxDrawn;
    }

    private function getStarlingTexture (symbol :String) :Texture {
        if (!_imageCreators.hasOwnProperty(symbol)) {
            return null;
        }
        return ImageCreator(_imageCreators[symbol]).texture;
    }

}
}

import flash.geom.Point;

import starling.display.DisplayObject;
import starling.display.Image;
import starling.textures.Texture;

class ImageCreator {
    public var texture :Texture;
    public var origin :Point;
    public var symbol :String;

    public function ImageCreator (texture :Texture, origin :Point, symbol :String) {
        this.texture = texture;
        this.origin = origin;
        this.symbol = symbol;
    }

    public function create () :DisplayObject {
        const image :Image = new Image(texture);
        image.pivotX = origin.x;
        image.pivotY = origin.y;
        image.name = symbol;
        return image;
    }
}
