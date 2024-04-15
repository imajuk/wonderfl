﻿package com.imajuk.commands.loading {    import com.imajuk.commands.AbstractAsyncCommand;    import com.imajuk.commands.IAsynchronousCommand;    import com.imajuk.commands.ICommand;    import com.imajuk.interfaces.IDisposable;    import com.imajuk.interfaces.IProgess;    import com.imajuk.utils.URIUtil;    import flash.display.Loader;    import flash.display.LoaderInfo;    import flash.events.Event;    import flash.media.Sound;    import flash.net.URLLoader;    import flash.net.URLRequest;    import flash.system.LoaderContext;    /**     * ファイルをロードするコマンドです.     *      * <p>抽象非同期コマンドであるAbstractAsyncCommandの特化された実装で、<br/>     * ファイルをロードするという責務のほか、要求されたリクエストの拡張子を判別して、適当なローダーを生成する責務も持っています。</p>     * <p>This is a command that load a file</p>     * <p>This implements AbstractAsyncCommand that is asynchronous command, <br/>     * and has duty to load file, to create suitable loader by extention of required URL.</p>     *      * @author	yamaharu     * @see		Command     * @see		AbstractAsyncCommand     */    public class LoadCommand extends AbstractAsyncCommand implements IAsynchronousCommand, IDisposable, ILoadComponent, IProgess
    {
        // --------------------------------------------------------------------------        //        //  Constructor        //        //--------------------------------------------------------------------------                /**         * コンストラクタ.         *          * @param request	ロード対象が記述された<code>URLRequest</code>         * 					<p><code>URLRequest</code> written loaded URL.</p>         */        private var asBinary : Boolean;        public function LoadCommand(request : URLRequest, defaultLoader : Class = null, context : LoaderContext = null, asBinary : Boolean = false)        {            this.asBinary = asBinary;            this.request = request;            this.context = context;
                        //=================================            // ローダーを作成            //=================================        	if (defaultLoader == null)                _defaultLoader = getLoaderClass(request);            else                _defaultLoader = defaultLoader;            loader = new AbstractLoader(_defaultLoader, asBinary);                        //=================================            // リスナに登録            //=================================            LoadCommandUtil.relayCommonEvent(loader.dispatcher, this);                        super(function ():void            {                loader.addEventListener(Event.COMPLETE, completeHandler);                loader.load(request, context);            });            if (!request)                throw new Error("リクエストが渡されませんでした.");        }                //--------------------------------------------------------------------------        //        //  implementation of IProgessComponent        //        //--------------------------------------------------------------------------        public function get value() : Number        {            return loader.value;        };
        public function set value(value : Number) : void
        {        	//do anything        };

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
        };                //--------------------------------------------------------------------------        //        //  implementation of ILoadComponent        //        //--------------------------------------------------------------------------        /**         * @copy ILoadComponent#waitInitialize         */        public function get waitInitialize():Boolean        {            return loader.waitInitialize;        }        public function set waitInitialize(value:Boolean):void        {            loader.waitInitialize = value;        }        //--------------------------------------------------------------------------        //        //  Variables        //        //--------------------------------------------------------------------------        /**         * @private         */        private var request:URLRequest;        /**         * @private         */        private var context : LoaderContext;
        
        //--------------------------------------------------------------------------        //        //  properties        //        //--------------------------------------------------------------------------        /**         * @private         */        private var loader:AbstractLoader;                /**         * ロードされたオブジェクトを返します.         *          * <p>ロードが終了していない場合は<code>null</code>を返します.</p>         * <p>returns a loaded object.<br/>         * If it doesn't been loaded still, returns <code>null</code>.</p>         */        public function get content():*        {            return loader.content;        }        /**         * ロード情報を表す<code>LoaderInfo</code>を返します.         *          * <p><code>Loader</code>を使用したロード処理の場合は、ロード情報を表す<code>LoaderInfo</code>を返します.<br/>         * <code>URLLoader</code>を使用したロード処理の場合は、<code>null</code>を返します.</p>         * <p>If Loader is used internaly, returns <code>LoaderInfo</code>.<br/>         * If URLLoader is used internaly, returns <code>null</code>.</p>         */        public function get loaderInfo():LoaderInfo        {            return loader.loaderInfo;        }        /**         * ロード対象の拡張子の解析に失敗した場合使用するデフォルトのローダーを指定します.         * 特に指定がない場合は、<code>flash.display.Loader</code>を使用します.         */        private var _defaultLoader:Class;                //--------------------------------------------------------------------------        //        //  Overridden methods        //        //--------------------------------------------------------------------------                /**         * ロード処理を一時停止します.         *          * <p>paused loading execution.</p>         */        override public function pause():Boolean        {            if(!super.pause())                return false;                        return loader.pause();        }        /**         * ロード処理を完全に停止します.         *          * <p>stop loading execution.</p>         */        override public function stop():Boolean        {            if(!super.stop())                return false;                        return loader.stop();        }        /**         * ロード処理を再開します.         *          * <p>stop loading execution.</p>         */        override public function resume():Boolean        {            if(!super.resume())                return false;                            return loader.resume();        }        /**         * @private         */        override public function toString():String        {            return "LoadCommand[" + request.url + "]";        }                //--------------------------------------------------------------------------        //        //  Methods: decide loader class        //        //--------------------------------------------------------------------------                /**         * @private         * @return reference of Class, by extention of URL.          */        private function getLoaderClass(urlRequest:URLRequest):Class        {            var c:Class;            var ext:String = URIUtil.getFileExtention(urlRequest.url);            switch(ext)            {				//TODO binに対応させる。気が向いたら.csvにも                case "xml":                case "txt":                case "TXT":                case "json":                case "atom":                {                    c = URLLoader;                    break;                }                case "swf":                case "SWF":                case "jpg":                case "jpeg":                case "JPG":                case "png":                case "PNG":                case "gif":                case "GIF":                {                    c = Loader;                    break;                }                case "mp3":                    c = Sound;                    break;                default:                    c = _defaultLoader;                    trace("LoadCommand : 対応していない拡張子です.[" + ext + "]\n" + _defaultLoader + "を使ってロードを試みます.");            }            return c;        }        //--------------------------------------------------------------------------        //        //  Methods: utility        //        //--------------------------------------------------------------------------                 /**         * コマンドを複製します.         *          * <p>保持している<code>URLRequest</code>を含め複製します.</p>         * <p>clone Command has same <code>URLRequest</code>.</p>         */        override public function clone():ICommand        {            return new LoadCommand(request, _defaultLoader, context, asBinary);        }                  //--------------------------------------------------------------------------        //        //  Event Handler        //        //--------------------------------------------------------------------------                private function completeHandler(event:Event):void
        {
            LoadCommandUtil.killRelayCommonEvent(loader.dispatcher, this);            loader.removeEventListener(Event.COMPLETE, completeHandler);            finish();        }                public function dispose() : void        {        	loader.dispose();
        }
    }
}
