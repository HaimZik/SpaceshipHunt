package spaceshiptHunt.entities
{
	import nape.geom.Vec2;
	import spaceshiptHunt.level.Environment;
	import spaceshiptHunt.entities.Spaceship;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Player extends Spaceship
	{
		
		public var impulse:Vec2;
		public var maxTurningAcceleration:Number;
		protected var skewSpeed:Number;
		private static var _current:Player = new Player(new Vec2());
		
		public function Player(position:Vec2)
		{
			//normally should be called by Player.current
			super(position);
			impulse = Vec2.get(0, 0);
			weaponsPlacement["fireCannon"] = Vec2.get(16, -37);
		}
		
		static public function get current():Player
		{
			return _current;
		}
		
		static public function set current(value:Player):void
		{
			_current=value;
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			for (var i:int = 0; i < body.shapes.length; i++)
			{
				body.shapes.at(i).filter.collisionMask = ~4;
				body.shapes.at(i).filter.collisionGroup = 8;
			}
			this.gunType = "fireCannon";
			maxTurningAcceleration = body.mass * 5;
			maxAngularAcceleration = body.mass * 220;
			maxAcceleration = body.mass * 18.0;
			life = 1500.0;
		}
		
		override public function dispose():void
		{
			super.dispose();
		}
		
		override public function update():void
		{
			super.update();
			skewSpeed = 0.2;
			graphics.skewY = graphics.skewY * (1.0 - skewSpeed) + (impulse.x * 0.4) * skewSpeed;
			if (impulse.length != 0)
			{
				body.applyImpulse(impulse.mul(maxAcceleration, true).rotate(body.rotation));
				impulse.setxy(0.0, 0.0);
			}
			//if (body.velocity.length > 500)
			//{
			//body.velocity.length = 500;
			//}			
		}
	
	}

}