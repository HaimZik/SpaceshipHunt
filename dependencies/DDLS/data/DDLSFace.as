package DDLS.data
{
	public class DDLSFace
	{
	
		public var edge:DDLSEdge;
		private static var face:Vector.<DDLSFace> = new <DDLSFace>[];
		private static var INC:int = 0;
		private var _id:int;
		
		private var _isReal:Boolean;
		
		public var colorDebug:int = -1;
		
		public static function getFaceByID(faceID:int):DDLSFace
		{
			return face[faceID];
		}
		
		public static function get largestID():int
		{
			return INC;
		}
		
		public function DDLSFace()
		{
			_id = INC;
			face[INC++] = this;
		}
		
		[Inline]
		public final function get id():int
		{
			return _id;
		}
		
		public function get isReal():Boolean
		{
			return _isReal;
		}
		
		public function setDatas(edge:DDLSEdge, isReal:Boolean=true):void
		{
			_isReal = isReal;
			this.edge = edge;
		}
		
		public function dispose():void
		{
			edge = null;
		}
		
	}
}