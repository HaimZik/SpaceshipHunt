package spaceshiptHunt.entities
{
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.utils.MathUtil;
	
	public class BodyInfo
	{
		public static var list:Vector.<BodyInfo> = new Vector.<BodyInfo>();
		public var body:Body;
		public var graphics:DisplayObject;
		public var infoFileName:String;
		
		public function BodyInfo(position:Vec2)
		{
			body = new Body(BodyType.DYNAMIC, position);
			body.userData.info = this;
		}
		
		public function dispose():void
		{
			body.space = null;
			body.userData.info = null;
			graphics.removeFromParent(true);
			BodyInfo.list.removeAt(BodyInfo.list.indexOf(this));
		}
		
		public function syncGraphics():void
		{
			graphics.rotation = body.rotation;
			//if (!MathUtil.isEquivalent(body.position.x, graphics.x,0.075))
			//{
			graphics.x = body.position.x;
			//}
			//if (!MathUtil.isEquivalent(body.position.y, graphics.y,0.075))
			//{
			graphics.y = body.position.y;
			//	}
		}
		
		public function lateSyncGraphics():void
		{
		
		}
		
		public function init(bodyDescription:Object):void
		{
			body.userData.info = this;
		}
		
		public function update():void
		{
			if (!body.isSleeping)
			{
				syncGraphics();
			}
		}
		
		protected function get timeStamp():int
		{
			return body.space.timeStamp;
		}
	
	}
}