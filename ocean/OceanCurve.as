/**
 * Copyright imajuk ( http://wonderfl.net/user/imajuk )
 * MIT License ( http://www.opensource.org/licenses/mit-license.php )
 * Downloaded from: http://wonderfl.net/c/7xwU
 */

package  
{
    import flash.display.StageScaleMode;
    import flash.display.StageQuality;
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.BlendMode;
    import flash.display.IGraphicsFill;
    import flash.display.GradientType;
    import flash.geom.Matrix;
    import flash.display.GraphicsGradientFill;
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import org.libspark.thread.EnterFrameThreadExecutor;
    import org.libspark.thread.Thread;

    /**
     * @author imajuk
     */
    public class OceanCurve extends Sprite 
    {
        public function OceanCurve()
        {
            //Wonderfl.capture_delay(21);
        		
        		Thread.initialize(new EnterFrameThreadExecutor());
        	
        		stage.quality = StageQuality.HIGH;
        		stage.scaleMode = StageScaleMode.NO_SCALE;
	        	stage.frameRate = 120;
 	       	start();
        }
        
        private function start() : void
        {
            var w : int = stage.stageWidth;
            var h : int = stage.stageHeight;

            //=================================
            // canvas
            //=================================
            var canvas : BitmapData = new BitmapData(w, h, true, 0xFFFFFFFF);
            var canvas2 : BitmapData = canvas.clone();
            
            var layer0:Shape = new Shape();
            
            var layer1 : Bitmap = new Bitmap(canvas2);
            layer1.blendMode = BlendMode.MULTIPLY;
            
            var layer2 : Bitmap = new Bitmap(canvas);
            layer2.blendMode = BlendMode.SCREEN;
            
            var layer3 : Bitmap = new Bitmap(canvas);
            layer3.blendMode = BlendMode.OVERLAY;
            
            
            addChild(layer0);
            addChild(layer1);
            addChild(layer2);
            addChild(layer3);
            
            //=================================
            // color
            //=================================
            var cl1 : int = 0x6264db;
            var cl2 : int = 0xcecee5;
            var cl3 : int = 0x32347f;
            var cl4 : int = 0x2b2edb;
            
            //=================================
            // background
            //=================================
            layer0.graphics.beginGradientFill(
                GradientType.LINEAR, 
                [0xFFFFFF, cl4], 
                [1, 1], 
                [100,255], 
                getGradMatrix(h, Math.PI * .5)
            );
            layer0.graphics.drawRect(0, 0, w, h);
            
            //=================================
            // fill
            //=================================
            var fill1 : IGraphicsFill = 
                new GraphicsGradientFill(
                    GradientType.LINEAR, 
                    [cl2, cl3], 
                    [1, 1], 
                    [0,255], 
                    getGradMatrix(h, Math.PI * .5)
                );
            var fill2 : IGraphicsFill = 
                new GraphicsGradientFill(
                    GradientType.LINEAR, 
                    [0xFFFFFF, cl1], 
                    [1, 1], 
                    [100,255], 
                    getGradMatrix2(h, Math.PI * .5)
                );
            var fill3 : IGraphicsFill = 
                new GraphicsGradientFill(
                    GradientType.LINEAR, 
                    [0xFFFFFF, cl1], 
                    [1, 1], 
                    [0,255], 
                    getGradMatrix(h, -Math.PI * .5)
                );
            
            //=================================
            // waves
            //=================================
            var wave1 : Wave = new Wave(w+50, h, null, fill1, 450, 38);
            var wave2 : Wave = new Wave(w+50, h, null, fill2, 450, 30);
            var wave3 : Wave = new Wave(w+50, h, null, fill3, 400, 50, WaveType.COS);
            wave2.opposite = true;
            wave2.rotation = 2;
            wave1.y = wave2.y = wave3.y = 340;
            
            //=================================
            // wave updater
            //=================================
            new WaveUpdateThread(wave1, Math.PI * .5, .02, .03, 100, 0, 1).start();
            new WaveUpdateThread(wave2, Math.PI,      .02, .03, 30, 0, 2).start();
            new WaveUpdateThread(wave3, -Math.PI,     .02, .05, 50, 0, .5).start();
            
            //=================================
            // draw waves in canvas
            //=================================
            new WaveRenderThread(Vector.<Wave>([wave3, wave1, wave2]), canvas, canvas2).start();
        };

        private function getGradMatrix(length : int, angle : Number) : Matrix 
        {
            var gradMatrix : Matrix = new Matrix();
            gradMatrix.createGradientBox(length, length, angle, 0, 0);
            return gradMatrix;
        }

        private function getGradMatrix2(length : int, angle : Number) : Matrix 
        {
            var gradMatrix : Matrix = new Matrix();
            gradMatrix.createGradientBox(length, length, angle, 0, -length);
            return gradMatrix;
        }
    }
}

class WaveType 
{
    public static const SIN:String = "SIN";
    public static const COS:String = "COS";
}

import flash.display.IGraphicsFill;
import flash.display.GraphicsPathCommand;
import flash.display.GraphicsPath;
import flash.display.GraphicsStroke;
import flash.display.IGraphicsData;
import flash.display.Graphics;
import flash.display.Shape;

class Wave extends Shape
{
    public var curveWidth:Number;
    public var curveHeight:Number;
    public var opposite:Boolean = false;
    private var stroke:GraphicsStroke;
    private var canvasWidth:Number;
    private var fill:IGraphicsFill;
    private var canvasHeight:int;
    private var curve:Function;

    /**
     * @param canvasWidth   キャンバスの横幅
     * @param canvasHeight  キャンバスの縦幅
     * @param stroke        波のスタイル（ストローク）
     * @param fill          波のスタイル（塗り）
     * @param curveWidth    波の最大幅
     * @param curveHeight   波の最大高
     * @param type          波のタイプ（WaveType.SIN or WaveType.COS）
     */
    public function Wave(
                        canvasWidth:int, 
                        canvasHeight:int, 
                        stroke:GraphicsStroke, 
                        fill:IGraphicsFill, 
                        curveWidth:Number,
                        curveHeight:Number,
                        type:String = WaveType.SIN
                        ) 
    {
        this.stroke = stroke;
        this.fill = fill;
        this.canvasWidth = canvasWidth;
        this.canvasHeight = canvasHeight;
        this.curveWidth = curveWidth;
        this.curveHeight = curveHeight;
        this.curve = (type == WaveType.COS) ? Math.cos : Math.sin;
    }

    public function draw(seed:Number, sx:Number, sy:Number):void 
    {
        //波の縦サイズ(-curveHeight ~ +curveHeight)
        var waveHeight:Number = Math.sin(seed) * curveHeight;
            
        var g:Graphics = graphics;
        g.clear();
        g.drawGraphicsData(Vector.<IGraphicsData>([ stroke, fill, getPath(sx, sy, curveWidth, waveHeight, seed) ]));
    }

    /**
     * @param px    描画のスタート位置
     * @param py    描画のスタート位置
     * @param w     波の最大横幅
     * @param h     波の最大縦幅
     * @param seed  上下の触れ幅（-Math.PI ~ Math.PI）
     */
    private function getPath(px:Number, py:Number, w:Number, h:Number, seed:Number):GraphicsPath
    {
        if (w <= 0) throw new Error("サイズが負の数値です");
            
        var path:GraphicsPath = new GraphicsPath();
        path.commands = Vector.<int>([ GraphicsPathCommand.MOVE_TO ]);
        path.data = Vector.<Number>([ px, py += Math.sin(seed) * h * .5 ]);
            
        //波一つ分をどのくらいの精度で描画するか（数値が大きいほど解像度が高い）
        var resolution:int = 30;
        var step:Number = 1 / resolution;
        var stepRad:Number = Math.PI * 2 / resolution;
            
        h *= .5;
            
        while(px < canvasWidth)
        {   
            seed += stepRad;
            px += w * step;
            py += curve(seed) * h * stepRad;
            path.commands.push(GraphicsPathCommand.LINE_TO);
            path.data.push(px, py);
        }
            
        path.commands.push(GraphicsPathCommand.LINE_TO);
        path.data.push(px, py += (opposite) ? -canvasHeight : canvasHeight);
        path.commands.push(GraphicsPathCommand.LINE_TO);
        path.data.push(0, py);
            
        return path;
    }
}

import fl.motion.easing.Quadratic;

import org.libspark.thread.Thread;

class WaveUpdateThread extends Thread 
{
    private var wave:Wave;
    private var time:Number = 0;
    private var seed:Number;
    private var easings:Array = [ Quadratic.easeOut, Quadratic.easeIn ];
    private var easing:Function = easings[0];
    private var step:Number;
    private var direction:int = 1;
    private var begin:Number;
    private var end:Number;
    private var speedH:Number;
    private var stX:Number = 0;

    /**
     * @param wave      ターゲットになるウェーブ
     * @param seed      ウェーブの初期値（-Math.PI ~ Math.PI）
     * @param minSpeed  縦揺れの最低スピード
     * @param maxSpeed  縦揺れの最高スピード
     * @param duration  縦揺れのスピードが変化する時間
     * @param time      縦揺れスピードの初期値（0 ~ 1）
     * @param speedH    横移動のスピード
     */
    public function WaveUpdateThread(
                            wave:Wave, 
                            seed:Number = NaN, 
                            minSpeed:Number = .01, 
                            maxSpeed:Number = .03, 
                            duration:int = 300, 
                            time:Number = NaN, 
                            speedH:Number = 1
                        )
    {
        super();
        this.wave = wave;
        this.begin = minSpeed; 
        this.end = maxSpeed - minSpeed;
        this.seed = isNaN(seed) ? Math.random() * Math.PI * 2 - Math.PI : seed;
        this.time = isNaN(time) ? Math.random() : time;
        this.step = 1 / duration;
        this.speedH = speedH;
    }

    override protected function run():void
    {
        next(run);
            
        time += step * direction;
        seed += easing(time, begin, end, 1);
        if (time > 1) 
        {
            time = 1;
            direction *= -1;
            easing = easings[1];
        }
        else if(time < 0)
        {
            time = 0;
            direction *= -1;
            easing = easings[1];
        }
            
        //スタートの描画位置(x=0, y=+-10)
        stX -= speedH % wave.curveWidth;
        var sx:Number = stX;
        var sy:Number = Math.cos(seed) * 10;
            
        wave.draw(seed, sx, sy);
    }
}

import flash.geom.Rectangle;
import flash.filters.BlurFilter;
import flash.geom.Point;
import flash.geom.ColorTransform;
import flash.display.BitmapData;

class WaveRenderThread extends Thread 
{
    private static const POINT:Point = new Point();
    private var waves:Vector.<Wave>;
    private var canvas:BitmapData;
    private var delay:BitmapData;
    private var transparent:ColorTransform;
    private var histroy:Vector.<BitmapData> = new Vector.<BitmapData>();
    private var blur:BlurFilter = new BlurFilter(2, 2);
    private var clear:BitmapData;
    private var rect:Rectangle;

    public function WaveRenderThread(waves:Vector.<Wave>, canvas:BitmapData, delay:BitmapData)
    {
        super();
        this.waves = waves;
        this.canvas = canvas;
        this.delay = delay;
            
        rect = canvas.rect; 
        clear = new BitmapData(canvas.width, canvas.height, true, 0x00FFFFFF);
        transparent = new ColorTransform(1, 1, 1, .5, 0, 0, 0, 0);
        histroy.push(canvas.clone());
    }

    override protected function run():void
    {
        next(run);
            
        canvas.lock();
        canvas.copyPixels(clear, rect, POINT);
        waves.forEach(function(wave:Wave, ...param):void
        {
            canvas.draw(wave, wave.transform.matrix, transparent);
        });
        canvas.unlock();
            
        delay.lock();
        delay.copyPixels(clear, rect, POINT);
        delay.draw(histroy[0]);
        delay.unlock();
                
        if (histroy.length > 5) histroy.shift().dispose();
                    
        var b:BitmapData = canvas.clone(); 
        b.applyFilter(b, b.rect, POINT, blur);
        histroy.push(b);
    }
}