package flump.util
{

import starling.display.Quad;
import starling.display.Sprite;

public class BorderImage extends Sprite
{

    public function setSize(width : Number, height : Number) : void
    {
        removeChildren();
        if (width > 0 && height > 0)
        {
            const COLOR : uint = 0xef2323;
            var q : Quad = new Quad(width, 1, COLOR);
            addChild(q);
            q = new Quad(1, height, COLOR);
            addChild(q);
            q = new Quad(width, 1, COLOR);
            q.y = height;
            addChild(q);
            q = new Quad(1, height, COLOR);
            q.x = width;
            addChild(q);
        }
    }
}
}
