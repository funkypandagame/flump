//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;
import aspire.util.MathUtil;

import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.text.TextField;

import flump.display.Movie;
import flump.TextFieldUtil;
import flump.Util;
import flump.export.texturepacker.TexturePacker;
import flump.export.view.AnimPreviewWindow;
import flump.export.view.AtlasPreviewWindow;
import flump.mold.MovieMold;
import flump.xfl.XflLibrary;
import flump.xfl.XflTexture;

import mx.core.UIComponent;

import spark.components.Group;
import spark.events.GridSelectionEvent;
import spark.formatters.NumberFormatter;

import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Sprite;

public class PreviewController
{
    public function show (project :ProjectConf, lib :XflLibrary) :void {
        _lib = lib;
        _project = project;

        if (_animPreviewWindow == null || _animPreviewWindow.closed) {
            createAnimWindow();
        } else {
            _animPreviewWindow.activate();
            showInternal();
        }
    }

    protected function createAnimWindow () :void {
        _animPreviewWindow = new AnimPreviewWindow();
        _animPreviewWindow.started = function (container :starling.display.Sprite) :void {
            _container = container;
            _originIcon = Util.createOriginIcon();

            Starling.current.stage.addEventListener(Event.RESIZE, onAnimPreviewResize);
            showInternal();
        };
        _animPreviewWindow.open();

        _animPreviewWindow.movies.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
                function (..._) :void {
                    _animPreviewWindow.textures.selectedIndex = -1;
                    displayLibraryItem(_animPreviewWindow.movies.selectedItem.movie);
                });
        _animPreviewWindow.textures.addEventListener(GridSelectionEvent.SELECTION_CHANGE,
                function (..._) :void {
                    _animPreviewWindow.movies.selectedIndex = -1;
                    displayLibraryItem(_animPreviewWindow.textures.selectedItem.texture);
                });

        _animPreviewWindow.showAtlas.addEventListener(MouseEvent.CLICK, function (..._) :void {
            if (_atlasPreviewWindow == null || _atlasPreviewWindow.closed) {
                createAtlasWindow();
            } else {
                _atlasPreviewWindow.activate();
            }
        });
    }

    protected function createAtlasWindow () :void {
        _atlasPreviewWindow = new AtlasPreviewWindow();
        _atlasPreviewWindow.open();

        // default our atlas scale to our export scale
        var scale :Number = 1;
        var border :int = 1;
        if (_project.exports.length > 0) {
            const exportConf :ExportConf = _project.exports[0];
            scale = exportConf.scale;
            border = exportConf.textureBorder;
        }
        _atlasPreviewWindow.scale.text = "" + scale;
        _atlasPreviewWindow.border.text = "" + border;
        _atlasPreviewWindow.preview.addEventListener(MouseEvent.CLICK, F.bind(updateAtlas));
        updateAtlas();
    }

    protected function updateAtlas () :void {
        // create our atlases
        const exportConf :ExportConf =
            (_project.exports.length > 0 ? _project.exports[0] : new ExportConf());

        const scale :Number = MathUtil.clamp(Number(_atlasPreviewWindow.scale.text), 0.001, 10);
        _atlasPreviewWindow.scale.text = scale.toString();
        const border :int = Math.max(0, int(_atlasPreviewWindow.border.text));
        const optimizeStrategy :String = _atlasPreviewWindow.optimizeBox.selectedItem;
        try {
            const atlases:Vector.<Atlas> = TexturePacker.withLib(_lib)
                    .baseScale(scale)
                    .borderSize(border)
                    .quality(exportConf.quality)
                    .maxAtlasSize(exportConf.maxAtlasSize)
                    .optimizeForSpeed(optimizeStrategy==ExportConf.OPTIMIZE_SPEED)
                    .createAtlases();
        }
        catch (err : Error) {
            ErrorWindowMgr.showErrorPopup("Error", err.toString(), _atlasPreviewWindow);
            return;
        }

        var atlasSize :Number = 0;
        var atlasUsed :Number = 0;
        const sprite :flash.display.Sprite = new flash.display.Sprite();
        for (var ii :int = 0; ii < atlases.length; ++ii) {
            var atlas :Atlas = atlases[ii];
            var atlasSprite :flash.display.Sprite = AtlasUtil.toSprite(atlas);
            var w :int = atlasSprite.width;
            var h :int = atlasSprite.height;

            // atlas info
            var tf :TextField = TextFieldUtil.newBuilder()
                .text("Atlas " + ii + ": " + int(w) + "x" + int(h))
                .color(0x0)
                .autoSizeCenter()
                .build();

            tf.x = 2;
            tf.y = sprite.height;
            sprite.addChild(tf);

            // border
            atlasSprite.graphics.lineStyle(1, 0x0000ff);
            atlasSprite.graphics.drawRect(0, 0, w, h);
            atlasSprite.y = sprite.height;
            sprite.addChild(atlasSprite);

            atlasSize += atlas.area;
            atlasUsed += atlas.used;
        }
        const percentFormatter :NumberFormatter = new NumberFormatter();
        percentFormatter.fractionalDigits = 2;
        _atlasPreviewWindow.atlasWasteValue.text = percentFormatter.format((1.0 - (atlasUsed/atlasSize)) * 100) + "%";

        const uic :UIComponent = new UIComponent();
        uic.addChild(sprite);

        const group :Group = _atlasPreviewWindow.bitmapLayoutGroup;
        group.removeAllElements();
        group.addElement(uic);

        // Agh. I cannot figure out how to get the group to properly resize itself when
        // new elements are added.
        group.width = sprite.width;
        group.height = sprite.height;
    }

    protected function showInternal () :void {
        // we dispose this at the end of the function
        var oldCreator :DisplayCreator = _creator;

        _creator = new DisplayCreator(_lib);

        // All explicitly exported movies
        const previewMovies :Vector.<MovieMold> =
            _lib.movies.filter(function (movie :MovieMold, ..._) :Boolean {
                return _lib.isExported(movie);
            });

        _animPreviewWindow.movies.dataProvider.removeAll();
        for each (var movie :MovieMold in previewMovies) {
            _animPreviewWindow.movies.dataProvider.addItem({
                movie: movie.id,
                drawn: _creator.getMaxDrawn(movie.id)
            });
        }

        _animPreviewWindow.textures.dataProvider.removeAll();
        for each (var tex :XflTexture in _lib.textures) {
            _animPreviewWindow.textures.dataProvider.addItem({texture: tex.symbol});
        }

        if (previewMovies.length > 0) {
            // Play the first movie
            _animPreviewWindow.movies.selectedIndex = 0;
            // Grumble, wish setting the index above would fire the listener
            displayLibraryItem(previewMovies[0].id);
        }

        Starling.current.stage.color = _lib.backgroundColor;

        if (_atlasPreviewWindow != null && !_atlasPreviewWindow.closed) {
            updateAtlas();
        }

        if (oldCreator != null) {
            oldCreator.dispose();
        }
    }

    protected function displayLibraryItem (name :String) :void {
        while (_container.numChildren > 0) _container.removeChildAt(0);
        _previewSprite = _creator.createDisplayObject(name);
        _previewBounds = _previewSprite.bounds;
        _container.addChild(_previewSprite);
        _container.addChild(_originIcon);
        if (_previewSprite is Movie) {
            Starling.juggler.add(Movie(_previewSprite));
        }
        onAnimPreviewResize();
    }

    protected function onAnimPreviewResize (..._) :void {
        _previewSprite.x = _originIcon.x =
            ((_animPreviewWindow.previewGroup.width - _previewBounds.width) * 0.5) - _previewBounds.left;
        _previewSprite.y = _originIcon.y =
            ((_animPreviewWindow.previewGroup.height - _previewBounds.height) * 0.5) - _previewBounds.top;
    }

    protected var _previewSprite :starling.display.DisplayObject;
    protected var _previewBounds :Rectangle;
    protected var _container :starling.display.Sprite;
    protected var _originIcon :starling.display.Sprite;
    protected var _animPreviewWindow :AnimPreviewWindow;
    protected var _atlasPreviewWindow :AtlasPreviewWindow;
    protected var _creator :DisplayCreator;

    protected var _lib :XflLibrary;
    protected var _project :ProjectConf;
}
}
