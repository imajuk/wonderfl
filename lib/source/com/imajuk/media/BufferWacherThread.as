﻿package com.imajuk.media
{
    import org.libspark.thread.Thread;
        private var video : SimpleFLVPlayer;
        private var isBuffering : Boolean;

        public function BufferWacherThread(video : SimpleFLVPlayer, alert:IBufferingAlert)
            super();
            
            this.video = video;
            this.alert = alert;
            	isBuffering = true;
                
                alert.alertBuffering(l, t, per);
            }
            	if (isBuffering)
            	   alert.invisibleBufferingAlert();
            	   
            	isBuffering = false;
        }