﻿package com.imajuk.graphics 
    import flash.geom.Point;    
     * @author yamaharu
     */
    public class AlignBR extends AbstractAlignAction implements IALignAction 
        override public function execute(target:DisplayObject, coordinateSpace:AlignCoordinateSpace, aplyDirection : String = Align.BOTH):void
            var y : Number = p.y + coordinateSize.height - r.height + offV;
}