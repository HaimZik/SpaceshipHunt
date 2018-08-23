package spaceshiptHunt.utils
{
	import flash.geom.Point;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.utils.Pool;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class BillboardNode
	{
		
		public var parent:DisplayObject;
		public var child:DisplayObject;
		protected var _x:Number = 0;
		protected var _y:Number = 0;
		
		public function BillboardNode(transformParent:DisplayObject, child:DisplayObject)
		{
			parent = transformParent;
			this.child = child;
		}
		
		public function update():void
		{
			//var newCords:Point = parent.localToGlobal(Pool.getPoint(_x, _y));
			//child.x =  newCords.x;
			//child.y = newCords.y;
			//	child.transformationMatrix.copyFrom(parent.transformationMatrix);
			//	child.transformationMatrix.
			child.x = parent.x + Math.cos(-child.parent.rotation) * _x - Math.sin(-child.parent.rotation) * _y;
			child.y = parent.y + Math.sin(-child.parent.rotation) * _x + Math.cos(-child.parent.rotation) * _y;
			child.rotation = -child.parent.rotation;
			//	trace(child.parent.rotation);
		}
		
		public function get x():Number
		{
			return _x;
		}
		
		public function set x(value:Number):void
		{
			_x = value;
		}
		
		public function get y():Number
		{
			return _y;
		}
		
		public function set y(value:Number):void
		{
			_y = value;
		}
		
		public function get scaleX():Number
		{
			return child.scaleX;
		}
		
		public function set scaleX(value:Number):void
		{
			child.scaleX = value;
		}
		
		public function get scaleY():Number
		{
			return child.scaleY;
		}
		
		public function set scaleY(value:Number):void
		{
			child.scaleY = value;
		}
		
		public function get scale():Number
		{
			return child.scale;
		}
		
		public function set scale(value:Number):void
		{
			child.scale = value;
		}
	
	}

}