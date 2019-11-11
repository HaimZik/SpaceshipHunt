package DDLS.iterators
{
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSVertex;
	
	public class IteratorFromVertexToOutgoingEdges
	{
		
		private var _fromVertex:DDLSVertex;
		private var _nextEdge:DDLSEdge;
		private var _resultEdge:DDLSEdge;
		
		public function IteratorFromVertexToOutgoingEdges()
		{
		
		}
		
		public function set fromRealVertex(value:DDLSVertex):void
		{
			_fromVertex = value;
			_nextEdge = _fromVertex.edge;
			while (!_nextEdge.isReal)
			{
				_nextEdge = _nextEdge.rotLeftEdge;
			}
		}
		
		public function set fromAnyVertex(value:DDLSVertex):void
		{
			_fromVertex = value;
			_nextEdge = _fromVertex.edge;
		}
		
		[inline]
		public final function next():DDLSEdge
		{
			_resultEdge = _nextEdge;
			if (_nextEdge)
			{
				_nextEdge = _nextEdge.rotLeftEdge;
				if (_nextEdge == _fromVertex.edge)
				{
					_nextEdge = null;
				}
			}
			
			return _resultEdge;
		}
		
		[inline]
		public final function nextRealEdge():DDLSEdge
		{
			if (_nextEdge)
			{
				_resultEdge = _nextEdge;
				do
				{
					_nextEdge = _nextEdge.rotLeftEdge;
					if (_nextEdge == _fromVertex.edge)
					{
						_nextEdge = null;
						break;
					}
				} while (!_nextEdge.isReal)
			}
			else
			{
				_resultEdge = null;
			}
			
			return _resultEdge;
		}
	
	}
}