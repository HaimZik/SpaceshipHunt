package spaceshiptHunt.entities
{
	import nape.geom.Vec2;
	import spaceshiptHunt.level.Environment;
	import spaceshiptHunt.entities.Spaceship;
	import starling.utils.Color;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Player extends Spaceship
	{
		
		public var maxTurningAcceleration:Number;
		private static var _current:Player = new Player(new Vec2());
		
		public function Player(position:Vec2)
		{
			//normally should be called by Player.current
			super(position);
			weaponsPlacement["fireCannon"] = Vec2.get(16, -37);
			fireColor = Color.AQUA;
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
			maxLife = 1000.0;
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
		}
		
		override protected function onDeath():void 
		{
			super.onDeath();
			Environment.current.resetLevel();
		}
		
		override public function dispose():void
		{
			super.dispose();
			body.shapes.clear();
		}
	
	}

}