package DDLS.data.math
{
	public class DDLSRandGenerator
	{
		
		private var _originalSeed:int;
		private var _currSeed:int;
		public var rangeMin:int;
		public var rangeMax:int;
		
		private var _numIter:int;
		private var _tempString:String;
		
		public function DDLSRandGenerator(seed:int=1234, rangeMin:int=0, rangeMax:int=1)
		{
			_originalSeed = _currSeed = seed;
			this.rangeMin = rangeMin;
			this.rangeMax = rangeMax;
			
			_numIter = 0;
		}
		
		public function set seed(value:int):void		{	_originalSeed = _currSeed = value;		}
		
		public function get seed():int					{		return _originalSeed;	}
		
		public function reset():void
		{
			_currSeed = _originalSeed;
			_numIter = 0;
		}
		
		[inline]
		public final function next():int
		{
			_tempString = (_currSeed*_currSeed).toString();
			
			while (_tempString.length < 8)
			{
				_tempString = "0" + _tempString;
			}
			
			_currSeed = int(_tempString.substr( 1 , 5 ));
			
			var res:int = Math.round(rangeMin + (_currSeed / 99999)*(rangeMax - rangeMin));
			
			if (_currSeed == 0)
				_currSeed = _originalSeed+_numIter;
			
			_numIter++;
			
			if (_numIter == 200)
				reset();
			return res;	
				
			//fix for bad performance
		//	return rangeMin+int(Math.random()*(rangeMax-rangeMin));
		}

	}
}