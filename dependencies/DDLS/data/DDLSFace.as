package DDLS.data
{
	public class DDLSFace
	{
	
		public var edge:DDLSEdge;
		public var id:int;
		private static var face:Vector.<DDLSFace> = new <DDLSFace>[];
		private static var INC:int = 0;
		
		private var _isReal:Boolean;
		
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
			id = INC;
			face[INC++] = this;
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