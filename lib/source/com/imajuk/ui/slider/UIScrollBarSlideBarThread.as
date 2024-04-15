﻿package com.imajuk.ui.slider
{
    import flash.geom.Rectangle;

    import com.imajuk.motion.TweensyThread;
    import com.imajuk.ui.IUIView;
    import com.imajuk.ui.UIType;

    import org.libspark.thread.Thread;
        private var value : Number;

                return;
            var destination : int;
            {
                destination = bar.externalX + value;
                prop = {"x":destination};
                noEasing = function():void{bar.x = destination;};
            }
            else
            {
                destination = validate("y", bar.externalY + value);
                prop = {"y":destination};
            }
            var destMin:int = model.destMin;
             
                destination = destMin;
        	   destination = destMax;
        }

        private function validate(prop : String, d : int) : int
        {
        	var range1:Rectangle = model.getBarRange();
            d = Math.max(range2, d);
            d = Math.min(range2 + range1.height, d);
            return d;
        }
