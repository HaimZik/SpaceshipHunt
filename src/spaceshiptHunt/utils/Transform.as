package spaceshiptHunt.utils
{
	import starling.display.DisplayObject;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Transform
	{
		public var parent:DisplayObject;
		public var child:DisplayObject;
		
		public function Transform(transformParent:DisplayObject,child:DisplayObject)
		{
			parent = transformParent;
			this.child = child;
		}
		
		public function update():void
		{
		
		}
		
		public function dispose():void
		{
			child.removeFromParent(true);
			child = null;
			parent = null;
		}
	
	}

}