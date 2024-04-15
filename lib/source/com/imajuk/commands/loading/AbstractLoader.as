﻿package com.imajuk.commands.loading
    {
        
        
        //--------------------------------------------------------------------------
        //
        //  implementation for IProgress
        //
        //--------------------------------------------------------------------------
        /**
         * @copy IProgess#total
         */
        public function get total():Number
        {
            var t:Number = dispatcher["bytesTotal"];
            return (isNaN(t)) ? 0 : t;
        }
        public function set total(value : Number) : void
        {
            throw new Error("totalの設定は許されていません");
        }
        /**
         * @copy IProgess#value
         */
        public function get value():Number
        {
            var b:Number = dispatcher["bytesLoaded"];
            return isNaN(b) ? 0 : b;        
        }
        public function set value(value : Number) : void
        {
            throw new Error("valueの設定は許されていません");
        }
        /**
         * @copy IProgess#percent
         */
        public function get percent():Number
        {
            var total:Number = total;
            return (total == 0) ? 0 : value / total;
        }

         * @private
         * temporaly for resume();
        private var _context : LoaderContext;
        {
        }
            else if (loader is Sound)
            {
                c = loader;	
			else
                    
            var f : Function = function() : void
            {
                    
                    clearTimeout(intvl);
            };
        	if (loadingSimurationTime > 0)
                intvl = setTimeout(f, loadingSimurationTime * 1000);
            else
                f();
}