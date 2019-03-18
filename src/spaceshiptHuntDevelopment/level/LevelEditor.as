package spaceshiptHuntDevelopment.level
{
	import DDLS.data.DDLSObject;
	import DDLSDebug.view.DDLSSimpleView;
	import DDLSDebug.view.DDLSStarlingView;
	import DDLSDebug.view.DDLSView;
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import input.Key;
	import nape.geom.GeomPoly;
	import nape.geom.GeomPolyList;
	import nape.geom.Mat23;
	import nape.geom.Vec2;
	import nape.geom.Winding;
	import nape.phys.Body;
	import nape.phys.BodyList;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.util.ShapeDebug;
	import spaceshiptHunt.entities.BodyInfo;
	import spaceshiptHunt.entities.Enemy;
	import spaceshiptHunt.entities.Entity;
	import spaceshiptHunt.entities.PhysicsParticle;
	import spaceshiptHunt.entities.Spaceship;
	import spaceshiptHunt.level.Environment;
	import starling.core.Starling;
	import starling.display.Canvas;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Stage;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.geom.Polygon;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.Pool;
	CONFIG::air
	{
		import nape.geom.MarchingSquares;
		import flash.display.BitmapData;
		import nape.BitmapDataIso;
		import flash.filesystem.File;
		import flash.filesystem.FileMode;
		import flash.filesystem.FileStream;
	}
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class LevelEditor extends Environment
	{
		private var obstacleBody:Dictionary;
		private var obstaclePolygon:Dictionary;
		private var obstacleDisplay:Dictionary;
		private var navShape:Dictionary;
		private var verticesDisplay:Canvas;
		private var closeVertexIndex:int = -1;
		private var currentPoly:starling.geom.Polygon;
		private var lastObstacleId:int = -1;
		private var napeDebug:ShapeDebug;
		private var navMeshDebugView:DDLSView;
		private var lastViewCenter:Point = new Point(0, 0);
		private var displayNavMesh:Boolean = true;
		private var lastDebugDraw:Number = 0;
		
		CONFIG::air
		{
			private var dragEx:DragAndDropArea;
		}
		private var _levelEditorMode:Boolean;
		
		public function LevelEditor()
		{
			super();
			staticMeshRelativePath = "devPhysicsBodies/";
			obstacleDisplay = new Dictionary();
			obstacleBody = new Dictionary();
			obstaclePolygon = new Dictionary();
			navShape = new Dictionary();
			verticesDisplay = new Canvas();
			var stage:Stage = Starling.current.stage;
			var flashView:DDLSSimpleView;
			navMeshDebugView = flashView = new DDLSSimpleView();
			;
			Starling.current.nativeOverlay.addChild(flashView.surface);
//			navMeshDebugView.surface.mouseEnabled = false;
			//mainDisplay.addChild(navMeshDebugView.canvas);
			//napeDebug = new ShapeDebug(stage.stageWidth, stage.stageHeight, 0x33333333);
			//Starling.current.nativeOverlay.addChild(napeDebug.display);
			Key.addKeyUpCallback(Keyboard.N, switchNavMeshView);
			Key.addKeyUpCallback(Keyboard.F12, toggleLevelEditorMode);
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onZoom);
			CONFIG::air
			{
				dragEx = new DragAndDropArea(0, 0, stage.stageWidth, stage.stageHeight, onFileDrop);
				Starling.current.nativeStage.addChild(dragEx);
				Key.addKeyUpCallback(Keyboard.F1, saveLevel);
				levelEditorMode = false;
			}
		}
		
		protected function onZoom(e:MouseEvent):void
		{
			var preBaseZoom:Number = _baseZoom;
			baseZoom += e.delta * _baseZoom * 0.05;
			camTargetVelocity.setxy(0, 0);
		}
		
		public function get levelEditorMode():Boolean
		{
			return _levelEditorMode;
		}
		
		public function set levelEditorMode(value:Boolean):void
		{
			_levelEditorMode = value;
			if (_levelEditorMode)
			{
				mainDisplay.addChild(verticesDisplay);
			}
			else
			{
				mainDisplay.removeChild(verticesDisplay);
			}
		}
		
		override public function update(passedTime:Number):void
		{
			drawDebugGrp();
			super.update(passedTime);
		}
		
		override public function loadLevel(levelName:String, onFinsh:Function = null):void
		{
			super.loadLevel(levelName, onFinsh);
			commandQueue.push(function addCommand():void
			{
				drawNavMesh();
			});
		}
		
		private function toggleLevelEditorMode():void
		{
			levelEditorMode = !levelEditorMode;
			paused = levelEditorMode;
		}
		
		private static function meshToString(mesh:Vector.<Vector.<int>>):String
		{
			return "[[" + mesh.join("],[") + "]]";
		}
		
		private function drawDebugGrp():void
		{
			if (napeDebug)
			{
				napeDebug.clear();
				napeDebug.draw(Environment.current.physicsSpace);
				napeDebug.flush();
				napeDebug.transform = Mat23.fromMatrix(mainDisplay.transformationMatrix);
			}
			if (displayNavMesh)
			{
				navMeshDebugView.cleanPaths();
				navMeshDebugView.cleanEntities();
				var viewRadius:Number = Math.max(Starling.current.viewPort.width, Starling.current.viewPort.height) / 2;
				var viewCenter:Point = Pool.getPoint(cameraPosition.x, cameraPosition.y);
				//when starling is out of foucus the time reset to zero
				if (lastDebugDraw > lastNavMeshUpdate)
				{
					lastDebugDraw = lastNavMeshUpdate;
				}
				if (lastNavMeshUpdate > lastDebugDraw || Point.distance(viewCenter, lastViewCenter) > viewRadius / 2.1)
				{
					lastDebugDraw = lastNavMeshUpdate;
					lastViewCenter.x = viewCenter.x;
					lastViewCenter.y = viewCenter.y;
					navMeshDebugView.cleanMesh();
					navMeshDebugView.drawMesh(Environment.current.navMesh, false, viewCenter.x, viewCenter.y, viewRadius / mainDisplay.scale);
				}
				Pool.putPoint(viewCenter);
				for (var i:int = 0; i < BodyInfo.list.length; i++)
				{
					if (BodyInfo.list[i] is Entity)
					{
						(BodyInfo.list[i] as Entity).drawDebug(navMeshDebugView);
						if (BodyInfo.list[i] is Spaceship)
						{
							var agent:Enemy = (BodyInfo.list[i] as Enemy);
							if (Key.isDown(Keyboard.U))
							{
								var path:Vector.<Number> = agent.path;
								if (path.length > 2)
								{
									agent.findPathTo(path[path.length - 2], path[path.length - 1], path);
									if (!isPathValid(path))
									{
									agent.findPathTo(path[path.length - 2], path[path.length - 1], path);
										trace("invaild " + agent.body.id);
									}
								}
							}
						}
					}
				}
				(navMeshDebugView as DDLSSimpleView).surface.transform.matrix = mainDisplay.transformationMatrix;
			}
		}
		
		protected function isPathValid(path:Vector.<Number>):Boolean
		{
			for (var i:int = 0; i < path.length-2; i+=1)
			{
				var fromX:Number = path[i];
				var fromY:Number = path[++i];
				if (hitTestLine(fromX, fromY,path[i+1]-fromX,path[i+2]-fromY))
				{
					return false;
				}
			}
			return true;
		}
		
		override protected function syncTransforms():void
		{
			super.syncTransforms();
			if (displayNavMesh)
			{
				(navMeshDebugView as DDLSSimpleView).surface.transform.matrix = mainDisplay.transformationMatrix;
			}
		}
		
		protected function switchNavMeshView():void
		{
			if (displayNavMesh)
			{
				cleanDebugView();
				if (navMeshDebugView is DDLSStarlingView)
				{
					(navMeshDebugView as DDLSStarlingView).canvas.removeFromParent();
				}
			}
			else
			{
				if (navMeshDebugView is DDLSStarlingView)
				{
					mainDisplay.addChild((navMeshDebugView as DDLSStarlingView).canvas);
				}
				drawNavMesh();
			}
			displayNavMesh = !displayNavMesh;
		}
		
		CONFIG::air public function saveFile(path:String, data:String, rootFile:String = null):void
		{
			var file:File;
			if (rootFile)
			{
				file = new File(rootFile + path);
			}
			else
			{
				file = new File(File.applicationDirectory.resolvePath(path).nativePath);
			}
			var fileStream:FileStream = new FileStream();
			fileStream.addEventListener(Event.CLOSE, function fileSaved(e:Event):void
			{
				trace("done saving:" + path);
				fileStream.removeEventListener(Event.CLOSE, arguments.callee);
			});
			fileStream.openAsync(file, FileMode.WRITE);
			fileStream.writeUTFBytes(data);
			fileStream.close();
		}
		
		CONFIG::air public function saveLevel():void
		{
			saveAsteroidField({type: "Static", textureName: "concrete_baked"});
			var levelData:Object = new Object();
			var infoFileName:String;
			for (var i:int = 0; i < BodyInfo.list.length; i++)
			{
				infoFileName = BodyInfo.list[i].infoFileName;
				if (infoFileName)
				{
					if (!levelData[infoFileName])
					{
						levelData[infoFileName] = new Object();
						levelData[infoFileName].cords = new Vector.<int>();
					}
					var typeArray:Object = levelData[infoFileName];
					(typeArray.cords as Vector.<int>).push(BodyInfo.list[i].body.position.x, BodyInfo.list[i].body.position.y);
				}
			}
			levelData["levelSpecific/" + currentLevelName + "/static/asteroidField"] = new Object();
			saveFile(File.applicationDirectory.resolvePath("").nativePath + "/../src/spaceshiptHunt/level/" + currentLevelName + ".json", JSON.stringify(levelData), "");
		}
		
		CONFIG::air public function saveAsteroidField(bodyInfo:Object):void
		{
			var meshData:String = meshToString(getMeshData());
			if (meshData.length > 7)
			{
				saveFile("physicsBodies/levelSpecific/" + currentLevelName + "/static/asteroidField/Mesh.json", meshData);
				var meshDevData:String = "[[" + getDevMesh().join("],[") + "]]";
				saveFile("devPhysicsBodies/levelSpecific/" + currentLevelName + "/static/asteroidField/Mesh.json", meshDevData);
				saveFile("physicsBodies/levelSpecific/" + currentLevelName + "/static/asteroidField/Info.json", JSON.stringify(bodyInfo));
			}
		}
		
		override protected function drawMesh(canvas:DisplayObjectContainer, vertices:starling.geom.Polygon, texture:Texture, normalMap:Texture = null):void
		{
			updateCurrentPoly();
		}
		
		override protected function addMesh(vertices:Array, body:Body):void
		{
			if (body.isDynamic())
			{
				super.addMesh(vertices, body);
			}
			else
			{
				verticesDisplay.clear();
				var obstaclePhysicsBody:Body = new Body(BodyType.KINEMATIC);
				obstaclePhysicsBody.space = physicsSpace;
				lastObstacleId = obstaclePhysicsBody.id;
				obstacleBody[lastObstacleId] = obstaclePhysicsBody;
				currentPoly = new starling.geom.Polygon(vertices);
				obstaclePolygon[lastObstacleId] = currentPoly;
				obstacleDisplay[lastObstacleId] = new Canvas();
				navShape[lastObstacleId] = new DDLSObject();
				navMesh.insertObject(navShape[lastObstacleId]);
				asteroidField.addChild(obstacleDisplay[lastObstacleId]);
			}
		}
		
		override public function handleGameAreaTouch(e:TouchEvent):void
		{
			if (!levelEditorMode)
			{
				super.handleGameAreaTouch(e);
				return;
			}
			var touch:Touch = e.getTouch(mainDisplay.parent);
			if (touch)
			{
				var mouseLocation:Point = touch.getLocation(mainDisplay);
				if (lastObstacleId != -1 && !e.ctrlKey)
				{
					if (obstacleDisplay[lastObstacleId])
					{
						mouseLocation.offset(-obstacleDisplay[lastObstacleId].x, -obstacleDisplay[lastObstacleId].y);
					}
					else
					{
						var selectedBodyGrp:DisplayObject = findBodyInfoById(lastObstacleId).graphics;
						mouseLocation.offset(-selectedBodyGrp.x, -selectedBodyGrp.y);
					}
				}
				if (touch.phase == TouchPhase.BEGAN)
				{
					if (e.ctrlKey || lastObstacleId == -1)
					{
						addMesh([mouseLocation.x, mouseLocation.y], new Body(BodyType.KINEMATIC));
					}
					var pressedBodyId:int = selectPolygon(Vec2.fromPoint(touch.getLocation(mainDisplay)));
					if (obstacleBody[pressedBodyId])
					{
						if (closeVertexIndex == -1 && !e.shiftKey && (currentPoly == obstaclePolygon[lastObstacleId] || pressedBodyId == -1))
						{
							selectVertex(mouseLocation);
						}
						else if (currentPoly.numVertices > 2)
						{
							lastObstacleId = pressedBodyId;
						}
					}
				}
				else
				{
					if (touch.phase == TouchPhase.MOVED && lastObstacleId != -1)
					{
						if (e.shiftKey)
						{
							var mouseMovement:Point;
							if (obstacleBody[lastObstacleId])
							{
								mouseMovement = touch.getMovement(obstacleDisplay[lastObstacleId]);
								moveObstacle(lastObstacleId, mouseMovement.x, mouseMovement.y);
								Environment.current.meshNeedsUpdate = true;
								drawVertices(Color.BLUE);
							}
							else
							{
								var bodyInfo:BodyInfo = findBodyInfoById(lastObstacleId);
								mouseMovement = touch.getMovement(mainDisplay);
								trace(mouseMovement);
								bodyInfo.body.position.x += mouseMovement.x;
								bodyInfo.body.position.y += mouseMovement.y;
								bodyInfo.syncGraphics();
							}
						}
						else if (closeVertexIndex != -1)
						{
							currentPoly.setVertex(closeVertexIndex, mouseLocation.x, mouseLocation.y);
						}
					}
					else if (touch.phase == TouchPhase.ENDED)
					{
						closeVertexIndex = -1;
					}
				}
				if (touch.phase != TouchPhase.HOVER && !e.shiftKey && obstacleBody[lastObstacleId])
				{
					updateCurrentPoly();
				}
			}
		}
		
		override protected function cullAsteroidField():void
		{
		
		}
		
		protected function selectPolygon(underMousePosition:Vec2):int
		{
			for each (var body:Body in obstacleBody)
			{
				if (body.contains(underMousePosition))
				{
					currentPoly = obstaclePolygon[body.id];
					return body.id;
				}
			}
			for (var i:int = 0; i < BodyInfo.list.length; i++)
			{
				var dynamicBody:Body = BodyInfo.list[i].body;
				if (dynamicBody.isDynamic() && dynamicBody.contains(underMousePosition))
				{
					currentPoly = null;
					lastObstacleId = dynamicBody.id;
					trace(lastObstacleId);
					return lastObstacleId;
				}
			}
			return -1;
		}
		
		protected function selectVertex(mouseLocation:Point):void
		{
			var distanceToEdge:Number;
			var closestDistance:Number = Number.MAX_VALUE;
			var pressedEdge:Boolean = false;
			for (var x:int = 0; x < currentPoly.numVertices; x++)
			{
				distanceToEdge = Point.distance(currentPoly.getVertex(x), mouseLocation);
				if (distanceToEdge < closestDistance)
				{
					closestDistance = distanceToEdge;
					closeVertexIndex = x;
					if (distanceToEdge < 30.0)
					{
						var preVertex:Point = currentPoly.getVertex(closeVertexIndex, Pool.getPoint());
						currentPoly.setVertex(closeVertexIndex, mouseLocation.x, mouseLocation.y);
						if (!currentPoly.isSimple)
						{
							currentPoly.setVertex(closeVertexIndex, preVertex.x, preVertex.y);
						}
						Pool.putPoint(preVertex);
						pressedEdge = true;
						break;
					}
				}
			}
			if (!pressedEdge)
			{
				if (currentPoly.numVertices < 3)
				{
					currentPoly.addVertices(mouseLocation);
					closeVertexIndex = currentPoly.numVertices - 1;
				}
				else
				{
					var closeToEdge:Point = Point.interpolate(currentPoly.getVertex(closeVertexIndex), mouseLocation, 0.99999);
					if (!currentPoly.containsPoint(mouseLocation))
					{
						if (currentPoly.containsPoint(closeToEdge))
						{
							closeVertexIndex = -1;
						}
					}
					else if (!currentPoly.containsPoint(closeToEdge))
					{
						closeVertexIndex = -1;
					}
					if (closeVertexIndex != -1)
					{
						addVertex(mouseLocation);
					}
				}
			}
		}
		
		protected function moveObstacle(obstacleId:int, x:Number, y:Number):void
		{
			obstacleDisplay[obstacleId].x += x;
			obstacleDisplay[obstacleId].y += y;
			obstacleBody[obstacleId].translateShapes(Vec2.weak(x, y));
			navShape[obstacleId].x += x;
			navShape[obstacleId].y += y;
		}
		
		protected function drawNavMesh():void
		{
			if (displayNavMesh)
			{
				var viewRadius:Number = Math.max(Starling.current.viewPort.width, Starling.current.viewPort.height) / 2;
				var viewCenter:Point = Pool.getPoint(viewRadius, viewRadius);
				viewCenter = (mainDisplay.globalToLocal(viewCenter));
				navMeshDebugView.drawMesh(Environment.current.navMesh, true, viewCenter.x, viewCenter.y, viewRadius / mainDisplay.scale);
				lastViewCenter.x = viewCenter.x;
				lastViewCenter.y = viewCenter.y;
				Pool.putPoint(viewCenter);
			}
		}
		
		protected function cleanDebugView():void
		{
			navMeshDebugView.cleanPaths();
			navMeshDebugView.cleanEntities();
			navMeshDebugView.cleanMesh();
			if (navMeshDebugView is DDLSStarlingView)
			{
				(navMeshDebugView as DDLSStarlingView).canvas.removeFromParent();
			}
		}
		
		protected function findBodyInfoById(id:int):BodyInfo
		{
			for (var i:int = 0; i < BodyInfo.list.length; i++)
			{
				if (BodyInfo.list[i].body.id == id)
				{
					return BodyInfo.list[i];
				}
			}
			return null;
		}
		
		private function getDevMesh():Vector.<Vector.<Number>>
		{
			var mesh:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>(obstaclePolygon.length, true);
			for (var i:int = 0; i < obstaclePolygon.length; i++)
			{
				mesh[i] = new Vector.<Number>();
				polyToVector(obstaclePolygon[i], mesh[i], 0);
				for (var j:int = 0; j < mesh[i].length; j++)
				{
					mesh[i][j] = int(mesh[i][j] + obstacleDisplay[i].x);
					mesh[i][++j] = int(mesh[i][j] + obstacleDisplay[i].y);
				}
			}
			return mesh;
		}
		
		private function getMeshData():Vector.<Vector.<int>>
		{
			var meshData:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
			var i:int = 0;
			var k:int = 0;
			var j:int = 0;
			var shape:nape.shape.Polygon;
			var bodies:BodyList = physicsSpace.bodies;
			for (i = 0; i < bodies.length; i++)
			{
				var body:Body = bodies.at(i);
				if (body.type != BodyType.DYNAMIC && !body.cbTypes.has(PhysicsParticle.INTERACTION_TYPE))
				{
					for (k = body.shapes.length - 1; k >= 0; k--)
					{
						shape = body.shapes.at(k).castPolygon;
						meshData.push(new Vector.<int>(shape.worldVerts.length * 2, true));
						for (j = 0; j < shape.worldVerts.length; j++)
						{
							meshData[meshData.length - 1][j * 2] = shape.worldVerts.at(j).x;
							meshData[meshData.length - 1][j * 2 + 1] = shape.worldVerts.at(j).y
						}
					}
				}
			}
			return meshData;
		}
		
		private function addVertex(location:Point):void
		{
			var closestDistance:Number = Point.distance(location, currentPoly.getVertex(closeVertexIndex));
			currentPoly.addVertices(currentPoly.getVertex(currentPoly.numVertices - 1));
			var leftVertex:Point;
			for (var j:int = currentPoly.numVertices - 2; j > closeVertexIndex; j--)
			{
				leftVertex = currentPoly.getVertex(j - 1);
				currentPoly.setVertex(j, leftVertex.x, leftVertex.y);
			}
			if (closeVertexIndex != 0)
			{
				leftVertex = currentPoly.getVertex(closeVertexIndex - 1);
			}
			else
			{
				leftVertex = currentPoly.getVertex(currentPoly.numVertices - 1)
			}
			var closePoint:Point = currentPoly.getVertex(closeVertexIndex + 1);
			var nextVertex:Point = currentPoly.getVertex((closeVertexIndex + 2) % currentPoly.numVertices);
			var point1:Point = Point.interpolate(leftVertex, closePoint, closestDistance / Point.distance(leftVertex, closePoint));
			var point2:Point = Point.interpolate(nextVertex, closePoint, closestDistance / Point.distance(nextVertex, closePoint));
			if (Point.distance(location, point1) > Point.distance(location, point2))
			{
				currentPoly.setVertex(++closeVertexIndex, location.x, location.y);
			}
			else
			{
				currentPoly.setVertex(closeVertexIndex, location.x, location.y);
			}
		}
		
		private function drawVertices(color:uint):void
		{
			verticesDisplay.x = obstacleDisplay[lastObstacleId].x;
			verticesDisplay.y = obstacleDisplay[lastObstacleId].y;
			verticesDisplay.clear();
			verticesDisplay.beginFill(color, 0.5);
			var edge:Point;
			for (var j:int = 0; j < currentPoly.numVertices; j++)
			{
				edge = currentPoly.getVertex(j);
				verticesDisplay.drawCircle(edge.x, edge.y, 30);
			}
			verticesDisplay.endFill();
		}
		
		private function updateCurrentPoly():void
		{
			if (currentPoly.numVertices > 2)
			{
				var shape:GeomPoly = GeomPoly.get();
				for (var i:int = 0; i < currentPoly.numVertices; i++)
				{
					shape.push(Vec2.fromPoint(currentPoly.getVertex(i)));
				}
				if (shape.isSimple())
				{
					if (shape.winding() == Winding.ANTICLOCKWISE)
					{
						currentPoly.reverse();
						closeVertexIndex = currentPoly.numVertices - closeVertexIndex - 1;
					}
					obstacleBody[lastObstacleId].shapes.clear();
					var convex:GeomPolyList = shape.convexDecomposition();
					while (!convex.empty())
					{
						obstacleBody[lastObstacleId].shapes.add(new nape.shape.Polygon(convex.pop()));
					}
					obstacleBody[lastObstacleId].translateShapes(Vec2.weak(obstacleDisplay[lastObstacleId].x, obstacleDisplay[lastObstacleId].y));
					var navMeshCords:Vector.<Number> = new Vector.<Number>(currentPoly.numVertices * 4, true);
					polyToVector(currentPoly, navMeshCords);
					for (var l:int = 2; l <= navMeshCords.length - 6; l += 3)
					{
						navMeshCords[l] = navMeshCords[l + 2];
						navMeshCords[++l] = navMeshCords[l + 2];
					}
					navMeshCords[navMeshCords.length - 2] = navMeshCords[0];
					navMeshCords[navMeshCords.length - 1] = navMeshCords[1];
					navShape[lastObstacleId].coordinates = navMeshCords;
					obstacleDisplay[lastObstacleId].clear();
					super.drawMesh(obstacleDisplay[lastObstacleId], currentPoly, assetsLoader.getTexture("concrete_baked"), assetsLoader.getTexture("concrete_baked_n"));
					drawVertices(Color.BLUE);
					Environment.current.meshNeedsUpdate = true;
				}
				else
				{
					obstacleDisplay[lastObstacleId].clear();
					obstacleDisplay[lastObstacleId].beginFill(Color.RED, 0.5);
					obstacleDisplay[lastObstacleId].drawPolygon(obstaclePolygon[lastObstacleId]);
					obstacleDisplay[lastObstacleId].endFill();
					drawVertices(Color.RED);
				}
				shape.dispose();
			}
			else
			{
				drawVertices(Color.OLIVE);
			}
		}
		
		private function polyToVector(polygon:starling.geom.Polygon, array:Vector.<Number>, stride:int = 2):void
		{
			var numVertices:int = polygon.numVertices;
			var vertex:Point = Pool.getPoint();
			for (var i:int = 0; i < numVertices; i++)
			{
				vertex = polygon.getVertex(i, vertex);
				array[i * 2 + i * stride] = vertex.x;
				array[i * 2 + 1 + i * stride] = vertex.y;
			}
			Pool.putPoint(vertex);
		}
		
		CONFIG::air
		{
			public static function imageToMesh(image:BitmapData, pivotX:Number = 0.5, pivotY:Number = 0.5):Vector.<Vector.<int>>
			{
				var body:Body = new Body();
				var imageIso:BitmapDataIso = new BitmapDataIso(image);
				var polys:GeomPolyList = MarchingSquares.run(imageIso, imageIso.bounds, new Vec2(4, 4), 2);
				var data:Vector.<Vector.<int>> = new Vector.<Vector.<int>>();
				for (var i:int = 0; i < polys.length; i++)
				{
					var list:GeomPolyList = polys.at(i).simplify(3).convexDecomposition();
					var shape:nape.shape.Polygon;
					while (!list.empty())
					{
						shape = new nape.shape.Polygon(list.pop());
						//if (physicsSpace)
						//{
						//body.shapes.add(shape);
						//}
						data.push(new Vector.<int>(shape.localVerts.length * 2, true));
						for (var j:int = 0; j < shape.localVerts.length; j++)
						{
							data[data.length - 1][j * 2] = shape.localVerts.at(j).x - pivotX * image.width
							data[data.length - 1][j * 2 + 1] = shape.localVerts.at(j).y - pivotY * image.height;
						}
					}
				}
				return data;
			}
			
			private function dropJSON(x:Number, y:Number, file:File):void
			{
				var fs:FileStream = new FileStream();
				fs.open(file, FileMode.READ);
				var data:String = fs.readUTFBytes(fs.bytesAvailable);
				trace(data);
				fs.close();
			}
			
			private function dropImage(x:Number, y:Number, file:File):void
			{
				var loader:Loader = new Loader();
				var urlReq:URLRequest = new URLRequest(file.url);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
				{
					var bmp:Bitmap = e.target.content as Bitmap;
					var data:BitmapData = bmp.bitmapData;
					var name:String = file.name.slice(0, file.name.indexOf("."));
					if (name.substr(0, "level".length).toLowerCase() == "level")
					{
						saveFile("devPhysicsBodies/levelSpecific/" + name + "/static/asteroidField/Mesh.json", meshToString(imageToMesh(data, 0, 0)));
					}
					else
					{
						saveFile("physicsBodies/" + name + "/Mesh.json", meshToString(imageToMesh(data)));
					}
					data.dispose();
					loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, arguments.callee);
				});
				loader.load(urlReq);
			}
			
			protected function dropFolder(x:Number, y:Number, file:File):void
			{
				var spwanLocation:Point = mainDisplay.globalToLocal(new Point(x, y));
				spawnEntity(file.name, [spwanLocation.x, spwanLocation.y]);
				if (paused)
				{
					syncGraphics();
				}
			}
			
			private function onFileDrop(x:Number, y:Number, file:File):void
			{
				if (file.type == null)
				{
					dropFolder(x, y, file);
				}
				else if (file.type == ".json")
				{
					dropJSON(x, y, file);
				}
				else
				{
					dropImage(x, y, file);
				}
			}
		
		}
	}
}