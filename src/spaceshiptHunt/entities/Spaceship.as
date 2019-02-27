package spaceshiptHunt.entities
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import DDLS.ai.DDLSEntityAI;
	import flash.utils.Dictionary;
	import nape.geom.Vec2;
	import spaceshiptHunt.entities.Entity;
	import spaceshiptHunt.level.Environment;
	import spaceshiptHunt.utils.BillboardNode;
	import spaceshiptHunt.utils.MathUtilities;
	import spaceshiptHunt.utils.Transform;
	import spaceshiptHunt.utils.TransformNode;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.extensions.PDParticleSystem;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.SystemUtil;
	
	public class Spaceship extends Entity
	{
		public var maxAcceleration:Number;
		public var maxAngularAcceleration:Number;
		public var engineLocation:Vec2;
		public var armorDefance:Number = 8.0;
		public var fireColor:uint = Color.WHITE;
		[Embed(source = "JetFire.pex", mimeType = "application/octet-stream")]
		protected static const JetFireConfig:Class;
		protected var life:Number;
		protected var maxLife:Number = 150;
		protected var lifebarTransform:BillboardNode;
		protected var attachedTransforms:Vector.<Transform>;
		protected const lifebarOffset:Number = 25;
		protected var _gunType:String;
		protected var fireType:String = "fireball";
		protected var weaponsPlacement:Dictionary;
		protected var weaponRight:TransformNode;
		protected var weaponLeft:TransformNode;
		protected var firingRate:Number = 0.1;
		protected var bulletSpeed:Number = 80.0;
		protected const rotateTowardThreshold:Number = 0.02;
		protected var maxBullets:int = 5;
		protected var bulletsLeft:int;
		protected var filledLife:Quad;
		protected var lifebarBackground:Quad;
		protected var lastReloadTime:Number;
		protected var reloadTime:Number = 2.5;
		private var shootingCallId:uint;
		
		public function Spaceship(position:Vec2)
		{
			super(position);
			bulletsLeft = maxBullets;
			weaponsPlacement = new Dictionary(true);
		}
		
		override public function init(bodyDescription:Object):void
		{
			life = maxLife;
			super.init(bodyDescription);
			filledLife = new Quad(80, 10);
			lifebarBackground = new Quad(filledLife.width, filledLife.height);
			filledLife.color = Color.RED;
			lifebarBackground.color = Color.GRAY;
			Game.HUD.addChild(lifebarBackground);
			Game.HUD.addChild(filledLife);
			lifebarTransform = new BillboardNode(graphics, filledLife);
			attachedTransforms = new Vector.<Transform>();
			lifebarTransform.x = -filledLife.width * 0.5;
			lifebarTransform.y = -Math.max(body.bounds.width, body.bounds.height) * 0.5 - lifebarOffset;
			engineLocation = Vec2.get(bodyDescription.engineLocation.x, bodyDescription.engineLocation.y);
			maxAcceleration = body.mass * 8;
			maxAngularAcceleration = body.mass * 180;
		//	if (SystemUtil.isDesktop)
			{
				addFireParticle();
			}
		}
		
		override public function dispose():void
		{
			stopShooting();
			Environment.current.navMesh.deleteObject(pathfindingAgent.approximateObject);
			pathfindingAgent.dispose();
			lifebarBackground.removeFromParent(true);
			for (var i:int = 0; i < attachedTransforms.length; i++)
			{
				attachedTransforms[i].dispose();
			}
			lifebarTransform.dispose();
			attachedTransforms = null;
			weaponRight = weaponLeft = null;
			super.dispose();
		}
		
		override public function syncGraphics():void
		{
			super.syncGraphics();
			for (var i:int = 0; i < attachedTransforms.length; i++)
			{
				attachedTransforms[i].update();
			}
		}
		
		override public function lateSyncGraphics():void
		{
			lifebarTransform.update();
			lifebarTransform.scaleX = life / maxLife;
			lifebarBackground.rotation = filledLife.rotation;
			lifebarBackground.x = filledLife.x;
			lifebarBackground.y = filledLife.y;
		}
		
		public function set gunType(gunType:String):void
		{
			_gunType = gunType;
			var texture:Texture = Environment.current.assetsLoader.getTexture(gunType);
			if (weaponRight)
			{
				(weaponRight.child as Image).texture = texture;
				(weaponRight.child as Image).readjustSize();
				(weaponLeft.child as Image).texture = texture;
				(weaponLeft.child as Image).readjustSize();
			}
			else
			{
				weaponRight = attachDisplayObject(new Image(texture), Game.underSpaceshipsLayer);
				weaponLeft = attachDisplayObject(new Image(texture), Game.underSpaceshipsLayer);
			}
			var position:Vec2 = weaponsPlacement[gunType];
			weaponRight.x = position.x;
			weaponRight.y = position.y;
			weaponLeft.x = -position.x - weaponLeft.child.width;
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
				life = 0;
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
			if (Math.abs(angleDifference) > rotateTowardThreshold)
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
		//	trace("findPathTo Entity " + entity.approximateObject.id + " from entity " + pathfindingAgent.approximateObject.id);
			var diraction:Vec2 = Vec2.weak(entity.x - _pathfindingAgent.x, entity.y - _pathfindingAgent.y);
			diraction.length = pathfindingAgent.radius + entity.radius + pathfindingAgentSafeDistance * 2 + 2;
			findPathTo(entity.x - diraction.x, entity.y - diraction.y, outPath);
			for (var i:int = 0; i < 3; i++)
			{
				if (outPath.length == 0)
				{
					diraction.set(diraction.perp(true));
			//		trace("findPathToEntity " + i);
					findPathTo(entity.x - diraction.x, entity.y - diraction.y, outPath);
				}
				else
				{
					diraction.dispose();
		//			trace("findPathToEntity end");
					return;
				}
			}
			diraction.dispose();
			Environment.current.meshNeedsUpdate = true;
	//		trace("findPathToEntity end");
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
			if (!Environment.current.paused)
			{
				bulletsLeft -= 1;
			if (bulletsLeft == 0)
			{
				startReload();
			}
				var position:Vec2 = Vec2.get(weaponRight.x + weaponLeft.child.width / 4, weaponRight.y - 5);
				var bulletVelocity:Vec2 = Vec2.get(0, (bulletSpeed + Math.random() * bulletSpeed) * body.mass);
				bulletVelocity.angle = body.rotation - Math.PI / 2 + Math.random() * 0.1 + 0.05;
				//recoil
				body.applyImpulse(bulletVelocity.mul(-0.3, true));
				var bulletVelocityNormal:Vec2 = bulletVelocity.unit();
				bulletVelocity.length += Math.max(-bulletSpeed * 0.5, body.velocity.length * bulletVelocityNormal.dot(body.velocity.unit(true)));
				PhysicsParticle.spawn(fireType, position.copy(true).rotate(body.rotation).addeq(body.position), bulletVelocity, fireColor);
				position.x = weaponLeft.x + weaponLeft.child.width / 8;
				bulletVelocity.angle = body.rotation - Math.PI / 2 + Math.random() * 0.1 - 0.05;
				PhysicsParticle.spawn(fireType, position.rotate(body.rotation).addeq(body.position), bulletVelocity, fireColor);
				bulletVelocity.dispose();
				position.dispose();
			}
		}
		
		protected function startReload():void 
		{
			lastReloadTime = Starling.juggler.elapsedTime;
		}
		
		protected function attachDisplayObject(displayObject:DisplayObject, displayParent:DisplayObjectContainer):TransformNode
		{
			var transformNode:TransformNode = new TransformNode(graphics, displayObject);
			attachedTransforms.push(transformNode);
			displayParent.addChild(displayObject);
			return transformNode;
		}
		
		protected function addFireParticle():void
		{
			//if (!particleSystem)
			//{
			//	}
			var particleConfig:XML = XML(new JetFireConfig());
			var rightJetParticles:PDParticleSystem = new PDParticleSystem(particleConfig, Environment.current.assetsLoader.getTexture("fireball"));
			var leftJetParticles:PDParticleSystem = new PDParticleSystem(particleConfig, Environment.current.assetsLoader.getTexture("fireball"));
			rightJetParticles.batchable = true;
			leftJetParticles.batchable = true;
			var leftJetTransform:TransformNode = attachDisplayObject(leftJetParticles, Game.aboveSpaceshipsLayer);
			var rightJetTransform:TransformNode = attachDisplayObject(rightJetParticles, Game.aboveSpaceshipsLayer);
			Game.aboveSpaceshipsLayer.blendMode = leftJetParticles.blendMode;
			Starling.juggler.add(leftJetParticles);
			Starling.juggler.add(rightJetParticles);
			leftJetParticles.gravityY = 100;
			rightJetParticles.gravityY = 100;
			rightJetTransform.x = engineLocation.x;
			rightJetTransform.y = -engineLocation.y;
			leftJetTransform.x = -engineLocation.x;
			leftJetTransform.y = -engineLocation.y;
			//if (SystemUtil.isDesktop)
			//{
			rightJetParticles.start();
			leftJetParticles.start();
			//particleSystem.customFunction = bodyInfo.jetParticlePositioning;
			//		}
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