﻿package com.imajuk.graphics 
    import flash.geom.Rectangle;    
     * @author yamaharu
     */
    public class AlignBL extends AbstractAlignAction implements IALignAction 
        override public function execute(target:DisplayObject, coordinateSpace:AlignCoordinateSpace, aplyDirection : String = Align.BOTH):void
            var y : Number = p.y + (coordinateSize.height - r.height) + offV;
}