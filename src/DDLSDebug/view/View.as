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
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	public class View
	{
		protected var _showVerticesIndices:Boolean = false;
		protected var _vertices:flash.display.Sprite = new Sprite();
		
		public function View()
		{
		
		}
		
		public function isMeshEndVisable(mesh:DDLSMesh, viewCenterX:Number, viewCenterY, viewRadius:Number):Boolean
		{
			return viewCenterX < viewRadius * 2 || viewCenterX > mesh.width - viewRadius * 2 || viewCenterY < viewRadius * 2 || viewCenterY > mesh.height - viewRadius * 2;
		}
		
		public function drawMesh(mesh:DDLSMesh, cleanBefore:Boolean = true, viewCenterX:Number = 0, viewCenterY = 0, viewRadius:Number = -1):void
		{
			if (cleanBefore)
			{
				cleanMesh();
			}
			while (_vertices.numChildren)
				_vertices.removeChildAt(0);
		}
		
		public function drawEntity(entity:DDLSEntityAI, cleanBefore:Boolean = true):void
		{
			if (cleanBefore)
				cleanEntities();
		}
		
		public function drawEntities(vEntities:Vector.<DDLSEntityAI>, cleanBefore:Boolean = true):void
		{
			if (cleanBefore)
				cleanEntities();
		}
		
		public function drawPath(path:Vector.<Number>, cleanBefore:Boolean = true, color:uint = 0xFF00FF):void
		{
		}
		
		public function cleanMesh():void
		{
			_vertices.graphics.clear();
		}
		
		public function cleanPaths():void
		{
		}
		
		public function cleanEntities():void
		{
		}
		
		protected function vertexIsInsideAABB(vertex:DDLSVertex, mesh:DDLSMesh):Boolean
		{
			if (vertex.pos.x <= 0 || vertex.pos.x >= mesh.width || vertex.pos.y <= 0 || vertex.pos.y >= mesh.height)
				return false;
			else
				return true;
		}
		
		protected function isLineInView(lineStart:DDLSPoint2D, lineEnd:DDLSPoint2D, viewCenterX:Number, viewCenterY:Number, viewRange:Number):Boolean
		{
			var isStartVertexInView:Boolean = Math.abs(viewCenterX - lineStart.x) < viewRange && Math.abs(viewCenterY - lineStart.y) < viewRange;
			var isEndVertexInView:Boolean = Math.abs(viewCenterX - lineEnd.x) < viewRange && Math.abs(viewCenterY - lineEnd.y) < viewRange;
			return isStartVertexInView || isEndVertexInView || Math.pow(lineStart.x - lineEnd.x + lineStart.y - lineEnd.y, 2) > viewRange*viewRange * 2;
		}
	
	}
}