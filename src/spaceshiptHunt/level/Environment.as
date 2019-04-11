package spaceshiptHunt.level
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import DDLS.ai.DDLSEntityAI;
	import DDLS.ai.PathFinder;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSObject;
	import DDLS.data.HitTestable;
	import DDLS.factories.DDLSRectMeshFactory;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.system.TouchscreenType;
	import flash.ui.Keyboard;
	import input.Key;
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
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.TouchEvent;
	import starling.extensions.lighting.LightSource;
	import starling.extensions.lighting.LightStyle;
	import starling.geom.Polygon;
	import starling.rendering.VertexData;
	import starling.textures.Texture;
	import starling.utils.AssetManager;
	import starling.utils.MathUtil;
	import starling.utils.Pool;
	import starling.utils.SystemUtil;
	
	public class Environment implements HitTestable
	{
		public var mainDisplay:Sprite;
		public var meshNeedsUpdate:Boolean = true;
		public var assetsLoader:AssetManager;
		public var navMesh:DDLSMesh;
		public var physicsSpace:Space;
		public var paused:Boolean = false;
		public var light:LightSource;
		public var currentLevelName:String;
		public var cameraPosition:Point = new Point();
		public static const STATIC_OBSTACLES_FILTER:InteractionFilter = new InteractionFilter(2, ~8);
		static private var currentEnvironment:Environment;
		protected const MAX_ZOOM_OUT:Number = 0.3;
		protected var _baseZoom:Number = 1.0;
		protected var navMeshUpdateRate:Number = 1.2;
		protected var viewDistance:Number = 1548.0;
		protected var pathfinder:PathFinder;
		protected var lastNavMeshUpdate:Number;
		protected var commandQueue:Vector.<Function>;
		protected var navBody:DDLSObject;
		protected var staticMeshRelativePath:String;
		protected var asteroidField:Sprite;
		protected var camTargetVelocity:Vec2 = new Vec2();
		protected var camAngularVelocity:Number;
		private var rayHelper:Ray;
		
		public function Environment()
		{
			staticMeshRelativePath = "physicsBodies/";
			currentEnvironment = this;
			mainDisplay = Game.spaceshipsLayer;
			physicsSpace = new Space(new Vec2(0, 0));
			physicsSpace.worldAngularDrag = 3.0;
			physicsSpace.worldLinearDrag = 2;
			assetsLoader = new AssetManager();
			if (SystemUtil.isDesktop)
			{
				assetsLoader.numConnections = 50;
			}
			commandQueue = new Vector.<Function>();
			navMesh = DDLSRectMeshFactory.buildRectangle(5000, 5000);
			navBody = new DDLSObject();
			navMesh.insertObject(navBody);
			pathfinder = new PathFinder(this);
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
			Key.addKeyUpCallback(Keyboard.R, resetLevel);
			Key.addKeyUpCallback(Keyboard.P, togglePaused);
		}
		
		public static function get current():Environment
		{
			return currentEnvironment;
		}
		
		public function get baseZoom():Number
		{
			return _baseZoom;
		}
		
		public function set baseZoom(value:Number):void
		{
			_baseZoom = MathUtil.clamp(value, 0.04, 1.0);
		}
		
		public function update(passedTime:Number):void
		{
			var didNavMeshUpdated:Boolean = false;
			if (meshNeedsUpdate && Starling.juggler.elapsedTime - lastNavMeshUpdate > navMeshUpdateRate)
			{
				navMesh.updateObjects();
				lastNavMeshUpdate = Starling.juggler.elapsedTime;
				didNavMeshUpdated = true;
			}
			if (!paused)
			{
				physicsSpace.step(passedTime);
				for (var i:int = 0; i < BodyInfo.list.length; i++)
				{
					BodyInfo.list[i].update();
				}
				light.x = Player.current.graphics.x;
				light.y = Player.current.graphics.y + 400;
				cameraPosition.x = Player.current.graphics.x;
				cameraPosition.y = Player.current.graphics.y;
				var player:Player = Player.current;
				camAngularVelocity = MathUtil.normalizeAngle(mainDisplay.rotation) - MathUtil.normalizeAngle(player.body.angularVel / 17 - player.body.rotation);
				camTargetVelocity.set(player.body.velocity).rotate(mainDisplay.rotation).muleq(0.2);
				cullAsteroidField();
			}
			focusCam();
			for (var j:int = 0; j < BodyInfo.list.length; j++)
			{
				BodyInfo.list[j].lateSyncGraphics();
			}
			if (didNavMeshUpdated)
			{
				meshNeedsUpdate = false;
			}
		}
		
		public function syncGraphics():void
		{
			for (var i:int = 0; i < BodyInfo.list.length; i++)
			{
				BodyInfo.list[i].syncGraphics();
			}
			light.x = Player.current.graphics.x;
			light.y = Player.current.graphics.y + 400;
			cameraPosition.x = Player.current.body.position.x;
			cameraPosition.y = Player.current.body.position.y;
			var camPosition:Point = Pool.getPoint(cameraPosition.x, cameraPosition.y);
			mainDisplay.localToGlobal(camPosition, camPosition);
			mainDisplay.x -= camPosition.x - mainDisplay.stage.stageWidth * 0.5;
			mainDisplay.y -= camPosition.y - mainDisplay.stage.stageHeight * 0.5;
			Pool.putPoint(camPosition);
		}
		
		protected function focusCam():void
		{
			var rotationChangeThreshold:Number = 0.002;
			var didChange:Boolean = false;
			if (!MathUtil.isEquivalent(camAngularVelocity, 0, rotationChangeThreshold))
			{
				//mainDisplay.pivotX = cameraPosition.x;
				//mainDisplay.pivotY = cameraPosition.y;
				mainDisplay.rotation -= camAngularVelocity;
				didChange = true;
			}
			var newScale:Number = baseZoom - Math.min(MAX_ZOOM_OUT * baseZoom, camTargetVelocity.length * camTargetVelocity.length / 30000);
			if (!MathUtil.isEquivalent(mainDisplay.scale, newScale, 0.01))
			{
				mainDisplay.scale += (newScale - mainDisplay.scale) / 16;
				didChange = true;
			}
			var camPosition:Point = Pool.getPoint(cameraPosition.x, cameraPosition.y);
			mainDisplay.localToGlobal(camPosition, camPosition);
			var camVelocityX:Number = camPosition.x - camTargetVelocity.x - mainDisplay.stage.stageWidth / 2;
			var camVelocityY:Number = camPosition.y - camTargetVelocity.y - mainDisplay.stage.stageHeight * 0.7;
			//camVelocityX = 0;
			//camVelocityY = 0;
			if (!(MathUtil.isEquivalent(camVelocityX, 0, 0.75) && MathUtil.isEquivalent(camVelocityY, 0, 0.75)))
			{
				var smoothness:Number = 1.0 * (Player.current.isDashing() ? 0.9 : 1);
				mainDisplay.x -= camVelocityX * smoothness;
				mainDisplay.y -= camVelocityY * smoothness;
				didChange = true;
			}
			if (didChange)
			{
				syncTransforms();
			}
			Pool.putPoint(camPosition);
		}
		
		public function togglePaused():void
		{
			if (Player.current.lifePoints > 0)
			{
				paused = !paused;
				if (paused)
				{
					camAngularVelocity = 0;
				}
			}
		}
		
		public function findPath(pathfindingAgent:DDLSEntityAI, x:Number, y:Number, outPath:Vector.<Number>):void
		{
			pathfinder.entity = pathfindingAgent;
			//	trace(pathfindingAgent.approximateObject.id);
			pathfinder.findPath(x, y, outPath);
			if (outPath.length > 2)
			{
				fixPath(outPath);
			}
		}
		
		protected function fixPath(path:Vector.<Number>, maxFix:int = 4):void
		{
			var blockedPart:int = findBlockedWay(path);
			if (blockedPart != -1)
			{
				maxFix--;
				if (maxFix == 0 || blockedPart == 0)
				{
					path.length = 0;
					return;
				}
			}
			else
			{
				return;
			}
			var offset:int = -2;
			var fromX:Number = path[blockedPart + offset];
			var fromY:Number = path[blockedPart + 1 + offset];
			var toX:Number = path[path.length - 2];
			var toY:Number = path[path.length - 1];
			var badPath:Vector.<Number> = new Vector.<Number>();
			if (maxFix == 1)
			{
				pathfinder.findPathFrom(fromX, fromY, toX, toY, badPath);
			}
			//agent.findPathTo(path[path.length - 2], path[path.length - 1], path);
			pathfinder.findPathFrom(fromX, fromY, toX, toY, badPath);
			fixPath(badPath, maxFix);
			path.length = blockedPart + badPath.length;
			for (var i:int = blockedPart - offset; i < path.length; i++)
			{
				path[i] = badPath[i - blockedPart + offset];
			}
			
			//	var refind:int = findBlockedWay(badPath);
			//	if (refind != -1)
			{
				//trace(blockedPart + " fromX:" + fromX + " fromY:" + fromY + " toX:" + toX + " toY:" + toY + " invaild " + agent.body.id);
				//	pathfinder.findPathDebug(fromX, fromY, toX, toY, badPath);
			}
		}
		
		protected function findBlockedWay(path:Vector.<Number>):int
		{
			for (var i:int = 0; i < path.length - 2; i++)
			{
				var fromX:Number = path[i];
				var fromY:Number = path[++i];
				if (hitTestLine(fromX, fromY, path[i + 1] - fromX, path[i + 2] - fromY))
				{
					return i - 1;
				}
			}
			return -1;
		}
		
		public function hitTestLine(fromX:Number, fromY:Number, directionX:Number, directionY:Number):Boolean
		{
			rayHelper.origin.x = fromX;
			rayHelper.origin.y = fromY;
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
		
		public function loadLevel(levelName:String, onFinish:Function = null):void
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
			for (var i:int = BodyInfo.list.length - 1; i >= 0; i--)
			{
				BodyInfo.list[i].dispose();
			}
			navMesh.updateObjects();
		}
		
		public function resetLevel():void
		{
			loadLevel(currentLevelName);
		}
		
		public function handleGameAreaTouch(e:TouchEvent):void
		{
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
					spawnEntity(fileName, fileInfo.cords);
				}
			});
		}
		
		protected function spawnEntity(fileName:String, cords:Array):void
		{
			var infoFileName:String = fileName + "Info";
			var meshFileName:String = fileName + "Mesh";
			var bodyDescription:Object = assetsLoader.getObject(infoFileName);
			var EntityType:Class = LevelInfo.entityTypes["spaceshiptHunt.entities::" + bodyDescription.type];
			var polygonArray:Array = assetsLoader.getObject(meshFileName) as Array;
			for (var i:int = 0; i < cords.length; i++)
			{
				var bodyInfo:Entity;
				if (EntityType == Player)
				{
					Player.current.body.position.setxy(cords[i], cords[++i]);
					bodyInfo = Player.current;
				}
				else
				{
					bodyInfo = new EntityType(new Vec2(cords[i], cords[++i]));
				}
				bodyInfo.infoFileName = fileName;
				for (var j:int = 0; j < polygonArray.length; j++)
				{
					addMesh(polygonArray[j], bodyInfo.body);
				}
				physicsSpace.bodies.add(bodyInfo.body);
				bodyInfo.init(bodyDescription);
				mainDisplay.addChild(bodyInfo.graphics);
			}
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
			var bounds:Rectangle = mesh.getBounds(mesh, Pool.getRectangle());
			vertexPos.translatePoints("position", -(bounds.x + bounds.width / 2.0), -(bounds.y + bounds.height / 2.0));
			mesh.x = bounds.x + bounds.width / 2.0;
			mesh.y = bounds.y + bounds.height / 2.0;
			Pool.putRectangle(bounds);
			mesh.touchable = false;
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
			Game.underSpaceshipsLayer.addChildAt(asteroidField, 0);
			physicsSpace.bodies.add(body);
		}
		
		protected function cullAsteroidField():void
		{
			var viewRadius:Number = viewDistance / mainDisplay.scale;
			for (var i:int = 0; i < asteroidField.numChildren; i++)
			{
				var asteroid:DisplayObject = asteroidField.getChildAt(i);
				if (Math.abs(cameraPosition.x - asteroid.x) < viewRadius && Math.abs(cameraPosition.y - asteroid.y) < viewRadius)
				{
					asteroid.visible = true;
				}
				else
				{
					asteroid.visible = false;
				}
			}
		}
		
		protected function syncTransforms():void
		{
			Game.aboveSpaceshipsLayer.transformationMatrix = mainDisplay.transformationMatrix;
			Game.underSpaceshipsLayer.transformationMatrix = mainDisplay.transformationMatrix;
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
	
	}
}