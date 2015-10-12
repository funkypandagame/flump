package flump.export.texturepacker {

import flash.geom.Point;

import flump.SwfTexture;
import flump.Util;
import flump.export.Atlas;

public class MultiPackerBase {

    public static const MIN_SIZE : uint = 128;

    public function pack(textures :Vector.<SwfTexture>,
                         maxAtlasSize :uint,
                         borderSize :uint,
                         scaleFactor :int,
                         quality :String,
                         filenamePrefix :String,
                         isPowerOf2 : Boolean) : Vector.<Atlas> {
        throw new Error("Abstract function")
    }

    // Estimate the optimal size for the next atlas
    protected function calculateMinimumSize(textures :Vector.<SwfTexture>, borderSize :uint,
                                            maxAtlasSize :uint, isPowerOf2 : Boolean) :Point {
        var area :int = 0;
        var maxW :int = MIN_SIZE;
        var maxH :int = MIN_SIZE;

        for each (var tex :SwfTexture in textures) {
            const w :int = tex.w + (borderSize * 2);
            const h :int = tex.h + (borderSize * 2);
            area += w * h;
            maxW = Math.max(maxW, w);
            maxH = Math.max(maxH, h);
        }
        var size :Point;
        if (isPowerOf2)
        {
            // Double the area until it's big enough
            size = new Point(Util.nextPowerOfTwo(maxW), Util.nextPowerOfTwo(maxH));
            while (size.x * size.y < area) {
                if (size.x < size.y) size.x *= 2;
                else size.y *= 2;
            }
        }
        else
        {
            var minRectSize : uint = Math.max(maxW, maxH);
            while (minRectSize * minRectSize < area) {
                minRectSize = minRectSize * 1.1;
            }
            size = new Point(minRectSize, minRectSize);
        }
        size.x = Math.min(size.x, maxAtlasSize);
        size.y = Math.min(size.y, maxAtlasSize);
        return size;
    }

}
}
