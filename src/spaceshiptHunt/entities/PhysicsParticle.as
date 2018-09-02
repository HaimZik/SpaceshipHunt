package spaceshiptHunt.entities
{
	import nape.callbacks.*;
	import nape.geom.*;
	import nape.shape.*;
	import nape.phys.BodyType;
	import spaceshiptHunt.level.*;
	import starling.core.*;
	import starling.display.*;
	import starling.textures.*;
	import starling.utils.Color;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class PhysicsParticle extends BodyInfo
	{
		
		internal static var particlePool:Vector.<PhysicsParticle> = new Vector.<PhysicsParticle>();
		protected static const poolGrowth:int = 10;
		protected var currentCallId:uint;
		public static const INTERACTION_TYPE:CbType = new CbType();
		public static var impactForce:Number = 100.0;
		
		//	protected var 
		
		//	public static const fill:BlurFilter = new BlurFilter(2,2);
		
		public function PhysicsParticle(particleTexture:Texture, position:Vec2 = null)
		{
			super(position);
			body.isBullet = true;
			body.type = BodyType.KINEMATIC;
			graphics = new Image(particleTexture);
			graphics.pivotX = graphics.width / 2;
			graphics.pivotY = graphics.height / 2;
			body.cbTypes.add(PhysicsParticle.INTERACTION_TYPE);
			body.allowRotation = false;
			//	graphics.filter = fill;
			//var material:Material = Material.ice().copy();
			//material.staticFriction = 0;
			//material.dynamicFriction = 0;
			//material.
			//trace(material.dynamicFriction);
			//body.setShapeMaterials(material);
		}
		
		public function get color():uint 
		{
			return (graphics as Image).color;
		}
		
		public function set color(value:uint):void 
		{
			(graphics as Image).color = value;
		}
		
		public static function spawn(particleType:String, position:Vec2, impulse:Vec2, color:uint = Color.WHITE):void
		{
			if (particlePool.length == 0)
			{
				var particleTexture:Texture = Environment.current.assetsLoader.getTexture(particleType);
				var circleShape:Circle = new Circle(particleTexture.width / 2);
				circleShape.sensorEnabled = true;
				for (var i:int = 0; i < poolGrowth; i++)
				{
					particlePool.push(new PhysicsParticle(particleTexture));
					circleShape.filter.collisionMask = ~2; //in order for the raytracing to ignore it
					particlePool[i].body.shapes.add(circleShape.copy());
					particlePool[i].body.mass /= 3;
				}
			}
			var particle:PhysicsParticle = particlePool.pop();
			particle.color = color;
			particle.body.position.set(position);
			particle.body.rotation = impulse.angle;
			particle.body.velocity = impulse;
			particle.body.space = Environment.current.physicsSpace;
			Game.underSpaceshipsLayer.addChild(particle.graphics);
			particle.syncGraphics();
			BodyInfo.list.push(particle);
			particle.currentCallId = Starling.juggler.delayCall(particle.despawn, 5);
		}
		
		public function despawn():void
		{
			if (body.space)
			{
				Starling.juggler.removeByID(currentCallId);
				graphics.removeFromParent();
				body.space = null;
				BodyInfo.list.removeAt(BodyInfo.list.indexOf(this));
				particlePool.push(this);
			}
		}
		
		override public function dispose():void
		{
			despawn();
		}
		
	}

}