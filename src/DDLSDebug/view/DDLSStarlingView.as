package DDLSDebug.view
{
	import DDLS.data.DDLSMesh;
	import DDLS.ai.DDLSEntityAI;
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSVertex;
	import DDLS.data.math.DDLSPoint2D;
	import DDLS.iterators.IteratorFromMeshToVertices;
	import DDLS.iterators.IteratorFromVertexToIncomingEdges;
	import flash.utils.Dictionary;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Sprite;
	import starling.display.graphics.Stroke;
	import starling.filters.FragmentFilter;
	//import starling.textures.TextureSmoothing;
	import starling.utils.Color;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class DDLSStarlingView extends DDLSView
	{
		public var canvas:Sprite;
		protected var graphics:Stroke;
		protected var paths:Stroke;
		
		public function DDLSStarlingView()
		{
			super();
			canvas = new Sprite();
			canvas.touchable = false;
			graphics = new Stroke();
			graphics.alpha = 0.3;
			paths = new Stroke();
			canvas.addChild(graphics);
			canvas.addChild(paths);
			//var filter:FragmentFilter = new FragmentFilter();
			//	filter.textureSmoothing = TextureSmoothing.NONE;
			//filter.resolution = 0.5;
			//canvas.filter = filter;
		}
		
		override public function drawMesh(mesh:DDLSMesh, cleanBefore:Boolean = true, viewCenterX:Number = 0, viewCenterY = 0, viewRadius:Number = -1):void
		{
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
			//if (viewRadius == -1 || isMeshEndVisable(mesh, viewCenterX, viewCenterY, viewRadius))
			//{
//				graphics.drawRect(0, 0, mesh.width, mesh.height);
		//	}
			while ((vertex = iterVertices.next()) != null)
			{
				dictVerticesDone[vertex] = true;
				//		if (!vertexIsInsideAABB(vertex, mesh))
				//		continue;
				
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
				var destinationX:Number = 0;
				var destinationY:Number = 0;
				var thickness:Number = 6;
				var color:uint = 0xFF0000;
				var lineAlpha:Number = 0.5;
				while (incomingEdge)
				{
					if (!dictVerticesDone[incomingEdge.originVertex])
					{
						//	if (viewRadius == -1 || isLineInView(incomingEdge.originVertex.pos, incomingEdge.destinationVertex.pos, viewCenterX, viewCenterY, viewRadius))
						{
							if (incomingEdge.isConstrained)
							{
								color = 0xFF0000;
							}
							else
							{
								color = 0x999999;
							}
							graphics.moveTo(incomingEdge.originVertex.pos.x, incomingEdge.originVertex.pos.y);
							destinationX = incomingEdge.destinationVertex.pos.x;
							destinationY = incomingEdge.destinationVertex.pos.y;
							graphics.lineTo(incomingEdge.originVertex.pos.x, incomingEdge.originVertex.pos.y, thickness, color, lineAlpha);
							graphics.lineTo(destinationX, destinationY, thickness, color, lineAlpha);
						}
					}
					incomingEdge = iterEdges.next();
				}
			}
		}
		
		override public function cleanMesh():void
		{
			super.cleanMesh();
			graphics.clear();
		}
		
//		public function dispose
		
		override public function cleanPaths():void
		{
			super.cleanPaths();
			paths.clear();
		}
		
		override public function drawPath(path:Vector.<Number>, cleanBefore:Boolean = true, color:uint = 0xFF00FF):void
		{
			super.drawPath(path, cleanBefore, color);
			if (path.length == 0)
				return;
			var thickness:Number = 1;
			paths.moveTo(path[0], path[1]);
			for (var i:int = 0; i < path.length-1; i += 2)
			{
				paths.lineTo(path[i], path[i + 1], thickness+((i/2)%2)*2, color, 0.5);
			}
		}
	
	}
}