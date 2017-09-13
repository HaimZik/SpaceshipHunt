package spaceshiptHunt.entities
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import DDLS.ai.DDLSEntityAI;
	import spaceshiptHunt.level.Environment;
	import spaceshiptHunt.entities.Entity;
	import spaceshiptHunt.utils.MathUtilities;
	import flash.utils.Dictionary;
	import nape.geom.Vec2;
	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.textures.Texture;
	
	public class Spaceship extends Entity
	{
		public var maxAcceleration:Number;
		public var maxAngularAcceleration:Number;
		public var engineLocation:Vec2;
		public var armorDefance:Number = 8.0;
		protected var life:Number = 150;
		protected var _gunType:String;
		protected var fireType:String = "fireball";
		protected var weaponsPlacement:Dictionary;
		protected var weaponRight:Image;
		protected var weaponLeft:Image;
		protected var firingRate:Number = 0.1;
		protected var bulletSpeed:Number = 80.0;
		protected const rotateTowardThreshold:Number = 0.1;
		private var shootingCallId:uint;
		
		public function Spaceship(position:Vec2)
		{
			super(position);
			weaponsPlacement = new Dictionary(true);
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			engineLocation = Vec2.get(bodyDescription.engineLocation.x, bodyDescription.engineLocation.y);
			maxAcceleration = body.mass * 8;
			maxAngularAcceleration = body.mass * 180;
		}
		
		protected function dispose():void
		{
			stopShooting();
			body.space = null;
			body.userData.info = null;
			body = null;
			graphics.removeFromParent(true);
			BodyInfo.list.removeAt(BodyInfo.list.indexOf(this));
			Environment.current.navMesh.deleteObject(pathfindingAgent.approximateObject);
			pathfindingAgent.dispose();
		}
		
		public function set gunType(gunType:String):void
		{
			_gunType = gunType;
			var texture:Texture = Environment.current.assetsLoader.getTexture(gunType);
			if (weaponRight)
			{
				weaponRight.texture = texture;
				weaponRight.readjustSize();
				weaponLeft.texture = texture;
				weaponLeft.readjustSize();
			}
			else
			{
				weaponRight = new Image(texture);
				weaponLeft = new Image(texture);
				(graphics as DisplayObjectContainer).addChildAt(weaponRight, 0);
				(graphics as DisplayObjectContainer).addChildAt(weaponLeft, 0);
			}
			var position:Vec2 = weaponsPlacement[gunType];
			weaponRight.x = position.x;
			weaponRight.y = position.y;
			weaponLeft.x = -position.x - weaponLeft.width;
			weaponLeft.y = position.y;
		}
		
		public function get gunType():String
		{
			return _gunType;
		}
		
		public function get lifePoints():Number
		{
			return life;
		}
		
		public function set lifePoints(value:Number):void
		{
			life = value;
			if (life <= 0)
			{
				onDeath();
			}
		}
		
		public function startShooting():void
		{
			if (!Starling.juggler.containsDelayedCalls(shootParticle))
			{
				shootingCallId = Starling.juggler.repeatCall(shootParticle, firingRate);
			}
		}
		
		public function stopShooting():void
		{
			Starling.juggler.removeByID(shootingCallId);
		}
		
		public function rotateTowards(angle:Number):void
		{
			var angleDifference:Number = MathUtilities.angleDifference(angle + Math.PI / 2, body.rotation);
		//	if (Math.abs(angleDifference) > rotateTowardThreshold)
			{
				body.applyAngularImpulse(maxAngularAcceleration * angleDifference);
			}
		}
		
		public function findPathTo(x:Number, y:Number, outPath:Vector.<Number>):void
		{
			Environment.current.findPath(pathfindingAgent, x, y, outPath);
		}
		
		public function findPathToEntity(entity:DDLSEntityAI, outPath:Vector.<Number>):void
		{
			var diraction:Vec2 = Vec2.weak(entity.x - _pathfindingAgent.x, entity.y - _pathfindingAgent.y);
			diraction.length = pathfindingAgent.radius + entity.radius + pathfindingAgentSafeDistance * 2 + 2;
			findPathTo(entity.x - diraction.x, entity.y - diraction.y, outPath);
			for (var i:int = 0; i < 3; i++)
			{
				if (outPath.length == 0)
				{
					diraction.set(diraction.perp(true));
					findPathTo(entity.x - diraction.x, entity.y - diraction.y, outPath);
				}
				else
				{
					diraction.dispose();
					return;
				}
			}
			diraction.dispose();
			Environment.current.meshNeedsUpdate = true;
		}
		
		public function onBulletHit(impactForce:Number):void
		{
			lifePoints -= impactForce / armorDefance;
		}
		
		protected function onDeath():void
		{
			dispose();
		}
		
		protected function shootParticle():void
		{
			var position:Vec2 = Vec2.get(weaponRight.x + weaponLeft.width / 2, weaponRight.y - 5);
			var recoilImpulse:Vec2 = Vec2.get(0, (bulletSpeed + Math.random() * bulletSpeed) * body.mass);
			recoilImpulse.angle = body.rotation - Math.PI / 2 + Math.random() * 0.1 + 0.05;
			PhysicsParticle.spawn(fireType, position.copy(true).rotate(body.rotation).addeq(body.position), recoilImpulse);
			position.x = weaponLeft.x + weaponLeft.width / 2;
			recoilImpulse.angle = body.rotation - Math.PI / 2 + Math.random() * 0.1 - 0.05;
			PhysicsParticle.spawn(fireType, position.rotate(body.rotation).addeq(body.position), recoilImpulse);
			body.applyImpulse(recoilImpulse.mul(-0.3));
			position.dispose();
			recoilImpulse.dispose();
		}
	
		//public function jetParticlePositioning(particles:Vector.<PDParticle>, numActive:int):void
		//{
		//var p:PDParticle;
		//var velocityLength:Number = body.velocity.length;
		//var speedL:Number = velocityLength / 10 + body.angularVel * 10;
		//for (var i:int = 0; i < numActive; i += 2)
		//{
		//p = particles[i];
		//if (p.x > -5)
		//{
		//p.x -= engineLocation.x * 2 - 5;
		//p.y -= 5;
		//if (speedL < 35)
		//{
		//if (velocityLength < 20)
		//{
		//p.alpha = 0;
		//}
		//else
		//{
		//p.velocityY += Math.abs(speedL);
		//}
		//}
		//else
		//{
		//p.tangentialAcceleration = -body.angularVel * 30;
		//p.velocityY += speedL;
		//}
		//}
		//else
		//{
		//p.alpha = 0;
		//}
		//}
		//var speedR:Number = -body.angularVel * 1.3 + velocityLength / 180;
		//for (i = 1; i < numActive; i += 2)
		//{
		//p = particles[i];
		//if (velocityLength < 50)
		//{
		//p.alpha -= 0.5;
		//}
		//else if (p.x > -5)
		//{
		////p.x += player.engineLocation.x * 2 - 5;
		//if (speedR < 2)
		//{
		//if (velocityLength < 20)
		//{
		//p.alpha = 0;
		//}
		//else
		//{
		//p.velocityY += Math.abs(speedR) / 5;
		//}
		//}
		//else
		//{
		//p.tangentialAcceleration = -body.angularVel * 25;
		//p.velocityY += speedR;
		//}
		//}
		//}
		//}
	
	}

}