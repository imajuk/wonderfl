﻿/*
 * ActionScript Thread Library
 * 
 * Licensed under the MIT License
 * 
 * Copyright (c) 2008 BeInteractive! (www.be-interactive.org) and
 *                    Spark project  (www.libspark.org)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 */
package org.libspark.thread
{
    import com.imajuk.imajuk;

	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.utils.getDefinitionByName;
	import org.libspark.thread.errors.CurrentThreadNotFoundError;
	import org.libspark.thread.errors.IllegalThreadStateError;
	import org.libspark.thread.errors.InterruptedError;
	import org.libspark.thread.errors.ThreadLibraryNotInitializedError;
	
	/**
	 * Thread クラスは ActionScript Thread Library 1.0 (そうめん) の核となるクラスで、擬似スレッドを実現します.
	 * 
	 * <p>ここで実現される擬似スレッドは、タスクシステムと Java のスレッドモデルをベースとしています。
	 * 処理をいくつかのメソッドに切り分け、呼び出すメソッド (「<em>実行関数</em>」と呼びます) を切り替えつつ
	 * 順々に実行していくことで、処理を進めます。</p>
	 * 
	 * <p>新しいスレッドを作成するためには、まず Thread クラスのサブクラスを作成します。
	 * このサブクラスは、 Thread クラスの run メソッドをオーバーライドする必要があります。
	 * たとえば、「Hello, Thread!!」と出力するスレッドは、次のようになります。</p>
	 * <listing>public class HelloThread extends Thread
	 * {
	 *     override protected function run():void
	 *     {
	 *         trace('Hello, Thread!!');
	 *     }
	 * }</listing>
	 * 
	 * <p>作成したスレッドを実行するためには、 Thread Library を初期化する必要があります。
	 * 次のように、 Thread クラスの静的メソッド initialize を呼び出すことで初期化を行います。
	 * このとき、引数に IThreadExecutor インターフェイスの実装クラスのインスタンスを指定します。
	 * この IThreadExecutor インスタンスは、「いつスレッドを実行するか」を決める重要な役割を担っています。
	 * ここでは、 EnterFrameThreadExecutor クラスのインスタンスを渡し、フレーム実行のタイミングで
	 * スレッドが実行されるようにしています。初期化処理は、アプリケーションの最初で一度だけ行えば、その後呼び出す必要はありません。</p>
	 * <listing>Thread.initialize(new EnterFrameThreadExecutor());</listing>
	 * 
	 * <p>最後に、次のように HelloThread クラスのインスタンスを作り、 start メソッドを呼び出すことで、
	 * スレッドの実行を開始します。</p>
	 * <listing>var t:Thread = new HelloThread();
	 * t.start();</listing>
	 * 
	 * <p>スレッドは親子関係を形成します。この親子関係は、スレッドの実行開始時に決定されます。
	 * スレッドの start を呼び出したスレッド (つまりカレントスレッド) は、親スレッドとなり、
	 * start が呼び出されたスレッドは、その親スレッドの子スレッドとなります。
	 * ただし、 start の呼び出しがスレッドの外 (つまりカレントスレッドが null のとき) に行われた場合、
	 * start が呼び出されたスレッドはトップレベルスレッドとなります。</p>
	 * 
	 * <p>スレッドの親子関係は、スレッドの実行順序と例外の伝播において重要になります。
	 * スレッドの実行は、一番最初に開始されたトップレベルスレッドから始まります。今、このスレッドを A と呼ぶことにします。
	 * A に子スレッドがいる場合、 A の実行よりも先にまず、子スレッドが、開始された順番で実行されます。
	 * この子スレッドが実行されるとき、その子スレッドにさらに子スレッド (Aから見て孫スレッド) がいる場合、
	 * その子スレッドの実行より先に孫スレッドが開始された順番で実行され、これが子スレッドがいなくなるまで続けられます。
	 * 全ての A の子スレッドの実行が終了すると、 A が実行され、次に、A の次に開始されたトップレベルスレッドの実行が
	 * 同様にして続きます。</p>
	 * 
	 * <p>スレッド内で例外が発生し、その例外が、例外が発生したスレッド内で捕捉されなかった場合、
	 * 例外は親スレッドに伝播します。例外が発生したのがトップレベルスレッドで、親スレッドがいない場合、
	 * 例外は uncaughtErrorHandler に渡されます。</p>
	 * 
	 * <p>子スレッドよりも先に親スレッドが終了した場合、その親スレッドの全ての子スレッドは孤児スレッドとなり、
	 * トップレベルスレッドとして再配置されます。</p>
	 * 
	 * <p>スレッドはある時点で、以下のいずれかの状態を取ります。これらの値は ThreadState クラスで定義されており、
	 * state プロパティを通して知ることができます。</p>
	 * <ul>
	 * <li>NEW</li>
	 * <li>RUNNABLE</li>
	 * <li>WAITING</li>
	 * <li>TIMED_WAITING</li>
	 * <li>TERMINATING</li>
	 * <li>TERMINATED</li>
	 * </ul>
	 * 
	 * <p>スレッドが生成されると、まずはじめに状態は「NEW」に設定されます。この後、 start メソッドによって
	 * スレッドが開始されると、状態は「RUNNABLE」に設定されます。「NEW」以外の状態のスレッドを start メソッドによって
	 * 開始することはできません。</p>
	 * 
	 * <p>wait メソッド、 join メソッド等の呼び出しによってスレッドが待機状態になる場合、状態は「WAITING」に
	 * 設定されます。このとき、タイムアウトが設定されるか、sleep メソッドの呼び出しである場合、状態は「TIMED_WAITING」に
	 * 設定されます。待機状態が解除されると状態は元に戻ります。</p>
	 * 
	 * <p>スレッドが終了フェーズに移行すると、状態は「TERMINATING」に設定されます。スレッドが終了フェーズから
	 * 実行フェーズに戻ることは無く、同様に状態が「TERMINATING」から「RUNNABLE」に戻ることもありません。
	 * 終了フェーズが終わり、完全にスレッドが終了すると、状態は「TERMINATED」に設定されます。</p>
	 * 
	 * <p>スレッドの動作を視覚的に知りたい場合、以下の動作チャートを見ることをお勧めします。</p>
	 * <ul>
	 * <li>http://www.libspark.org/htdocs/as3/thread-files/behavior-chart.png</li>
	 * </ul>
	 * 
	 * @author	yossy:beinteractive
	 * @see	#run()
	 * @see	#initialize()
	 * @see	#start()
	 * @see	#uncaughtErrorHandler()
	 * @see	#state
	 * @see	ThreadState
	 * @see	http://www.libspark.org/htdocs/as3/thread-files/behavior-chart.png
	 */
	public class Thread extends Monitor
	{
		private static var _executor:IThreadExecutor;
		private static var _threadIndex:uint = 0;
		private static var _currentThread:Thread = null;
		private static var _toplevelThreads:Array = [];
		private static var _uncaughtErrorHandler:Function = null;
		private static var _defaultErrorHandlers:Dictionary = null;
		
		/**
		 * スレッドライブラリを初期化します.
		 * 
		 * <p>このメソッドは、最初に一度だけ呼び出してください。</p>
		 * 
		 * <p>スレッドの実行は、指定された IThreadExecutor インスタンスによって行われます。
		 * (このメソッド内で、 IThreadExectuor#start が呼び出されます)</p>
		 * 
		 * @param	executor	スレッドの実行を行う IThreadExecutor
		 * @see	IThreadExecutor
		 */
		public static function initialize(executor:IThreadExecutor):void
		{
			_threadIndex = 0;
			_currentThread = null;
			_toplevelThreads.length = 0;
			
			// 古い IThreadExecutor の実行を止める
			if (_executor != null) {
				_executor.stop();
			}
			
			_executor = executor;
			
			// 新しい IThreadExecutor の実行を開始
			if (_executor != null) {
				_executor.start();
			}
		}
		
		/**
		 * initialize メソッドの呼び出しによって IThreadExecutor が設定され、スレッドが実行可能な状態であれば true、そうでなければ false を返します.
		 * 
		 * @see	#initialize()
		 */
		public static function get isReady():Boolean
		{
			return _executor != null;
		}
		
		/**
		 * 現在実行中のスレッドを返します.
		 * 
		 * <p>現在実行中のスレッドがない場合、 null を返します。</p>
		 */
		public static function get currentThread():Thread
		{
			return _currentThread;
		}
		
		/**
		 * 現在実行中のスレッドを返します.
		 * 
		 * <p>ただし、現在実行中のスレッドがない(currentThread が null)の場合は CurrentThreadNotFoundError をスローします。</p>
		 * 
		 * @return	現在実行中のスレッド
		 * @throws	org.libspark.thread.errors.CurrentThreadNotFoundError	現在実行中のスレッドがない場合
		 * @private
		 */
		internal static function getCurrentThread():Thread
		{
			var t:Thread = currentThread;
			
			if (t != null) {
				return t;
			}
			
			throw new CurrentThreadNotFoundError('Expected Thread.currentThread is not null, but actual null.');
		}
		
		/**
		 * どのスレッドにも捕捉されなかった例外のためのハンドラを設定します.
		 * 
		 * <p>スレッド内で例外が発生し、処理されないままトップレベルまで到達するとこのハンドラが呼び出されます。</p>
		 * 
		 * <p>ここに登録する関数は、第一引数に発生した例外である Object と、第二引数に発生元のスレッドである Thread を引数としてとる必要があります。</p>
		 */
		public static function get uncaughtErrorHandler():Function
		{
			return _uncaughtErrorHandler;
		}
		
		/**
		 * @private
		 */
		public static function set uncaughtErrorHandler(value:Function):void
		{
			_uncaughtErrorHandler = value;
		}
		
		/**
		 * 例外ハンドラを取得します.
		 * 
		 * <p>ただし、ユーザーによって例外ハンドラが設定されていない場合、デフォルトのハンドラを返します。</p>
		 * 
		 * @return	ユーザーによって設定された例外ハンドラ。無い場合はデフォルトのハンドラ。
		 * @private
		 */
		private static function getUncaughtErrorHandler():Function
		{
			return uncaughtErrorHandler || defaultErrorHandler;
		}
		
		/**
		 * 例外ハンドラのデフォルトの実装です.
		 * 
		 * <p>このハンドラでは、例外の内容及び発生元の Thread の文字列表現を出力します。</p>
		 * 
		 * @param	e	発生した例外
		 * @param	t	例外が発生したスレッド
		 */
		public static function defaultErrorHandler(e:Object, t:Thread):void
		{
			trace((t ? t.toString() + ' ' : '') + (e is Error ? (e as Error).getStackTrace() : e.toString()));
		}
		
		/**
		 * 現在実行中のスレッドおよびその子スレッドで例外が発生した場合で、error メソッドによるハンドラの指定がなされていない場合にデフォルトで実行する実行関数を設定します.
		 * 
		 * <p>ここで設定される実行関数は、発生した例外である Object と、例外が発生したスレッドである Thread のふたつの引数をとる関数である必要があります。</p>
		 * 
		 * <p>この関数によって例外を処理できた (この関数内で再び例外が発生しなかった) 場合で、この関数内で
		 * next メソッドによる実行関数の設定が行われなかった場合、例外が発生する前の実行関数の設定を復元します。</p>
		 * 
		 * @param	klass	どの型の例外が発生した場合に関数を実行するかを示すクラス
		 * @param	func	例外が発生した際に実行される実行関数
		 * @param	autoTermination	実行関数の実行後、Thread#next(null) を自動的に呼び出すのであれば true, そうでなければ false
		 */
		public static function registerDefaultErrorHandler(klass:Class, func:Function, autoTermination:Boolean = false):void
		{
			if (func != null) {
				addDefaultErrorHandler(klass, func, autoTermination);
			}
			else {
				removeDefaultErrorHandler(klass);
			}
		}
		
		/**
		 * デフォルトエラーハンドラマップを返します.
		 * 
		 * @return	デフォルトエラーハンドラマップ
		 * @private
		 */
		private static function getDefaultErrorHandlers():Dictionary
		{
			return _defaultErrorHandlers || (_defaultErrorHandlers = new Dictionary());
		}
		
		/**
		 * デフォルトエラーハンドラをデフォルトエラーハンドラマップに追加します.
		 * 
		 * @param	klass	エラークラス
		 * @param	handler	エラーハンドラ
		 * @param	reset	リセットするか
		 * @param	autoTermination	自動で next(null) を呼び出すか
		 * @private
		 */
		private static function addDefaultErrorHandler(klass:Class, handler:Function, autoTermination:Boolean):void
		{
			getDefaultErrorHandlers()[getQualifiedClassName(klass)] = new ErrorHandler(handler, false, autoTermination);
		}
		
		/**
		 * デフォルトエラーハンドラをデフォルトエラーハンドラマップから削除します.
		 * 
		 * @param	klass	エラークラス
		 * @private
		 */
		private static function removeDefaultErrorHandler(klass:Class):void
		{
			// ハンドラマップが存在しなければ何もしない
			if (_defaultErrorHandlers == null) {
				return;
			}
			
			// ハンドラマップから削除
			delete _defaultErrorHandlers[getQualifiedClassName(klass)];
		}
		
		/**
		 * 全てのスレッドを実行します.
		 * 
		 * <p>通常、このメソッドは IThreadExector インターフェイスの実装クラスによって呼び出されます。</p>
		 */
		public static function executeAllThreads():void
		{
			// 全てのトップレベルスレッドを呼び出す
			var threads:Array = _toplevelThreads;
			var l:uint = threads.length;
			for (var i:uint = 0; i < l;) {
				var thread:Thread = Thread(threads[i]);
				if (!thread.execute()) {
					// スレッドが終了した場合は削除
					threads.splice(i, 1);
					--l;
				}
				else {
					++i;
				}
				// 伝播すべき例外が発生している場合はキャッチされない例外ハンドラを呼び出す
				// Note: _errorThread が null の場合、この例外はまだ伝播すべきではないことを示す
				if (thread._error != null && thread._errorThread != null) {
					try {
						getUncaughtErrorHandler()(thread._error, thread._errorThread);
					}
					catch (e:Object) {
						defaultErrorHandler(e, null);
					}
					thread._error = null;
					thread._errorThread = null;
				}
			}
		}
		
		/**
		 * 指定されたスレッドをトップレベルスレッドとして追加します.
		 * 
		 * @param	thread	追加するスレッド
		 * @private
		 */
		private static function addToplevelThread(thread:Thread):void
		{
			_toplevelThreads.push(thread);
		}
		
		/**
		 * 指定されたスレッドをトップレベルスレッドとして追加します.
		 * 
		 * @param	threads	追加するスレッドの配列
		 * @private
		 */
		private static function addToplevelThreads(threads:Array):void
		{
			_toplevelThreads.push.apply(_toplevelThreads, threads);
		}
		
		/**
		 * 現在実行中のスレッドが次に実行する実行関数を設定します.
		 * 
		 * <p>この設定は、スレッドの実行のたびにリセットされます。</p>
		 * 
		 * <p>このメソッドの呼び出しによって次に実行する実行関数が設定されない場合、スレッドは終了フェーズへと移行します。</p>
		 * 
		 * @param	func	次に実行する実行関数
		 */
		public static function next(func:Function):void
		{
			getCurrentThread()._runHandler = func;
		}
		
		/**
		 * 現在実行中のスレッドおよびその子スレッドで例外が発生した場合に実行する実行関数を設定します.
		 * 
		 * <p>ここで設定される実行関数は、発生した例外である Object と、例外が発生したスレッドである Thread のふたつの引数をとる関数である必要があります。</p>
		 * 
		 * <p>この関数によって例外を処理できた (この関数内で再び例外が発生しなかった) 場合で、この関数内で
		 * next メソッドによる実行関数の設定が行われなかった場合、例外が発生する前の実行関数の設定を復元します。</p>
		 * 
		 * <p>この設定は、reset 引数が false に設定されない限り、スレッドの実行のたびにリセットされます。</p>
		 * 
		 * @param	klass	どの型の例外が発生した場合に関数を実行するかを示すクラス
		 * @param	func	例外が発生した際に実行される実行関数
		 * @param	reset	次の実行のタイミングでこの設定を削除する場合には true、そうでなければ false
		 * @param	autoTermination	実行関数の実行後、Thread#next(null) を自動的に呼び出すのであれば true, そうでなければ false
		 */
		public static function error(klass:Class, func:Function, reset:Boolean = true, autoTermination:Boolean = false):void
		{
			if (func != null) {
				getCurrentThread().addErrorHandler(klass, func, reset, autoTermination);
			}
			else {
				getCurrentThread().removeErrorHandler(klass);
			}
		}
		
		/**
		 * 現在実行中のスレッドが待機中にタイムアウトした場合に実行する実行関数を設定します.
		 * 
		 * <p>この設定は、スレッドの実行のたびにリセットされます。</p>
		 * 
		 * @param	func	タイムアウトした場合に実行する実行関数
		 */
		public static function timeout(func:Function):void
		{
			getCurrentThread()._timeoutHandler = func;
		}
		
		/**
		 * 現在実行中のスレッドが指定されたイベントが発生した場合に実行する実行関数を設定します.
		 * 
		 * <p>ここで設定される実行関数は、発生したイベントである Event を引数にとる関数である必要があります。</p>
		 * 
		 * <p>このメソッドによってイベントハンドラが設定される場合、スレッドは自動的にイベントが発生するまで待機状態となります。
		 * ただし、 next メソッドによって次に実行する実行関数が設定される場合、待機状態にはならず、実行が継続されます。</p>
		 * 
		 * <p>この設定は、スレッドの実行のたびにリセットされます。</p>
		 * 
		 * @param	dispatcher	イベントリスナーの登録先となるディスパッチャ
		 * @param	type	捕捉するイベント名
		 * @param	func	イベントが発生した場合に実行する実行関数
		 * @param	useCapture	flash.events.IEventDispatcher#addEventListener() の該当する引数を参照してください。
		 * @param	priority	flash.events.IEventDispatcher#addEventListener() の該当する引数を参照してください。
		 * @param	useWeakReference	flash.events.IEventDispatcher#addEventListener() の該当する引数を参照してください。
		 * @see	flash.events.IEventDispatcher#addEventListener()
		 */
		public static function event(dispatcher:IEventDispatcher, type:String, func:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			getCurrentThread().addEventHandler(dispatcher, type, func, useCapture, priority, useWeakReference);
		}
		
		/**
		 * 現在実行中のスレッドの実行を、指定された時間だけ中断させます.
		 * 
		 * <p>指定された時間が経過すると、 sleep メソッドが呼び出されなかった場合と同様に実行が再開されます。</p>
		 * 
		 * <p>スレッドの実行が中断しても、子スレッドの実行が中断されることはありません。</p>
		 * 
		 * @param	time	実行を中断させる時間 (ミリ秒)
		 */
		public static function sleep(time:uint):void
		{
			// time が 0 だと永遠に待ってしまうので最低でも 1 にする
			if (time == 0) {
				time = 1;
			}
			
			// カレントスレッドを取得
			var current:Thread = getCurrentThread();
			
			// sleep 用のモニタがなければ生成
			if (current._sleepMonitor == null) {
				current._sleepMonitor = new Monitor();
			}
			
			// sleep 用のモニタを使って wait をかけて指定時間眠らせる
			current._sleepMonitor.wait(time);
		}
		
		/**
		 * 現在実行中のスレッドが待機中に割り込まれた場合に実行する実行関数を設定します.
		 * 
		 * <p>このメソッドによって割り込みハンドラが設定されていない状態で、待機中に割り込みが発生すると、
		 * 例外 InterruptedError が発生します。</p>
		 * 
		 * <p>この設定はスレッドの実行のたびにリセットされます。</p>
		 * 
		 * @param	func	待機中に割り込まれた場合に実行する実行関数
		 */
		public static function interrupted(func:Function):void
		{
			getCurrentThread()._interruptedHandler = func;
		}
		
		/**
		 * 現在のスレッドが割り込まれているかどうかを調べます.
		 * 
		 * <p>このメソッドによりスレッドの「割り込みステータス」がクリアされます。
		 * つまり、このメソッドが続けて2回呼び出された場合、2回目の呼び出しは false を返します。</p>
		 * 
		 * @return	現在のスレッドが割り込まれている場合は true、そうでない場合は false
		 */
		public static function checkInterrupted():Boolean
		{
			// カレントスレッドを取得
			var current:Thread = getCurrentThread();
			
			// 割り込みステータスを取得
			var status:Boolean = current._isInterrupted;
			
			// ステータスが設定されている場合はクリア
			if (status) {
				current._isInterrupted = false;
			}
			
			// ステータスを返す
			return status;
		}
		
		/**
		 * 新しい Thread クラスのインスタンスを生成します.
		 */
		public function Thread()
		{
			_id = ++_threadIndex;
			_name = 'Thread' + _id;
			_state = ThreadState.NEW;
			_runningState = ThreadState.NEW;
			_children = null;
			_runHandler = null;
			_savedRunHandler = null;
			_timeoutHandler = null;
			_interruptedHandler = null;
			_waitMonitor = null;
			_joinMonitor = null;
			_sleepMonitor = null;
			_eventMonitor = null;
			_event = null;
			_errorHandlers = null;
			_error = null;
			_errorThread = null;
			_eventHandlers = null;
			_isInterrupted = false;
		}
		
		private var _id:uint;
		private var _name:String;
		private var _state:uint;
		private var _runningState:uint;
		private var _children:Array;
		private var _runHandler:Function;
		private var _savedRunHandler:Function;
		private var _timeoutHandler:Function;
		private var _interruptedHandler:Function;
		private var _waitMonitor:IMonitor;
		private var _joinMonitor:IMonitor;
		private var _sleepMonitor:IMonitor;
		private var _eventMonitor:IMonitor;
		private var _event:Event;
		private var _errorHandlers:Dictionary;
		private var _error:Object;
		private var _errorThread:Thread;
		private var _eventHandlers:Array;
		private var _isInterrupted:Boolean;
		
		/**
		 * このスレッドのユニークな識別子を返します.
		 * 
		 * <p>initialize メソッドが呼び出されない限り、ふたつのスレッドに同じ id が割り振られることはありません。</p>
		 */
		public function get id():uint
		{
			return _id;
		}
		
		/**
		 * このスレッドの名前を設定します.
		 */
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * @private
		 */
		public function set name(value:String):void
		{
			_name = value;
		}
		
		/**
		 * このスレッドのクラス名を返します.
		 * 
		 * <p>デフォルトでは、 getQualifiedClassName メソッドを使用してクラス名を取得します。</p>
		 */
		public function get className():String
		{
			var names:Array = getQualifiedClassName(this).split(/::/);
			return names.length == 2 ? names[1] : names[0];
		}
		
		/**
		 * このスレッドの状態を返します.
		 * 
		 * <p>返される値は、 ThreadState クラスで定義されている定数のいずれかになります。</p>
		 * 
		 * @see	ThreadState
		 */
		public function get state():uint
		{
			return _state;
		}
		
		/**
		 * このスレッドが割り込まれている場合は true、そうでない場合は false を返します.
		 * 
		 * <p>このプロパティが true を返すようになるのは、待機状態<em>でない</em>スレッドに対して、
		 * interrupt メソッドで割り込んだ場合です。</p>
		 * 
		 * @see	#interrupt()
		 */
		public function get isInterrupted():Boolean
		{
			return _isInterrupted;
		}
		
		/**
		 * スレッドを開始します.
		 * 
		 * <p>スレッドが既に開始されている場合 (state が NEW でない場合) は IllegalThreadStateError が
		 * スローされます。</p>
		 * 
		 * <p>スレッドライブラリが初期化されていない状態の場合 (isReady が false の場合) は ThreadLibraryNotInitializedError が
		 * スローされます。</p>
		 * 
		 * <p>あるスレッドの実行中にこのメソッドが呼び出された場合、そのスレッドはこのメソッドが呼び出されたスレッドの親スレッドとなり、
		 * このメソッドが呼び出されたスレッドは子スレッドとなります。</p>
		 * 
		 * <p>スレッドが実行中で無い場合にこのメソッドが呼び出された場合、このメソッドが呼び出されたスレッドはトップレベルスレッドとなります。</p>
		 * 
		 * <p>このメソッドが呼び出されると、実行関数はまず run メソッドに設定されます。</p>
		 * 
		 * @throws	org.libspark.thread.errors.IllegalThreadStateError	スレッドが既に開始されている場合
		 * @throws	org.libspark.thread.errors.ThreadLibraryNotInitializedError	スレッドライブラリが初期化されていない場合
		 */
		public function start():void
		{
			// 初期化されていなければエラー
			if (!isReady) {
				throw new ThreadLibraryNotInitializedError('Thread Library is not initialized. Please call Thread#initialize before.');
			}
			
			// 既に実行されていたらエラー
			if (_state != ThreadState.NEW) {
				throw new IllegalThreadStateError('Thread is already running.');
			}
			
			// state を実行フェーズに切り替える
			_state = ThreadState.RUNNABLE;
			_runningState = ThreadState.RUNNABLE;
			
			// 次の実行関数を run に設定
			_runHandler = run;
			
			// カレントスレッドを取得
			var current:Thread = currentThread;
			
			if (current != null) {
				// カレントスレッドがある(=別のスレッド内で start された)場合はそのスレッドの子となる
				current.addChildThread(this);
			}
			else {
				// カレントスレッドがない場合はトップレベルスレッドとなる
				addToplevelThread(this);
			}
		}
		
		/**
		 * このスレッドを待機状態に移行させます.
		 * 
		 * <p>このメソッドは IMonitor インターフェイスの実装クラスによって内部的にのみ呼び出されます。</p>
		 * 
		 * @param	timeout	タイムアウト付かどうか
		 * @param	monitor	待機先のモニタ
		 * @private
		 */
		internal function monitorWait(timeout:Boolean, monitor:IMonitor):void
		{
			// wait できる状態でなければエラー
			if ((_state != ThreadState.RUNNABLE && _state != ThreadState.TERMINATING) || _waitMonitor != null) {
				throw new IllegalThreadStateError('Thread can not wait.');
			}
			
			// state を待機状態に切り替える
			_state = timeout ? ThreadState.TIMED_WAITING : ThreadState.WAITING;
			
			// モニタを保存
			_waitMonitor = monitor;
		}
		
		/**
		 * このスレッドを待機状態から復帰させます.
		 * 
		 * <p>このメソッドは IMonitor インターフェイスの実装クラスによって内部的にのみ呼び出されます。</p>
		 * 
		 * @param	monitor	待機先のモニタ
		 * @private
		 */
		internal function monitorWakeup(monitor:IMonitor):void
		{
			// 待機状態でなければエラー
			if ((_state != ThreadState.WAITING && _state != ThreadState.TIMED_WAITING) || _waitMonitor != monitor) {
				throw new IllegalThreadStateError('Thread can not wakeup.');
			}
			
			// state を実行状態に切り替える
			_state = _runningState;
			
			// 保存されていたモニタを破棄
			_waitMonitor = null;
		}
		
		/**
		 * このスレッドを待機状態からタイムアウトさせます.
		 * 
		 * <p>このメソッドは IMonitor インターフェイスの実装クラスによって内部的にのみ呼び出されます。</p>
		 * 
		 * @param	monitor	待機先のモニタ
		 * @private
		 */
		internal function monitorTimeout(monitor:IMonitor):void
		{
			// 待機時間付の待機状態でなければエラー
			if (_state != ThreadState.TIMED_WAITING || _waitMonitor != monitor) {
				throw new IllegalThreadStateError('Thread can not wakeup.');
			}
			
			// state を実行状態に切り替える
			_state = _runningState;
			
			// sleep によるタイムアウトではない場合
			if (_waitMonitor != _sleepMonitor) {
				// 次に実行する実行関数をタイムアウト用のものに切り替える
				if (_timeoutHandler != null) {
					_runHandler = _timeoutHandler;
				}
			}
			
			// 保存されていたモニタを破棄
			_waitMonitor = null;
		}
		
		/**
		 * join 用のモニタを返します.
		 * 
		 * @return	join 用のモニタ
		 * @private
		 */
		private function getJoinMonitor():IMonitor
		{
			return _joinMonitor || (_joinMonitor = new Monitor());
		}
		
		/**
		 * このスレッドが終了するまで、現在のスレッドを待機させます.
		 * 
		 * @param	timeout	待機させる時間 (ミリ秒)。 0 を指定した場合、永遠に待ち続けます
		 * @return	待機する必要がある場合は true、そうでない場合は false
		 */
		public function join(timeout:uint = 0):Boolean
		{
			// 既に終了していたらそのまま帰る
			if (_state == ThreadState.TERMINATED) {
				return false;
			}
			
			// join 用のモニタで wait する
			getJoinMonitor().wait(timeout);
			
			return true;
		}
		
		/**
		 * このスレッドに割り込みます.
		 * 
		 * <p>このスレッドが待機中である場合、割り込みステータスはクリアされ、スレッドが起床します。
		 * このとき、割り込みハンドラが設定されていれば実行関数を割り込みハンドラに設定して実行を再開し、
		 * そうでない場合は InterruptedError を発生させます。</p>
		 * 
		 * <p>待機中でない場合、このスレッドの割り込みステータスが設定されます。</p>
		 */
		public function interrupt():void
		{
			if (_state == ThreadState.WAITING || _state == ThreadState.TIMED_WAITING) {
				// 待機中の場合
				// モニタに対して待機セットから抜けることを伝える
				_waitMonitor.leave(this);
				_waitMonitor = null;
				// state を切り替える
				_state = _runningState;
				
				// 割り込みハンドラがあれば
				if (_interruptedHandler != null) {
					
					// 実行関数を割り込みハンドラに設定
					_runHandler = _interruptedHandler;
					
					// 入れ子になる場合があるのでカレントスレッドを保存
					var current:Thread = _currentThread;
					
					try {
						// そしてすぐ実行してみる
						internalExecute(null, this);
					}
					finally {
						// カレントスレッドを復元
						_currentThread = current;
					}
				}
				else {
					// 割り込みハンドラがなければ例外を発生
					_error = new InterruptedError();
				}
			}
			else {
				// そうでない場合は割り込みステータスを設定
				_isInterrupted = true;
			}
		}
		
		/**
		 * 子スレッドの配列を返します.
		 * 
		 * @return	子スレッドの配列
		 * @private
		 */
		private function getChildren():Array
		{
			return _children || (_children = []);
		}
		
		/**
		 * 子スレッドを子スレッドの配列に追加します.
		 * 
		 * @param	thread	追加する子スレッド
		 * @private
		 */
		private function addChildThread(thread:Thread):void
		{
			getChildren().push(thread);
		}
		
		/**
		 * エラーハンドラマップを返します.
		 * 
		 * @return	エラーハンドラマップ
		 * @private
		 */
		private function getErrorHandlers():Dictionary
		{
			return _errorHandlers || (_errorHandlers = new Dictionary());
		}
		
		/**
		 * エラーハンドラをエラーハンドラマップに追加します.
		 * 
		 * @param	klass	エラークラス
		 * @param	handler	エラーハンドラ
		 * @param	reset	リセットするか
		 * @param	autoTermination	自動で next(null) を呼び出すか
		 * @private
		 */
		private function addErrorHandler(klass:Class, handler:Function, reset:Boolean, autoTermination:Boolean):void
		{
			getErrorHandlers()[getQualifiedClassName(klass)] = new ErrorHandler(handler, reset, autoTermination);
		}
		
		/**
		 * エラーハンドラをエラーハンドラマップから削除します.
		 * 
		 * @param	klass	エラークラス
		 * @private
		 */
		private function removeErrorHandler(klass:Class):void
		{
			// ハンドラマップが存在しなければ何もしない
			if (_errorHandlers == null) {
				return;
			}
			
			// ハンドラマップから削除
			delete _errorHandlers[getQualifiedClassName(klass)];
		}
		
		/**
		 * エラーハンドラマップをリセットします.
		 * 
		 * @private
		 */
		private function resetErrorHandlers():void
		{
			// ハンドラマップが存在しなければ何もしない
			if (_errorHandlers == null) {
				return;
			}
			
			// 登録されているハンドラを巡回
			for (var key:String in _errorHandlers) {
				// reset が true であればハンドラを削除する
				if (ErrorHandler(_errorHandlers[key]).reset) {
					delete _errorHandlers[key];
				}
			}
		}
		
		/**
		 * 指定されたエラーに該当するエラーハンドラを返します.
		 * 
		 * <p>エラーハンドラが見つからず、デフォルトのエラーハンドラが登録されている場合、それを返します。</p>
		 * 
		 * @param	error	エラー
		 * @return	該当するエラーハンドラ。無ければ null
		 * @private
		 */
		private function getErrorHandler(error:Object):ErrorHandler
		{
			// まずスレッド自身に登録されているエラーハンドラを検索
			var handler:ErrorHandler = getErrorHandlerFrom(error, _errorHandlers);
			// 見つからなければ、デフォルトのエラーハンドラを検索
			if (handler == null) {
				handler = getErrorHandlerFrom(error, _defaultErrorHandlers);
			}
			return handler;
		}
		
		/**
		 * 指定されたエラーに該当するエラーハンドラを指定されたハンドラマップから返します.
		 * 
		 * @param	error	エラー
		 * @param	handlers	ハンドラの検索先となるハンドラマップ
		 * @return	該当するエラーハンドラ。無ければ null
		 */
		private function getErrorHandlerFrom(error:Object, handlers:Dictionary):ErrorHandler
		{
			// ハンドラマップが存在しなければ null を返す
			if (handlers == null) {
				return null;
			}
			
			// error のクラス名を取得
			var className:String = getQualifiedClassName(error);
			
			// クラス名が取得できる限り回す
			while (className != null) {
				// ハンドラマップからクラス名をキーにしてハンドラを検索する
				var handler:ErrorHandler = handlers[className];
				// 見つかればそれを返す
				if (handler != null) {
					return handler;
				}
				// 見つからなければ、スーパークラスを辿る
				try {
					className = getQualifiedSuperclassName(getDefinitionByName(className));
				}
				catch (e:ReferenceError) {
					// ここで出る ReferenceError は getDefinitionByName によるもの
					// プライベートクラス等の場合に起こりうる
					className = null;
				}
			}
			
			return null;
		}
		
		/**
		 * イベント待機用のモニタを返します.
		 * 
		 * @return	イベント待機用のモニタ
		 * @private
		 */
		private function getEventMonitor():IMonitor
		{
			return _eventMonitor || (_eventMonitor = new Monitor());
		}
		
		/**
		 * イベントハンドラの配列を返します.
		 * 
		 * @return	イベントハンドラの配列
		 * @private
		 */
		private function getEventHandlers():Array
		{
			return _eventHandlers || (_eventHandlers = []);
		}
		
		/**
		 * イベントハンドラをイベントハンドラの配列に追加します.
		 * 
		 * @param	dispatcher	ディスパッチャ
		 * @param	type	イベントタイプ
		 * @param	func	イベントハンドラ
		 * @param	useCapture	addEventListener 参照
		 * @param	priority	addEventListener 参照
		 * @param	useWeakReference	addEventListener 参照
		 * @private
		 */
		private function addEventHandler(dispatcher:IEventDispatcher, type:String, func:Function, useCapture:Boolean, priority:int, useWeakReference:Boolean):void
		{
			// イベントハンドラを作成してリストに追加
			getEventHandlers().push(new EventHandler(dispatcher, type, eventHandler, func, useCapture, priority, useWeakReference));
		}
		
		/**
		 * イベントハンドラの配列をリセットします.
		 * 
		 * @private
		 */
		private function resetEventHandlers():void
		{
			// イベントハンドラリストがなければ何もしない
			if (_eventHandlers == null) {
				return;
			}
			
			// 全てのイベントハンドラの登録を解除
			for each (var handler:EventHandler in _eventHandlers) {
				handler.unregister();
			}
			
			// 配列を初期化
			_eventHandlers.length = 0;
		}
		
		/**
		 * イベントが発生した際に実行されるハンドラです.
		 * 
		 * @param	e	発生したイベント
		 * @param	handler	該当するイベントハンドラ
		 * @private
		 */
		private function eventHandler(e:Event, handler:EventHandler):void
		{
			// 既にイベントが起こっていれば何もしない
			if (_event != null) {
				return;
			}
			
			// イベントを保存
			_event = e;
			
			// 該当するイベントハンドラを次の実行関数に設定
			_runHandler = handler.func;
			
			// イベントハンドラをリセット
			resetEventHandlers();
			
			// 待機状態である場合
			if (_waitMonitor != null) {
				// モニタに対して待機セットから抜けることを伝える
				_waitMonitor.leave(this);
				// 保存されていたモニタを破棄
				_waitMonitor = null;
			}
			
			// state を実行状態に切り替える
			_state = _runningState;
			
			// 入れ子になる場合があるのでカレントスレッドを保存
			var current:Thread = _currentThread;
			
			try {
				// そしてすぐ実行してみる
				internalExecute(null, this);
			}
			finally {
				// カレントスレッドを復元
				_currentThread = current;
			}
		}
		
		/**
		 * 子スレッドを含め、このスレッドを実行します.
		 * 
		 * @return	このスレッドの実行が継続していれば true、そうでなければ (実行が終了したら) false
		 * @private
		 */
		private function execute():Boolean
		{
			// まだ start していなければ何もしない
			if (_state == ThreadState.NEW) {
				return true;
			}
			// 既に終了していれば何もしない
			if (_state == ThreadState.TERMINATED) {
				return false;
			}
			
			// 発生した例外
			var error:Object = _error;
			var errorThread:Thread = _errorThread || this;
			
			// すべての子スレッドを呼び出す
			var children:Array = _children;
			if (children != null) {
				var cl:uint = children.length;
				for (var ci:uint = 0; ci < cl; ) {
					var child:Thread = Thread(children[ci]);
					if (!child.execute()) {
						// 終了したら削除
						children.splice(ci, 1);
						--cl;
					}
					else {
						++ci;
					}
					// 子スレッドで例外が起きていたら一番最初のものを保存
					// Note: _errorThread が null の場合、その例外はまだ親に伝播するべきではないことを示す
					if (child._error != null && child._errorThread != null && error == null) {
						error = child._error;
						errorThread = child._errorThread;
						child._error = null;
						child._errorThread = null;
					}
				}
			}
			
			return internalExecute(error, errorThread);
		}
		
		/**
		 * このスレッドを実行します.
		 * 
		 * <p>子スレッドは実行されません。</p>
		 * 
		 * @param	error	ここに来るまでに発生したエラー
		 * @param	errorThread	エラーが発生した場合、その発生元のスレッド
		 * @return	このスレッドの実行が継続していれば true、そうでなければ (実行が終了したら) false
		 * @private
		 */
		private function internalExecute(error:Object, errorThread:Thread):Boolean
		{
			if (_state == ThreadState.WAITING || _state == ThreadState.TIMED_WAITING) {
				if (error != null) {
					// 待機状態で子スレッドによる例外発生していた場合は無理やり起きる
					// モニタに対して待機セットから抜けることを伝える
					_waitMonitor.leave(this);
					_waitMonitor = null;
					// state を切り替える
					_state = _runningState;
				}
				else {
					// 例外が発生していない場合はここでリターン
					return true;
				}
			}
			
			// 今回実行する実行関数
			var runHandler:Function = null;
			// エラーハンドラ
			var errorHandler:ErrorHandler = null;
			
			if (error != null) {
				
				// 例外が発生していた場合は例外ハンドラを選択する
				errorHandler = getErrorHandler(error);
				
				if (errorHandler != null) {
					// ハンドラが見つかった場合
					// 例外が子から伝播してきた場合、割り込まれていると考え実行関数を保存する
					if (errorThread != this) {
						_savedRunHandler = _runHandler;
					}
					else {
						// 子からの伝播でない場合、自力で処理したということで保存されている例外をクリア
						_error = null;
					}
					// 実行関数をエラーハンドラに設定
					runHandler = errorHandler.handler;
				}
				else {
					// 見つからなかった場合はこのスレッドは終了フェーズに移行し親に例外を伝播する
					if (_runningState != ThreadState.TERMINATING) {
						// 既に終了フェーズでない場合のみ
						// state を終了フェーズに切り替える
						_state = ThreadState.TERMINATING;
						_runningState = ThreadState.TERMINATING;
						// 実行関数を finalize に設定
						runHandler = finalize;
					}
					// 親に伝播するよう例外を保存
					_error = error;
					_errorThread = errorThread;
				}
			}
			else {
				// 子スレッドによる例外が発生していない場合は前回指定された実行関数を設定
				runHandler = _runHandler;
			}
			
			// 実行関数をリセット
			_runHandler = null;
			// タイムアウトハンドラをリセット
			_timeoutHandler = null;
			// イベントハンドラをリセット
			resetEventHandlers();
			// エラーハンドラをリセット
			resetErrorHandlers();
			// 割り込みハンドラをリセット
			_interruptedHandler = null;
			
			// エラーハンドラが実行されようとしている場合、実行終了後に復帰できるように保存しておいた実行関数を設定
			if (errorHandler != null) {
				_runHandler = _savedRunHandler;
			}
			
			// Note: finalize の最後で wait が入って待機状態になった後に起きた等の場合に、
			//       runHandler が null の状態でここに到達することがある
			if (runHandler != null) {
				
				// カレントスレッドを設定
				_currentThread = this;
				
				 /**
                 * 
                 */
                for (var key : * in imajuk::meta) {
                    if(key != null && key === runHandler)
                    {
                        next(runHandler);
                        runHandler = imajuk::meta[key];
                        delete imajuk::meta[key];
                        break;
                    }
                }
                /**
                 * 
                 */
				
				try {
					// 実行関数を呼び出す
					if (errorHandler != null) {
						// エラーハンドラである場合は例外と例外の発生元のスレッドを引数として渡す
						runHandler.apply(this, [error, errorThread]);
						// 自動終了が求められていれば next(null) を呼び出す
						if (errorHandler.autoTermination) {
							next(null);
						}
					}
					else if (_event != null) {
						var ev:Event = _event;
						_event = null;
						// イベントハンドラである場合はイベントを渡す
						runHandler.apply(this, [ev]);
					}
					else {
						// それ以外の場合は引数なしで呼び出す
						runHandler.apply(this);
					}
				}
				catch (e:Object) {
					// 例外が発生した場合例外を保存
					_error = e;
					// エラーハンドラ以外で例外が発生し、かつ該当するエラーハンドラが存在する場合
					if (errorHandler == null && getErrorHandler(e) != null) {
						// 自力で例外を回復できる可能性があるので強制的に runHandler を非 null にして次に繰り越す
						// このとき、エラーハンドラ実行後に復帰するために runHandler を保存しておく
						// run はダミーで意味はない
						_savedRunHandler = _runHandler;
						_runHandler = run;
					}
					else {
						// それ以外の場合は例外を親に伝播する必要がある
						// 例外が親に伝播するように発生元スレッドを設定
						_errorThread = this;
						// 実行関数の設定をクリアして強制的に終了フェーズに移行させる
						_runHandler = null;
					}
					
				}
				finally {
					// カレントスレッドを元に戻す
					_currentThread = null;
				}
			}
			
			// 今エラーハンドラを実行し、かつエラーが発生していない場合、保存しておいた実行関数はもう必要ないので破棄
			if (errorHandler != null && _error == null) {
				_savedRunHandler = null;
			}
			
			// イベントハンドラが設定された場合
			if (_eventHandlers != null && _eventHandlers.length > 0) {
				// エラーが発生していなければ
				if (_error == null) {
					// 全てのイベントハンドラを登録
					for each (var eventHandler:EventHandler in _eventHandlers) {
						eventHandler.register();
					}
					// 次に実行する実行関数が設定されていない場合で
					if (_runHandler == null) {
						// まだ待機状態で無い場合、自動で待機状態に移行する
						if (_waitMonitor == null) {
							try {
								_currentThread = this;
								getEventMonitor().wait();
							}
							finally {
								_currentThread = null;
							}
						}
					}
				}
			}

			
			if (_runHandler != null) {
				// 次に実行する実行関数が設定されている場合実行を継続
			}
			else {
				// 次に実行する実行関数が設定されていない場合
				if (_state == ThreadState.WAITING || _state == ThreadState.TIMED_WAITING) {
					// 待機状態に入っている場合は次に繰り越す
				}
				else if (_runningState == ThreadState.TERMINATING) {
					// 終了フェーズだった場合は実行を終了する
					// 自分の子スレッドを、孤児スレッドとしてトップレベルに移動する
					if (_children != null) {
						addToplevelThreads(_children);
						// 子スレッドは破棄
						_children = null;
					}
					// state を終了状態に切り替える
					_state = ThreadState.TERMINATED;
					_runningState = ThreadState.TERMINATED;
					// join 用のモニタが存在(=join 待ちしているスレッドが存在)すれば notifyAll で起こす
					if (_joinMonitor != null) {
						_joinMonitor.notifyAll();
						_joinMonitor = null;
					}
					// 終了
					return false;
				}
				else {
					// 終了フェーズでない場合は終了フェーズに入る
					// state を終了フェーズに切り替える
					_state = ThreadState.TERMINATING;
					_runningState = ThreadState.TERMINATING;
					// 次の実行関数を finalize に設定
					_runHandler = finalize;
				}
			}
			
			return true;
		}
		
		/**
		 * このメソッドをオーバーライドして、スレッドの処理を記述します.
		 * 
		 * <p>start メソッドが呼び出され、スレッドの実行が開始されると、まずはじめにこのメソッドが実行関数として設定され、
		 * スレッドが実行されます。</p>
		 * 
		 * <p>このメソッド内で next メソッドを呼び出すことにより、次の実行関数を設定することができます。
		 * 次の実行関数が設定されない場合、スレッドは終了フェーズへと移行します。</p>
		 * 
		 * <p>next メソッドのほか、 wait, join, sleep, event, timeout, error, interrupted といった
		 * メソッドを呼び出すことで、スレッドの動作を様々に制御することができます。</p>
		 * 
		 * @see	#next()
		 * @see	#join()
		 * @see	#sleep()
		 * @see	#event()
		 * @see	#timeout()
		 * @see	#error()
		 * @see	#interrupted()
		 * @see	#interrupt()
		 * @see	#finalize()
		 */
		protected function run():void
		{
			
		}
		
		/**
		 * このメソッドをオーバーライドして、スレッドの終了処理を記述します.
		 * 
		 * <p>スレッドが終了フェーズに移行すると、必ずこのメソッドが実行関数に設定され、スレッドが実行されます。
		 * 例外が発生したりした場合でも、必ず終了フェーズに移行するので、スレッドが終了する前にはこのメソッドが実行されることが
		 * 確実に保証されています。</p>
		 * 
		 * <p>このメソッドも実行関数と同じ扱いであるため、 next をはじめとするメソッドによってスレッドを制御することが可能です。</p>
		 * 
		 * <p>スレッドはこのメソッドを利用して終了処理を行い、いかなる状況でも安全に終了することを保証するべきです。</p>
		 */
		protected function finalize():void
		{
			
		}
		
		/**
		 * このスレッドの名前を整形して返します.
		 * 
		 * <p>デフォルトでは、</p>
		 * <pre>'[' + className + ' ' + name + ']'</pre>
		 * <p>と等価な値が返されます。</p>
		 * 
		 * <p>このメソッドの呼び出し結果は、 toString メソッドなどで使用されます。</p>
		 * 
		 * @param	name	スレッドの名前
		 * @return	整形された名前
		 */
		protected function formatName(name:String):String
		{
			return '[' + className + ' ' + name + ']';
		}
		
		/**
		 * このスレッドの文字列表現を返します.
		 * 
		 * <p>デフォルトでは、 formatName メソッドを、このスレッドの名前を引数にして呼び出した結果です。</p>
		 * 
		 * @return	このスレッドの文字列表現
		 */
		public function toString():String
		{
			return formatName(name);
		}
		
		imajuk var meta:Dictionary = new Dictionary(true);
		imajuk function registerMetadata(f:Function, callback:Function):void
		{
			imajuk::meta[f] = callback;
		}
	}
}