package spaceshiptHunt.entities
{
	include "CompilerConfig.as";
	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import spaceshiptHunt.Game;
	import spaceshiptHunt.entities.Enemy;
	import spaceshiptHunt.level.Environment;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.utils.Color;
	import starling.utils.deg2rad;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class PreyEnemy extends Enemy
	{
		protected var pointingArrow:Image;
		protected var _playerPredictedPath:Vector.<Number>;
		protected var playerPathCheckTime:int;
		private static var _current:PreyEnemy;
		
		public function PreyEnemy(position:Vec2)
		{
			_current = this;
			super(position);
			playerPathCheckTime = -90;
			_playerPredictedPath = new Vector.<Number>();
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			pointingArrow = new Image(Environment.current.assetsLoader.getTexture("arrow"));
			Game.underSpaceshipsLayer.addChildAt(pointingArrow, 0);
		}
		
		override public function dispose():void 
		{
			super.dispose();
			pointingArrow.removeFromParent(true);
		}
		
		public override function update():void
		{
			super.update();
			if (pointingArrow.visible != !canViewPlayer)
			{
				pointingArrow.visible = !canViewPlayer;
			}
			if (canViewPlayer)
			{
				if (graphics.alpha < 1)
				{
					graphics.alpha += 0.025;
				}
				if (timeStamp - playerPathCheckTime > pathUpdateInterval)
				{
					Player.current.findPathToEntity(pathfindingAgent, _playerPredictedPath);
					playerPathCheckTime = timeStamp;
				}
			}
			else
			{
				if (graphics.alpha > 0.4)
				{
					graphics.alpha -= 0.005;
				}
				if (timeStamp - playerPathCheckTime > pathUpdateInterval)
				{
					var playerPosX:Number = Player.current.pathfindingAgent.x;
					var playerPosY:Number = Player.current.pathfindingAgent.y;
					Player.current.pathfindingAgent.x = lastSeenPlayerPos.x;
					Player.current.pathfindingAgent.y = lastSeenPlayerPos.y;
					Player.current.findPathToEntity(pathfindingAgent, _playerPredictedPath);
					Player.current.pathfindingAgent.x = playerPosX;
					Player.current.pathfindingAgent.y = playerPosY;
					playerPathCheckTime = timeStamp;
				}
			}
			updateArrow();
		}
		
		static public function get current():PreyEnemy
		{
			return _current;
		}
		
		static public function set current(value:PreyEnemy):void
		{
			_current = value;
		}
		
		public function get playerPredictedPath():Vector.<Number>
		{
			return _playerPredictedPath;
		}
		
		protected override function decideNextAction():void
		{
			if (canViewPlayer)
			{
				hide();
			}
		}
		
		public function hide(rayAngle:Number = 0):void
		{
			tempRay.origin.x = Player.current.pathfindingAgent.x;
			tempRay.origin.y = Player.current.pathfindingAgent.y;
			tempRay.direction.setxy(pathfindingAgent.x - tempRay.origin.x, pathfindingAgent.y - tempRay.origin.y);
			if (rayAngle != 0)
			{
				tempRay.direction.rotate(rayAngle);
			}
			tempRay.maxDistance = Vec2.distance(Player.current.body.position, body.position) + 2000;
			body.space.rayMultiCast(tempRay, true, PLAYER_FILTER, rayList);
			var rayEnter:RayResult;
			var rayExit:RayResult;
			var hidingSpot:Vec2;
			while (rayList.length >= 2 && nextPoint == -1)
			{
				rayList.shift().dispose();
				rayEnter = rayList.shift();
				if (rayList.length != 0)
				{
					rayExit = rayList.shift();
					if (rayExit.distance - rayEnter.distance > this.pathfindingAgent.radius)
					{
						hidingSpot = tempRay.at(rayEnter.distance + this.pathfindingAgent.radius + 10);
						goTo(hidingSpot.x, hidingSpot.y);
						hidingSpot.dispose();
					}
					rayExit.dispose();
				}
				else
				{
					hidingSpot = tempRay.at(rayEnter.distance + this.pathfindingAgent.radius + 10);
					goTo(hidingSpot.x, hidingSpot.y);
					hidingSpot.dispose();
				}
				rayEnter.dispose();
			}
			while (!rayList.empty())
			{
			  rayList.pop().dispose();
			}
			if (nextPoint == -1)
			{
				if (rayAngle == 0)
				{
					hide(deg2rad(5));
					if (nextPoint == -1)
					{
						hide(deg2rad(-5));
					}
				}
				else if (Math.abs(rayAngle) < Math.PI)
				{
					hide(-(rayAngle + rayAngle / Math.abs(rayAngle) * deg2rad(15)));
				}
				else
				{
					if (nextPoint == -1)
					{
						Environment.current.meshNeedsUpdate = true;
					}
				}
			}
		}
		
		private function updateArrow():void
		{
			var distanceVec:Vec2 = Player.current.body.position.sub(body.position, true);
			distanceVec.length /= -10;
			if (distanceVec.length > 120)
			{
				pointingArrow.x = Player.current.graphics.x + distanceVec.x;
				pointingArrow.y = Player.current.graphics.y + distanceVec.y;
				pointingArrow.rotation = distanceVec.angle + Math.PI / 2;
				pointingArrow.visible = true;
			}
			else
			{
				pointingArrow.visible = false;
			}
			distanceVec.dispose();
		}
		
		CONFIG::isDebugMode
		{
			import DDLSDebug.view.DDLSView;
			
			override public function drawDebug(canvas:DDLSView):void
			{
				super.drawDebug(canvas);
				canvas.drawPath(playerPredictedPath, false, Color.BLUE);
			}
		}
	
		//end
	}
}