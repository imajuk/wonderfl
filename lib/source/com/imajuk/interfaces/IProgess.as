﻿package com.imajuk.interfaces
{
    import flash.events.IEventDispatcher;
    /**
     * @author shin.yamaharu
     */
    public interface IProgess extends IEventDispatcher
    {
        function get value() : Number;
        function set total(value:Number) : void;
        function get percent() : Number;
    }
}