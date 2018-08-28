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
	public class BillboardNode extends Transform
	{
		
		protected var _x:Number = 0;
		protected var _y:Number = 0;
		
		public function BillboardNode(transformParent:DisplayObject, child:DisplayObject)
		{
			parent = transformParent;
			this.child = child;
		}
		
		override public function update():void
		{
			//if (parent.parent != child.parent)
			//{
			var newPos:Point = Pool.getPoint(0, 0);
			parent.localToGlobal(newPos, newPos);
			newPos.offset(_x, _y);
			child.parent.globalToLocal(newPos, newPos);
			child.x = newPos.x;
			child.y = newPos.y;
			child.rotation = -child.parent.rotation;
			Pool.putPoint(newPos);
			//}
			//else
			//{
			//child.x = parent.x + Math.cos(-child.parent.rotation) * _x - Math.sin(-child.parent.rotation) * _y;
			//child.y = parent.y + Math.sin(-child.parent.rotation) * _x + Math.cos(-child.parent.rotation) * _y;
			//child.rotation = -child.parent.rotation;
			//}
		
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