﻿package com.imajuk.media
        private var video : SimpleFLVPlayer;
        
        private var videoLoadingProgressThread : Thread = new Thread();
        private var videoHeadThread : Thread = new Thread();
        private var videoPlayButtonThread : Thread = new Thread();
        private var videoSoundThread : Thread = new Thread();
        private var videoSize : VideoSize;
        private var videoPlaybackProgressThread : Thread;
        private var videoFullThread : Thread;
        {
            super();
            
            this.videoUI = videoUI;
        }
        private function setup() : void 
        private function waitInput() : void 
        }

            waitInput();
        }
            ThreadUtil.interrupt(videoSoundThread);
        }