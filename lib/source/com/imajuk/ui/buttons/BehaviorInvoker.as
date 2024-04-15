﻿package com.imajuk.ui.buttons{    import com.imajuk.behaviors.BehaviorConfrict;    import com.imajuk.behaviors.BehaviorDetail;    import com.imajuk.behaviors.IButtonBehavior;    import com.imajuk.ui.buttons.fluent.BehaviorContext;    import flash.media.Sound;    import flash.utils.getQualifiedClassName;    import org.libspark.betweenas3.tweens.ITween;    /**     * ビヘイビア実行オブジェクト.     *      * BehaviorInvokerは、ひとつまたは複数のIButtonBehaviorを保持し     * ボタンの振る舞いをIButtonBehaviorに移譲します.     * BehaviorInvokerはAbstractButtonが生成し、クライアントが直接インスタンス化してはいけません.     *      * @author shin.yamaharu     */    internal class BehaviorInvoker     {        //TODO Down/UPコンテクストにglobalClickSound        internal static var globalClickSound : Sound;        internal static var globalOverSound : Sound;                internal var lock : Boolean;                private var button : AbstractButton;        private var _touchBehaviors      : Array = [];        private var _clickBehaviors      : Array = [];        private var _disableBehaviors    : Array = [];        private var _selectableBehaviors : Array = [];
        private var threads : Array;
        public function BehaviorInvoker(button : AbstractButton)        {            if (!button) throw new Error("a button is needed but null.");                        this.button = button;        }                public function toString() : String        {            return "ButtonControler[" + button.id + "]";        }                //--------------------------------------------------------------------------
        //  internal API
        //--------------------------------------------------------------------------        button_internal var behaviorDetail : BehaviorDetail = new BehaviorDetail();                button_internal function applyBehaviorToContext(behavior : IButtonBehavior, contextType : String) : void        {            switch(contextType)            {                case BehaviorContext.ROLL_OVER_OUT:                    button_internal::addTouchBehavior(behavior);                    break;                case BehaviorContext.DOWN_UP:                    button_internal::addClickBehavior(behavior);                    break;                case BehaviorContext.SELECT_UNSELECT:                    button_internal::addSelectableBehavior(behavior);                    break;                case BehaviorContext.ENABLE_DISABLE:                    button_internal::addDisableBehavior(behavior);                    break;                default:                    throw new Error("unrecognize context.");            }        }                button_internal function applySoundToContext(sound : Sound, contextType : String) : void        {            switch(contextType)            {                case BehaviorContext.ROLL_OVER_OUT:                    applySound(_touchBehaviors, sound);                    break;                case BehaviorContext.DOWN_UP:                    applySound(_clickBehaviors, sound);                    break;                case BehaviorContext.SELECT_UNSELECT:                    applySound(_selectableBehaviors, sound);                    break;                case BehaviorContext.ENABLE_DISABLE:                    applySound(_disableBehaviors, sound);                    break;                default:                    throw new Error("unrecognize context.");            }        }                button_internal function addTouchBehavior(behavior : IButtonBehavior) : void        {            _touchBehaviors.push(behavior);        }                button_internal function addClickBehavior(behavior : IButtonBehavior) : void        {            _clickBehaviors.push(behavior);        }                button_internal function addSelectableBehavior(behavior : IButtonBehavior) : void        {            _selectableBehaviors.push(behavior);        }                button_internal function addDisableBehavior(behavior : IButtonBehavior) : void        {            _disableBehaviors.push(behavior);        }                button_internal function removeBehaviorAll() : void        {            stopBehaviors();                        disposeBehaviors(_touchBehaviors);            _touchBehaviors = [];            disposeBehaviors(_clickBehaviors);            _clickBehaviors = [];                        disposeBehaviors(_selectableBehaviors);            _selectableBehaviors = [];                        disposeBehaviors(_disableBehaviors);            _disableBehaviors = [];        }                button_internal function checkConfrict() : void        {            BehaviorConfrict.validate(_touchBehaviors, BehaviorContext.ROLL_OVER_OUT);        }        button_internal function getBehavior(context : String) : Array        {            switch(context)            {                case BehaviorContext.ROLL_OVER_OUT:                    return _touchBehaviors;                    break;                case BehaviorContext.DOWN_UP:                    return _clickBehaviors;                    break;                case BehaviorContext.SELECT_UNSELECT:                    return _selectableBehaviors;                    break;                case BehaviorContext.ENABLE_DISABLE:                    return _disableBehaviors;                    break;            }            return null;        }        //--------------------------------------------------------------------------
        //  behaviors
        //--------------------------------------------------------------------------        internal function behaveSelected() : void         {            if (lock) return;                        playSound(_selectableBehaviors);                    	if (_selectableBehaviors.length > 0)        	{                var task:Array =                    _selectableBehaviors.map(                        function(ib : IButtonBehavior, ...param):ITween                        {                            return ib.selectedBehavior(button_internal::behaviorDetail);                        }                    );                                //選択ビヘイビアとロールアウトビヘイビアが同一タイプでなければ                //選択ビヘイビアの後にロールアウトビヘイビアを実行する                var task2 : Array = substructBehaviors(_touchBehaviors, _selectableBehaviors);                task2 = task2.map(function(ib : IButtonBehavior, ...param) : ITween                {                    return ib.rollOutBehavior(button_internal::behaviorDetail);                });                                startBehavior(task.concat(task2));   
        	}            else                trace("WARNIG : 選択状態のベヘイビアが定義されていません.");        }                internal function behaveUnSelected() : void         {            if (lock) return;                    	if (_selectableBehaviors)
                startBehavior(                    _selectableBehaviors.map(                        function(ib : IButtonBehavior, ...param):ITween
                        {
                            return ib.unSelectedBehavior(button_internal::behaviorDetail);
                        }                    )                );        }
        internal function behaveEnable() : void         {            if (lock) return;                        playSound(_disableBehaviors);                    	startBehavior(        	   _disableBehaviors.map(                    function(b : IButtonBehavior, ...param):ITween                    {                        return b.enableBehavior(button_internal::behaviorDetail);                    }                )            );
        }
        internal function behaveDisable() : void         {            if (lock) return;                        if (_disableBehaviors.length == 0)                return;                        	startBehavior(            	_disableBehaviors.map(                    function(b : IButtonBehavior, ...param):ITween                    {                        return b.disableBehavior(button_internal::behaviorDetail);                    }                 )            );
        }
        internal function behaveRollOver(forceExec:Boolean = false) : void         {            if (lock) return;                        if (_touchBehaviors.length == 0)                return;                            if (!forceExec && !button.mouseEnabled)                return;                            playSound(_touchBehaviors, globalOverSound);                    	//=================================            // ロールオーバビヘイビアが発動する条件            // mouseEnabledがtrueであること            // selectableBehaviorとコンフリクトしていないこと            //=================================            //もし選択可能ボタンかつ選択中であれば、選択ビヘイビアとコンフリクトするロールオーバビヘイビアを除外する            var a : Array = _touchBehaviors;            if (!forceExec && button.selectable && button.selected)               a = a.filter(                        function(b : IButtonBehavior, ...param):Boolean                        {                            var c:String = getQualifiedClassName(b);                            return !_selectableBehaviors.some(                                       function(b2 : IButtonBehavior, ...param) : Boolean                                        {                                            return c == getQualifiedClassName(b2);                                        }                                    );                        }                    );                                    	       startBehavior(                    a.map(                        function(label : IButtonBehavior, ...param):ITween                        {                            return label.rollOverBehavior(button_internal::behaviorDetail);                        })                );        }
        internal function behaveRollOut(forceExec:Boolean = false) : void         {            if (lock) return;                    	if (!forceExec && !button.mouseEnabled)                return;                        	//=================================        	// ロールアウトビヘイビアが発動する条件        	// mouseEnabledがtrueであること        	// selectableBehaviorとコンフリクトしていないこと        	//=================================        	//もし選択可能ボタンかつ選択中であれば、選択ビヘイビアとコンフリクトするロールアウトビヘイビアを除外する
            var a : Array = _touchBehaviors;            if (!forceExec && button.selectable && button.selected)        	   a = a.filter(                        function(b : IButtonBehavior, ...param):Boolean                        {                            var c:String = getQualifiedClassName(b);                            return !_selectableBehaviors.some(                                       function(b2 : IButtonBehavior, ...param) : Boolean                                        {                                            return c == getQualifiedClassName(b2);                                        }                                    );                        }                    );    	   startBehavior(                a.map(                    function(b : IButtonBehavior, ...param):ITween                    {                        return b.rollOutBehavior(button_internal::behaviorDetail);                    })            );        }                internal function behaveDown() : void         {            if (lock) return;                        playSound(_clickBehaviors, globalClickSound);                        if (_clickBehaviors.length == 0)                return;                            if (!button.mouseEnabled)                return;                            //=================================            // ロールオーバビヘイビアが発動する条件            // mouseEnabledがtrueであること            // selectableBehaviorとコンフリクトしていないこと            //=================================            var a : Array = _clickBehaviors;            //もし選択可能ボタンかつ選択中であれば、選択ビヘイビアとコンフリクトするロールオーバビヘイビアを除外する            if (button.selectable && button.selected)               a = a.filter(                        function(b : IButtonBehavior, ...param):Boolean                        {                            var c:String = getQualifiedClassName(b);                            return !_selectableBehaviors.some(                                       function(b2 : IButtonBehavior, ...param) : Boolean                                        {                                            return c == getQualifiedClassName(b2) && b.target == b2.target;                                        }                                    );                        }                    );                                               startBehavior(                    a.map(                        function(label : IButtonBehavior, ...param):ITween                        {                            return label.downBehavior(button_internal::behaviorDetail);                        })                );        }                internal function behaveUp() : void         {            if (lock) return;                        if (!button.mouseEnabled)                return;                            //=================================            // ロールアウトビヘイビアが発動する条件            // mouseEnabledがtrueであること            // selectableBehaviorとコンフリクトしていないこと            //=================================            //もし選択可能ボタンかつ選択中であれば、選択ビヘイビアとコンフリクトするロールアウトビヘイビアを除外する            var a : Array = _clickBehaviors;            if (button.selectable && button.selected)               a = a.filter(                        function(b : IButtonBehavior, ...param):Boolean                        {                            var c:String = getQualifiedClassName(b);                            return !_selectableBehaviors.some(                                       function(b2 : IButtonBehavior, ...param) : Boolean                                        {                                            return c == getQualifiedClassName(b2) && b.target == b2.target;                                        }                                    );                        }                    );                               startBehavior(                a.map(                    function(b : IButtonBehavior, ...param):ITween                    {                        return b.upBehavior(button_internal::behaviorDetail);                    })            );        }                //--------------------------------------------------------------------------
        //  privates
        //--------------------------------------------------------------------------
        private function startBehavior(behavior : Array) : void         {        	if (!behavior || behavior.length == 0)        	   return;        	//            stopBehaviors();                        threads = behavior;            threads.forEach(function(t:ITween, ...param) : void            {                t.play();            });        }                private function stopBehaviors() : void        {            if (threads)                threads.forEach(function(t:ITween, ...param):void                {                    if (t)                       t.stop();                });            threads = null;        }        private function disposeBehaviors(behaviors : Array) : void        {            behaviors.forEach(function(b:IButtonBehavior, ...param) : void            {                b.dispose();            });        }                /**         * behaviors1に含まれるIButtonBehaviorのうち、         * behaviors2に含まれるIButtonBehaviorと重複しないIButtonBehaviorを返す         */        private static function substructBehaviors(behaviors1 : Array, behaviors2 : Array) : Array        {            return behaviors1.filter(function(b:IButtonBehavior, ...param) : Boolean            {                return !behaviors2.some(function(b2:IButtonBehavior, ...param) : Boolean                {                    return getQualifiedClassName(b) == getQualifiedClassName(b2);                });            });        }                private function applySound(behaviors : Array, sound:Sound) : void        {            if (behaviors)                behaviors.forEach(function(b:IButtonBehavior, ...param) : void                {                    b.sound = sound;                });        }                private function playSound(behaviors : Array, grobalSound:Sound = null) : void        {            //global sound has priority over behavior's sound            if (grobalSound)            {                grobalSound.play();                return;            }                            if (!behaviors)                return;                            var snd:Sound;            if(behaviors.some(function(b:IButtonBehavior, ...param) : Boolean            {                snd = b.sound;                return b.sound != null;            })) snd.play();        }    }}