package DDLS.data
{
	import DDLS.data.math.DDLSPoint2D;

	public class DDLSVertex
	{
		
		
		public var pos:DDLSPoint2D;
		public var edge:DDLSEdge;
		
		private var _isReal:Boolean;
		private static var INC:int = 0;
		private var _id:int;
		
		private var _fromConstraintSegments:Vector.<DDLSConstraintSegment>;
		
		public function DDLSVertex()
		{
			_id = INC;
			INC++;
			
			pos = new DDLSPoint2D();
			
			_fromConstraintSegments = new Vector.<DDLSConstraintSegment>();
		}
		
		public function get id():int
		{
			return _id;
		}
		
		[inline]
		public final function get isReal():Boolean
		{
			return _isReal;
		}
		
		public function get fromConstraintSegments():Vector.<DDLSConstraintSegment>
		{
			return _fromConstraintSegments;
		}
		
		public function set fromConstraintSegments(value:Vector.<DDLSConstraintSegment>):void
		{
			_fromConstraintSegments = value;
		}
		
		public function setDatas(edge:DDLSEdge, isReal:Boolean=true):void
		{
			_isReal = isReal;
			this.edge = edge;
		}
		
		public function addFromConstraintSegment(segment:DDLSConstraintSegment):void
		{
			if ( _fromConstraintSegments.indexOf(segment) == -1 )
				_fromConstraintSegments.push(segment);
		}
		
		public function removeFromConstraintSegment(segment:DDLSConstraintSegment):void
		{
			var index:int = _fromConstraintSegments.indexOf(segment);
			if ( index != -1 )
				_fromConstraintSegments.removeAt(index);
		}
		
		public function dispose():void
		{
			edge = null;
			_fromConstraintSegments.length=0;
		}
		
		public function toString():String
		{
			return "ver_id " + _id;
		}
		
	}
}