package DDLSDebug.view
{
	import DDLS.ai.DDLSEntityAI;
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSVertex;
	import DDLS.data.math.DDLSPoint2D;
	import DDLS.iterators.IteratorFromMeshToVertices;
	import DDLS.iterators.IteratorFromVertexToIncomingEdges;
	import flash.display.GraphicsPathCommand;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class DDLSSimpleView extends DDLSView
	{
		protected var drawCommands:Vector.<int>;
		protected var lineCoord:Vector.<Number>;
		
		protected var _edges:Sprite;
		protected var _constraints:Sprite;
//		protected var _vertices:Sprite;
		protected var _paths:Sprite;
		protected var _entities:Sprite;
		
		protected var _surface:Sprite;
		
		public function DDLSSimpleView()
		{
			_edges = new Sprite();
			_constraints = new Sprite();
			_paths = new Sprite();
			_entities = new Sprite();
			_surface = new Sprite();
			_surface.addChild(_edges);
			_surface.addChild(_constraints);
			//	_surface.addChild(_vertices);
			_surface.addChild(_paths);
			_surface.addChild(_entities);
			drawCommands = new Vector.<int>();
			lineCoord = new Vector.<Number>();
		}
		
		public function get surface():Sprite
		{
			return _surface;
		}
		
		override public function drawMesh(mesh:DDLSMesh, cleanBefore:Boolean = true, viewCenterX:Number = 0, viewCenterY = 0, viewRadius:Number = -1):void
		{
			_constraints.scrollRect = new Rectangle(viewCenterX - viewRadius, viewCenterY - viewRadius, viewRadius * 2.1, viewRadius * 2.1);
			_constraints.x = viewCenterX - viewRadius;
			_constraints.y = viewCenterY - viewRadius;
			super.drawMesh(mesh, cleanBefore, viewCenterX, viewCenterY, viewRadius);
			var vertex:DDLSVertex;
			var incomingEdge:DDLSEdge;
			var holdingFace:DDLSFace;		
			var iterVertices:IteratorFromMeshToVertices;
			iterVertices = new IteratorFromMeshToVertices();
			iterVertices.fromMesh = mesh;
			var iterEdges:IteratorFromVertexToIncomingEdges;
			iterEdges = new IteratorFromVertexToIncomingEdges();
			var dictVerticesDone:Dictionary;
			dictVerticesDone = new Dictionary();
			var commandCount:int = -1;
			_constraints.graphics.lineStyle(2, 0xFF0000, 1, false, LineScaleMode.NONE);
			if (viewRadius == -1 || isMeshEndVisable(mesh, viewCenterX, viewCenterY, viewRadius))
			{
				_constraints.graphics.drawRect(0, 0, mesh.width, mesh.height);
			}
			while ((vertex = iterVertices.next()) != null)
			{
				dictVerticesDone[vertex] = true;
				if (!vertexIsInsideAABB(vertex, mesh))
					continue;
				
				//_vertices.graphics.lineStyle(0, 0);
				//_vertices.graphics.beginFill(0x0000FF, 1);
				//_vertices.graphics.drawCircle(vertex.pos.x, vertex.pos.y, 0.5);
				//_vertices.graphics.endFill();
				
				//if (_showVerticesIndices)
				//{
				//var tf:TextField = new TextField();
				//tf.mouseEnabled = false;
				//tf.text = String(vertex.id);
				//tf.x = vertex.pos.x + 5;
				//tf.y = vertex.pos.y + 5;
				//tf.width = tf.height = 20;
				//_vertices.addChild(tf);
				//}
				
				iterEdges.fromVertex = vertex;
				incomingEdge = iterEdges.next();
				_edges.graphics.lineStyle(1, 0x999999, 1, false, LineScaleMode.NONE);
				while (incomingEdge)
				{
					if (!dictVerticesDone[incomingEdge.originVertex])
					{
						if (viewRadius == -1 || isLineInView(incomingEdge.originVertex.pos, incomingEdge.destinationVertex.pos, viewCenterX, viewCenterY, viewRadius))
						{
							if (incomingEdge.isConstrained)
							{
								//_constraints.graphics.lineStyle(2, 0xFF0000, 1, false, LineScaleMode.NONE);
								drawCommands[++commandCount] = GraphicsPathCommand.MOVE_TO;
								lineCoord[commandCount * 2] = incomingEdge.originVertex.pos.x;
								lineCoord[commandCount * 2 + 1] = incomingEdge.originVertex.pos.y;
								drawCommands[++commandCount] = GraphicsPathCommand.LINE_TO;
								lineCoord[commandCount * 2] = incomingEdge.destinationVertex.pos.x;
								lineCoord[commandCount * 2 + 1] = incomingEdge.destinationVertex.pos.y;
							}
							else
							{
						//	_edges.graphics.moveTo(incomingEdge.originVertex.pos.x, incomingEdge.originVertex.pos.y);
						//	_edges.graphics.lineTo(incomingEdge.destinationVertex.pos.x, incomingEdge.destinationVertex.pos.y);
							}
						}
					}
					incomingEdge = iterEdges.next();
				}
			}
			drawCommands.length = commandCount + 1;
			lineCoord.length = drawCommands.length * 2;
			_constraints.graphics.drawPath(drawCommands, lineCoord);
		}
		
		override public function drawEntity(entity:DDLSEntityAI, cleanBefore:Boolean = true):void
		{
			super.drawEntity(entity, cleanBefore);
			_entities.graphics.lineStyle(1, 0x00FF00, 1, false, LineScaleMode.NONE);
			_entities.graphics.beginFill(0x00FF00, 0.1);
			_entities.graphics.drawCircle(entity.x, entity.y, entity.radius);
			_entities.graphics.endFill();
		}
		
		override public function drawEntities(vEntities:Vector.<DDLSEntityAI>, cleanBefore:Boolean = true):void
		{
			super.drawEntities(vEntities, cleanBefore);
			_entities.graphics.lineStyle(1, 0x00FF00, 0.5, false, LineScaleMode.NONE);
			for (var i:int = 0; i < vEntities.length; i++)
			{
				_entities.graphics.beginFill(0x00FF00, 1);
				_entities.graphics.drawCircle(vEntities[i].x, vEntities[i].y, vEntities[i].radius);
				_entities.graphics.endFill();
			}
		}
		
		override public function drawPath(path:Vector.<Number>, cleanBefore:Boolean = true, color:uint = 0xFF00FF):void
		{
			super.drawPath(path, cleanBefore, color);
			if (path.length == 0)
				return;
			
			_paths.graphics.lineStyle(1.5, color, 0.5, false, LineScaleMode.NONE);
			
			_paths.graphics.moveTo(path[0], path[1]);
			for (var i:int = 2; i < path.length; i += 2)
				_paths.graphics.lineTo(path[i], path[i + 1]);
		}
		
		override public function cleanMesh():void
		{
			super.cleanMesh();
			//	_surface.graphics.clear();
			_edges.graphics.clear();
			_constraints.graphics.clear();
		}
		
		override public function cleanPaths():void 
		{
			super.cleanPaths();
			_paths.graphics.clear();
		}
		
		override public function cleanEntities():void 
		{
			super.cleanEntities();
			_entities.graphics.clear();
		}
	
	}
}