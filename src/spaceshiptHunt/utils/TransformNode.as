package spaceshiptHunt.utils
{
	import flash.geom.Matrix;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.utils.MatrixUtil;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class TransformNode 
	{
		public var parent:DisplayObject;
		public var child:DisplayObject;
		public var transformationMatrix:Matrix;
		
		public function TransformNode(transformParent:DisplayObject,child:DisplayObject) 
		{
			parent = transformParent;
			transformationMatrix = new Matrix();
			this.child = child;
	//		child.alignPivot();
		}
		
		public function update():void
		{
		child.transformationMatrix.copyFrom(transformationMatrix);
		child.transformationMatrix.concat(parent.transformationMatrix);
		}
		
		public function get x():Number 
		{
			return transformationMatrix.tx;
		}
		
		public function set x(value:Number):void 
		{
			transformationMatrix.tx = value;
		}
		
		public function get y():Number 
		{
			return transformationMatrix.ty;
		}
		
		public function set y(value:Number):void 
		{
			transformationMatrix.ty = value;
		}
		
	}

}