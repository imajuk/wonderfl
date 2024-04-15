﻿package com.imajuk.ui.slider
        private var bar : IUIView;
        private var draggableArea : Rectangle;

            event(slider.backGround, MouseEvent.MOUSE_DOWN, bgClicked);
        }
        
        private function startDrag(e : MouseEvent) : void
        {
        	if(isInterrupted) return;
        	interrupted(function():void{});
            
        }

        private function dragging() : void
        {
        	if(isInterrupted) return;
            interrupted(function():void{});
            
            event(StageReference.stage, MouseEvent.MOUSE_MOVE, mouseMove);
            event(StageReference.stage, MouseEvent.MOUSE_UP, stopDrag);

        private function mouseMove(e : MouseEvent) : void
        {
            if (e.stageY < 0)
            {
                stopDrag(null);
                return;
            }
        	var v:Number = bar.x / (draggableArea.x + draggableArea.width);
        	if (model.value != v)
        	   model.value = v;
        	   
        	dragging();
        }
        
            
            if (model.direction == UIType.HORIZONAL)