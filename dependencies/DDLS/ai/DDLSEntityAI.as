package DDLS.ai
{
	import DDLS.data.DDLSObject;
	
	public class DDLSEntityAI
	{
		
		private var _radius:Number;
		private var _radiusSquared:Number;
		private var _x:Number;
		private var _y:Number;
		private var _dirNormX:Number;
		private var _dirNormY:Number;
		private var _angleFOV:Number;
		private var _approximateObject:DDLSObject;
		private const NUM_SEGMENTS:int = 6;
		
		public function DDLSEntityAI()
		{
			radius = 10;
			_x = _y = 0;
			_dirNormX = 1;
			_dirNormY = 0;
			_angleFOV = 60;
		}
		
		public function buildApproximation():void
		{
			_approximateObject = new DDLSObject();
			_approximateObject.matrix.translate(x, y);
			var coordinates:Vector.<Number> = new Vector.<Number>();
			_approximateObject.coordinates = coordinates;
			
			if (_radius == 0)
				return;
			
			for (var i:int = 0; i < NUM_SEGMENTS; i++)
			{
				coordinates.push(_radius * Math.cos(2 * Math.PI * i / NUM_SEGMENTS));
				coordinates.push(_radius * Math.sin(2 * Math.PI * i / NUM_SEGMENTS));
				coordinates.push(_radius * Math.cos(2 * Math.PI * (i + 1) / NUM_SEGMENTS));
				coordinates.push(_radius * Math.sin(2 * Math.PI * (i + 1) / NUM_SEGMENTS));
			}
		}
		
		public function get approximateObject():DDLSObject
		{
			//if (!_approximateObject)
			//{
			//return null;
			//}
			//_approximateObject.matrix.identity();
			//_approximateObject.matrix.translate(x, y);
			return _approximateObject;
		}
		
		public function dispose():void
		{
			_approximateObject.dispose();
			_approximateObject = null;
		}
		
		public function get angleFOV():Number
		{
			return _angleFOV;
		}
		
		public function set angleFOV(value:Number):void
		{
			_angleFOV = value;
		}
		
		public function get dirNormY():Number
		{
			return _dirNormY;
		}
		
		public function set dirNormY(value:Number):void
		{
			_dirNormY = value;
		}
		
		public function get dirNormX():Number
		{
			return _dirNormX;
		}
		
		public function set dirNormX(value:Number):void
		{
			_dirNormX = value;
		}
		
		[Inline]
		public final function get x():Number
		{
			return _x;
		}
		
		[Inline]
		public final function set x(value:Number):void
		{
			_x = value;
		}
		
		[Inline]
		public final function get y():Number
		{
			return _y;
		}
		
		[Inline]
		public final function set y(value:Number):void
		{
			_y = value;
		}
		
		[Inline]
		public final function get radius():Number
		{
			return _radius;
		}
		
		public function get radiusSquared():Number
		{
			return _radiusSquared;
		}
		
		public function set radius(value:Number):void
		{
			_radius = value;
			_radiusSquared = _radius * _radius;
		}
	
	}
}