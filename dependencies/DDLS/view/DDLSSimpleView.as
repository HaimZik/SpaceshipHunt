package DDLS.view
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
	
	public class DDLSSimpleView
	{
		private var drawCommands:Vector.<int>;
		private var lineCoord:Vector.<Number>;
		
		private var _edges:Sprite;
		private var _constraints:Sprite;
		private var _vertices:Sprite;
		private var _paths:Sprite;
		private var _entities:Sprite;
		
		private var _surface:Sprite;
		
		private var _showVerticesIndices:Boolean = false;
		
		public function DDLSSimpleView()
		{
			_edges = new Sprite();
			_constraints = new Sprite();
			_vertices = new Sprite();
			_paths = new Sprite();
			_entities = new Sprite();
			_surface = new Sprite();
			//_surface.addChild(_edges);
			_surface.addChild(_constraints);
			//	_surface.addChild(_vertices);
			_surface.addChild(_paths);
			//	_surface.addChild(_entities);
			drawCommands = new Vector.<int>();
			lineCoord = new Vector.<Number>();
		}
		
		public function get surface():Sprite
		{
			return _surface;
		}
		
		public function isMeshEndVisable(mesh:DDLSMesh, viewCenterX:Number, viewCenterY, viewRadius:Number):Boolean
		{
			return viewCenterX < viewRadius * 2 || viewCenterX > mesh.width - viewRadius * 2 || viewCenterY < viewRadius * 2 || viewCenterY > mesh.height - viewRadius * 2;
		}
		
		public function drawMesh(mesh:DDLSMesh, cleanBefore:Boolean = true, viewCenterX:Number = 0, viewCenterY = 0, viewRadius:Number = -1):void
		{
			_constraints.scrollRect = new Rectangle(0, 0, viewCenterX + viewRadius, viewCenterY + viewRadius);
			var viewRadiusSquared:Number = Math.pow(viewRadius * 1.5, 2);
			if (cleanBefore)
			{
				cleanMesh();
			}
			while (_vertices.numChildren)
				_vertices.removeChildAt(0);
			
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
				while (incomingEdge)
				{
					if (!dictVerticesDone[incomingEdge.originVertex])
					{
						if (viewRadius == -1 || isLineInView(incomingEdge.originVertex.pos, incomingEdge.destinationVertex.pos, viewCenterX, viewCenterY, viewRadiusSquared))
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
								//_edges.graphics.lineStyle(1, 0x999999, 1, false, LineScaleMode.NONE);
								//_edges.graphics.moveTo(incomingEdge.originVertex.pos.x, incomingEdge.originVertex.pos.y);
								//_edges.graphics.lineTo(incomingEdge.destinationVertex.pos.x, incomingEdge.destinationVertex.pos.y);
							}
						}
					}
					incomingEdge = iterEdges.next();
				}
			}
			drawCommands.length = commandCount + 1;
			lineCoord.length = (commandCount + 1) * 2;
			_constraints.graphics.drawPath(drawCommands, lineCoord);
		}
		
		public function drawEntity(entity:DDLSEntityAI, cleanBefore:Boolean = true):void
		{
			if (cleanBefore)
				_entities.graphics.clear();
			
			_entities.graphics.lineStyle(1, 0x00FF00, 1, false, LineScaleMode.NONE);
			_entities.graphics.beginFill(0x00FF00, 0.5);
			_entities.graphics.drawCircle(entity.x, entity.y, entity.radius);
			_entities.graphics.endFill();
		}
		
		public function drawEntities(vEntities:Vector.<DDLSEntityAI>, cleanBefore:Boolean = true):void
		{
			if (cleanBefore)
				_entities.graphics.clear();
			
			_entities.graphics.lineStyle(1, 0x00FF00, 0.5, false, LineScaleMode.NONE);
			for (var i:int = 0; i < vEntities.length; i++)
			{
				_entities.graphics.beginFill(0x00FF00, 1);
				_entities.graphics.drawCircle(vEntities[i].x, vEntities[i].y, vEntities[i].radius);
				_entities.graphics.endFill();
			}
		}
		
		public function drawPath(path:Vector.<Number>, cleanBefore:Boolean = true, color:uint = 0xFF00FF):void
		{
			if (cleanBefore)
				_paths.graphics.clear();
			
			if (path.length == 0)
				return;
			
			_paths.graphics.lineStyle(1.5, color, 0.5, false, LineScaleMode.NONE);
			
			_paths.graphics.moveTo(path[0], path[1]);
			for (var i:int = 2; i < path.length; i += 2)
				_paths.graphics.lineTo(path[i], path[i + 1]);
		}
		
		public function cleanMesh():void
		{
			//	_surface.graphics.clear();
			_edges.graphics.clear();
			_constraints.graphics.clear();
			_vertices.graphics.clear();
		}
		
		public function cleanPaths():void
		{
			_paths.graphics.clear();
		}
		
		public function cleanEntities():void
		{
			_entities.graphics.clear();
		}
		
		private function vertexIsInsideAABB(vertex:DDLSVertex, mesh:DDLSMesh):Boolean
		{
			if (vertex.pos.x <= 0 || vertex.pos.x >= mesh.width || vertex.pos.y <= 0 || vertex.pos.y >= mesh.height)
				return false;
			else
				return true;
		}
		
		private function isLineInView(lineStart:DDLSPoint2D, lineEnd:DDLSPoint2D, viewCenterX:Number, viewCenterY:Number, viewRangeSquared:Number):Boolean
		{
			var isStartVertexInView:Boolean = Math.pow(viewCenterX - lineStart.x + viewCenterY - lineStart.y, 2) < viewRangeSquared;
			var isEndVertexInView:Boolean = Math.pow(viewCenterX - lineEnd.x + viewCenterY - lineEnd.y, 2) < viewRangeSquared;
			return isStartVertexInView || isEndVertexInView || Math.pow(lineStart.x - lineEnd.x + lineStart.y - lineEnd.y, 2) > viewRangeSquared * 2;
		}
	
	}
}