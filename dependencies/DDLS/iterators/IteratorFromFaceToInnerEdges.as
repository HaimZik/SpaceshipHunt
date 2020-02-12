package DDLS.iterators
{
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;

	public class IteratorFromFaceToInnerEdges
	{
		
		private var _fromFace:DDLSFace;
		private var _nextEdge:DDLSEdge;
		
		public function IteratorFromFaceToInnerEdges()
		{
			
		}
		
		[inline]
		public final function set fromFace( value:DDLSFace ):void
		{
			_fromFace = value;
			_nextEdge = _fromFace.edge;
		}
		
		[inline]
		public final function next():DDLSEdge
		{
			var _resultEdge:DDLSEdge = _nextEdge;
			if (_nextEdge)
			{
				_nextEdge = _nextEdge.nextLeftEdge;				
				if ( _nextEdge == _fromFace.edge )
					_nextEdge = null;
			}			
			return _resultEdge;
		}
		
		
	}
}