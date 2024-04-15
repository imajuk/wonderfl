﻿package com.imajuk.geom 
{
	/**
	 * @author yamaharu
	 */
	public interface IGeom
	{
		function get x () : Number;
		function get width () : Number;
		function get height () : Number;
		function set width (value : Number) : void;
		function set height (value : Number) : void;
		function clone () : IGeom;
		function equals (geom : IGeom) : Boolean;
		function containsPoint (point : Point2D, includeOnLine : Boolean = true) : Boolean;
	}
}