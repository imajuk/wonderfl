﻿package com.imajuk.commands.loading 
    {
        // --------------------------------------------------------------------------
            
        public function set value(value : Number) : void
        {

        public function get total() : Number
        {
            return loader.total;
        }
        public function set total(value : Number) : void
        {
        	//do anything
        };

        public function get percent() : Number
        {
            return loader.percent;
        };
        
        //--------------------------------------------------------------------------
        {
            LoadCommandUtil.killRelayCommonEvent(loader.dispatcher, this);
        }
    }
}