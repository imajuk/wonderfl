﻿package com.imajuk.behaviors 
{
    import org.libspark.betweenas3.core.easing.IEasing;
    import org.libspark.betweenas3.easing.Cubic;
    import org.libspark.betweenas3.easing.Expo;

    /**
     * @author shinyamaharu
     */
    public class BehaviorDetail 
    {
        public var overDuration : Number       = .4;
        public var downDuration : Number       = .1;
        public var upDuration : Number         = .1;
        
        public var overEasing : IEasing       = Expo.easeOut;
        public var downEasing : IEasing       = Expo.easeOut;
        public var upEasing : IEasing         = Expo.easeOut;
    }
}