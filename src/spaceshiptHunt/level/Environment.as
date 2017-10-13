package spaceshiptHunt.level
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import DDLS.ai.DDLSEntityAI;
	import DDLS.ai.DDLSPathFinder;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSObject;
	import DDLS.data.HitTestable;
	import DDLS.factories.DDLSRectMeshFactory;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.system.TouchscreenType;
	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.dynamics.InteractionFilter;
	import nape.geom.Ray;
	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import nape.geom.Vec2List;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.space.Space;
	import spaceshiptHunt.entities.*;
	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.PDParticleSystem;
	import starling.extensions.lighting.LightSource;
	import starling.extensions.lighting.LightStyle;
	import starling.geom.Polygon;
	import starling.rendering.VertexData;
	import starling.textures.Texture;
	import starling.utils.AssetManager;
	import starling.utils.Pool;
	import starling.utils.SystemUtil;
	
	public class Environment implements HitTestable
	{
		public var mainDisplay:Sprite;
		public var meshNeedsUpdate:Boolean = true;
		public var assetsLoader:AssetManager;
		public var navMesh:DDLSMesh;
		public var physicsSpace:Space;
		
		public var light:LightSource;
		public var currentLevelName:String;
		static private var currentEnvironment:Environment;
		protected var pathfinder:DDLSPathFinder;
		protected var lastNavMeshUpdate:Number;
		protected var commandQueue:Vector.<Function>;
		protected var navBody:DDLSObject;
		protected var particleSystem:PDParticleSystem;
		protected static const STATIC_OBSTACLES_FILTER:InteractionFilter = new InteractionFilter(2, ~8);
		private var rayHelper:Ray;
		
		[Embed(source = "JetFire.pex", mimeType = "application/octet-stream")]
		protected static const JetFireConfig:Class;
		
		protected var asteroidField:Sprite;
		protected var staticMeshRelativePath:String;
		
		public function Environment(mainSprite:Sprite)
		{
			staticMeshRelativePath = "physicsBodies/";
			currentEnvironment = this;
			mainDisplay = mainSprite;
			physicsSpace = new Space(new Vec2(0, 0));
			physicsSpace.worldAngularDrag = 3.0;
			physicsSpace.worldLinearDrag = 2;
			assetsLoader = new AssetManager();
			if (SystemUtil.isDesktop)
			{
				assetsLoader.numConnections = 50;
			}
			commandQueue = new Vector.<Function>();
			navMesh = DDLSRectMeshFactory.buildRectangle(10000, 10000);
			navBody = new DDLSObject();
			navMesh.insertObject(navBody);
			pathfinder = new DDLSPathFinder(this);
			pathfinder.mesh = navMesh;
			var bulletCollisionListener:InteractionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, CbType.ANY_BODY, PhysicsParticle.INTERACTION_TYPE, onBulletHit);
			physicsSpace.listeners.add(bulletCollisionListener);
			light = new LightSource();
			light.z = -800;
			light.brightness = 0.8;
			if (Capabilities.touchscreenType != TouchscreenType.NONE)
			{
				light.brightness -= 0.4;
			}
			light.ambientBrightness = 0.1;
			//light.showLightBulb = true;
			lastNavMeshUpdate = Starling.juggler.elapsedTime;
			rayHelper = Ray.fromSegment(Vec2.get(), Vec2.get());
		}
		
		public static function get current():Environment
		{
			return currentEnvironment;
		}
		
		public function update(passedTime:Number):void
		{
			physicsSpace.step(passedTime);
			if (Player.current)
			{
				light.x = Player.current.graphics.x;
				light.y = Player.current.graphics.y + 400;
				var length:int = BodyInfo.list.length;
				for (var i:int = 0; i < length; i++)
				{
					BodyInfo.list[i].update();
				}
			}
			if (meshNeedsUpdate && Starling.juggler.elapsedTime - lastNavMeshUpdate > 1.0)
			{
				navMesh.updateObjects();
				lastNavMeshUpdate = Starling.juggler.elapsedTime;
				meshNeedsUpdate = false;
			}
		}
		
		public function enqueueLevel(levelName:String, onFinish:Function = null):void
		{
			disposeLevel();
			var level:Object = JSON.parse(new LevelInfo[levelName](), function(k, v):Object
			{
				if (isNaN(Number(k)) && !(v is Array))
				{
					if (currentLevelName != levelName || k.indexOf("static") == -1)
					{
						enqueueBody(k, v);
					}
				}
				return v;
			});
			//for (var entitieType:String in level)
			//{
			//enqueueBody(entitieType, level[entitieType]);
			//}
			currentLevelName = levelName;
			assetsLoader.loadQueue(function onProgress(ratio:Number):void
			{
				if (ratio == 1.0)
				{
					var length:int = commandQueue.length;
					for (var i:int = 0; i < length; i++)
					{
						(commandQueue.shift())();
					}
					if (onFinish)
					{
						onFinish();
					}
					navMesh.updateObjects();
				}
			})
		}
		
		public function disposeLevel():void
		{
			navMesh.updateObjects();
			for (var i:int = 0; i < BodyInfo.list.length; i++)
			{
				BodyInfo.list[i].dispose();
				navMesh.updateObjects();
			}
		}
		
		public function resetLevel():void
		{
			enqueueLevel(currentLevelName);
		}
		
		public function enqueueBody(fileName:String, fileInfo:Object):void
		{
			var infoFileName:String = fileName + "Info";
			if (assetsLoader.getObject(infoFileName) == null)
			{
				assetsLoader.enqueueWithName("physicsBodies/" + fileName + "/Info.json", infoFileName);
			}
			var meshFileName:String = fileName + "Mesh";
			if (fileName.indexOf("static") != -1)
			{
				meshFileName = assetsLoader.enqueueWithName(staticMeshRelativePath + fileName + "/Mesh.json", meshFileName);
			}
			else if (assetsLoader.getObject(meshFileName) == null)
			{
				meshFileName = assetsLoader.enqueueWithName("physicsBodies/" + fileName + "/Mesh.json", meshFileName);
			}
			commandQueue.push(function onFinish():void
			{
				if (fileName.indexOf("static") != -1)
				{
					createStaticMesh(infoFileName, meshFileName);
				}
				else
				{
					var bodyDescription:Object = assetsLoader.getObject(infoFileName);
					var EntityType:Class = LevelInfo.entityTypes["spaceshiptHunt.entities::" + bodyDescription.type];
					var polygonArray:Array = assetsLoader.getObject(meshFileName) as Array;
					for (var i:int = 0; i < fileInfo.cords.length; i++)
					{
						var bodyInfo:Entity;
						if (EntityType == Player)
						{
							Player.current.body.position.setxy(fileInfo.cords[i], fileInfo.cords[++i]);
							bodyInfo = Player.current;
						}
						else
						{
							bodyInfo = new EntityType(new Vec2(fileInfo.cords[i], fileInfo.cords[++i]));
						}
						bodyInfo.infoFileName = fileName;
						for (var j:int = 0; j < polygonArray.length; j++)
						{
							addMesh(polygonArray[j], bodyInfo.body);
						}
						bodyInfo.init(bodyDescription);
						if (bodyDescription.hasOwnProperty("engineLocation"))
						{
							var spcaeship:Spaceship = bodyInfo as Spaceship;
								//addFireParticle(spcaeship);
						}
						physicsSpace.bodies.add(bodyInfo.body);
						mainDisplay.addChild(bodyInfo.graphics);
					}
				}
			});
		}
		
		protected function drawMesh(container:DisplayObjectContainer, polygon:starling.geom.Polygon, texture:Texture, normalMap:Texture = null):void
		{
			var vertexPos:VertexData = new VertexData(null, polygon.numVertices);
			polygon.copyToVertexData(vertexPos)
			var mesh:Mesh = new Mesh(vertexPos, polygon.triangulate());
			mesh.texture = texture;
			if (normalMap)
			{
				var lightStyle:LightStyle = new LightStyle(normalMap);
				lightStyle.light = light;
				mesh.style = lightStyle;
			}
			mesh.textureRepeat = true;
			applyUV(mesh);
			container.addChild(mesh);
		}
		
		protected function applyUV(mesh:Mesh):void
		{
			var vertex:Point = Pool.getPoint();
			for (var i:int = 0; i < mesh.numVertices; i++)
			{
				mesh.getVertexPosition(i, vertex);
				mesh.setTexCoords(i, (vertex.x / mesh.style.texture.width), ((vertex.y / mesh.style.texture.height)));
			}
			Pool.putPoint(vertex);
		}
		
		protected function addMesh(points:Array, body:Body):void
		{
			var vec2List:Vec2List = new Vec2List();
			var i:int = 0;
			if (body.type == BodyType.STATIC)
			{
				navBody.coordinates.push(points[0], points[1]);
				vec2List.add(Vec2.weak(points[points.length - 2], points[points.length - 1]));
				i += 2;
				for (; i < points.length; i++)
				{
					navBody.coordinates.push(points[i], points[i + 1]);
					navBody.coordinates.push(points[i], points[i + 1]);
					vec2List.add(Vec2.weak(points[points.length - i - 2], points[points.length - i - 1]));
					i++;
				}
				navBody.coordinates.push(points[0], points[1]);
				navBody.hasChanged = true;
			}
			else
			{
				for (; i < points.length; i++)
				{
					vec2List.add(Vec2.weak(points[i], points[++i]));
				}
			}
			body.shapes.add(new nape.shape.Polygon(vec2List));
			vec2List.clear();
			vec2List = null;
		}
		
		protected function addFireParticle(bodyInfo:Spaceship):void
		{
			if (SystemUtil.isDesktop)
			{
				//if (!particleSystem)
				//{
				particleSystem = new PDParticleSystem(XML(new JetFireConfig()), assetsLoader.getTexture("fireball"));
				particleSystem.batchable = true;
				(bodyInfo.graphics as DisplayObjectContainer).addChild(particleSystem);
				var particleSystem2:PDParticleSystem = new PDParticleSystem(XML(new JetFireConfig()), assetsLoader.getTexture("fireball"));
				(bodyInfo.graphics as DisplayObjectContainer).addChild(particleSystem2);
				particleSystem.start();
				particleSystem2.start();
				Starling.juggler.add(particleSystem);
				Starling.juggler.add(particleSystem2);
				particleSystem.x = bodyInfo.engineLocation.x;
				particleSystem.y = -bodyInfo.engineLocation.y;
				particleSystem.gravityY = 100;
				particleSystem2.x = -bodyInfo.engineLocation.x;
				particleSystem2.y = -bodyInfo.engineLocation.y;
				particleSystem2.gravityY = 100;
					//	}
					//particleSystem.customFunction = bodyInfo.jetParticlePositioning;
			}
		}
		
		protected function createStaticMesh(infoFileName:String, meshFileName:String):void
		{
			var bodyDescription:Object = assetsLoader.getObject(infoFileName);
			var texture:Texture = assetsLoader.getTexture(bodyDescription.textureName);
			var normalMap:Texture = assetsLoader.getTexture(bodyDescription.textureName + "_n");
			var body:Body = new Body(BodyType.STATIC);
			asteroidField = new Sprite();
			var polygonArray:Array = assetsLoader.getObject(meshFileName) as Array;
			for (var k:int = 0; k < polygonArray.length; k++)
			{
				addMesh(polygonArray[k], body);
				drawMesh(asteroidField, new starling.geom.Polygon(polygonArray[k]), texture, normalMap);
			}
			mainDisplay.addChild(asteroidField);
			physicsSpace.bodies.add(body);
		}
		
		public function findPath(pathfindingAgent:DDLSEntityAI, x:Number, y:Number, outPath:Vector.<Number>):void
		{
			pathfinder.entity = pathfindingAgent;
			pathfinder.findPath(x, y, outPath);
		}
		
		private function onBulletHit(event:InteractionCallback):void
		{
			var bulletBody:Body;
			var collidedBody:Body;
			var interactor1Entity:BodyInfo = event.int1.userData.info;
			var interactor2Entity:BodyInfo = event.int2.userData.info;
			if (interactor1Entity is PhysicsParticle)
			{
				bulletBody = event.int1.castBody;
				collidedBody = event.int2.castBody
				collidedBody.applyImpulse(bulletBody.velocity.normalise().muleq(PhysicsParticle.impactForce), bulletBody.position);
				(interactor1Entity as PhysicsParticle).despawn();
			}
			if (interactor2Entity is PhysicsParticle)
			{
				bulletBody = event.int2.castBody;
				collidedBody = event.int1.castBody;
				collidedBody.applyImpulse(bulletBody.velocity.normalise().muleq(PhysicsParticle.impactForce), bulletBody.position);
				(interactor2Entity as PhysicsParticle).despawn();
			}
			if (collidedBody.userData.info is Spaceship)
			{
				(collidedBody.userData.info as Spaceship).onBulletHit(PhysicsParticle.impactForce);
			}
		}
		
		public function hitTestLine(fromEntity:DDLSEntityAI, directionX:Number, directionY:Number):Boolean
		{
			rayHelper.origin.x = fromEntity.x;
			rayHelper.origin.y = fromEntity.y;
			rayHelper.direction.x = directionX;
			rayHelper.direction.y = directionY;
			rayHelper.maxDistance = rayHelper.direction.length;
			var rayResult:RayResult = physicsSpace.rayCast(rayHelper, false, STATIC_OBSTACLES_FILTER);
			if (rayResult)
			{
				rayResult.dispose();
				return true;
			}
			return false;
		}
		
		public function handleGameAreaTouch(e:TouchEvent):void
		{
		}
	
	}
}