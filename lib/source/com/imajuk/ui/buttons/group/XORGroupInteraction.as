﻿package com.imajuk.ui.buttons.group
        protected var oparation : ButtonOparation;
        protected var buttonToIndex:Dictionary = new Dictionary(true);

        					buttons : Array,
        					oparation:ButtonOparation
        {
            this.buttons = buttons;

            buttons.forEach(
        {
                    buttons.forEach(
                        {