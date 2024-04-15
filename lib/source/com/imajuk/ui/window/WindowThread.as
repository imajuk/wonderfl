﻿package com.imajuk.ui.window{    import com.imajuk.logs.Logger;    import org.libspark.thread.utils.ParallelExecutor;    import org.libspark.thread.Thread;    /**     * Windowの生成から廃棄までが記述されたテンプレートです.     * テンプレートにそってIWindowContentBuilderを呼び出し処理を実行します.     *      * @author shin.yamaharu     */    public class WindowThread extends Thread     {        private var windowContentBuilderImpl:IWindowContentBuilder;        private var preThread : Thread;        private var postThread : Thread;		/**		 * コンストラクタ		 * @param windowContentBuilderImpl	ウィンドウコンテントを生成するFactoryです		 * @param preThread					指定された場合、このThreadが実行される前に		 * 									start()&amp;join()されます		 * @param postThread				指定された場合、ウィンドウが非表示になる		 * 									タイミングでstart()されます。join()はされません		 */        public function WindowThread(        					windowContentBuilderImpl:IWindowContentBuilder,         					preThread:Thread = null,        					postThread:Thread = null)        {            super();            this.windowContentBuilderImpl = windowContentBuilderImpl;            this.preThread = preThread || new Thread();            this.postThread = postThread || new Thread();        }        private function doTask(f : Function) : void        {            error(Error, function(e : Error):void            {                trace("###", e);            });                        interrupted(function():void            {                t.interrupt();            });                        var t : Thread = f();            t.start();            t.join();        }                override protected function run():void        {            preThread.start();            preThread.join();        	            next(initializeWindowContent);        }                private function initializeWindowContent() : void        {        	doTask(windowContentBuilderImpl.getInitializeContentThread);            next(initializeScroll);        }                private function initializeScroll() : void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getInitializeScrollThread);            next(showCloseButton);        }                /**         * もしクローズボタンがあれば表示する         */        private function showCloseButton() : void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getShowCloseBtnThread);	        next(showWindowFrame);        }        private function showWindowFrame():void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getShowWindowFrameThread);            next(showWindowContent);        }        private function showWindowContent():void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getShowWindowContentThread);            next(startWindowContent);        }                private function startWindowContent() : void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getStartContentThread);        	next(startScroll);        }        private function startScroll():void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getStartScrollThread);        	        	next(idle);        }        private function idle():void        {        	Logger.debug(this);        	doTask(windowContentBuilderImpl.getIdleThread);            next(hide);        }        private function hide():void        {            interrupted(function():void            {                t.interrupt();            });                        var t:ParallelExecutor = new ParallelExecutor();            t.addThread(windowContentBuilderImpl.getHideContentThread());            t.addThread(postThread);            t.start();            t.join();                        next(disposeAsset);        }        private function disposeAsset():void        {            if (isInterrupted)        	   return;        	           	var dis:Thread = windowContentBuilderImpl.dispose();        	dis.start();        	dis.join(); //            if (scrollThread)//                scrollThread.interrupt();        }        override protected function finalize():void        {            trace(this + " : finalize " + []);        }    }}