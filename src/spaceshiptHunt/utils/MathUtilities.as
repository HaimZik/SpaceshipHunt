package spaceshiptHunt.utils
{
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import starling.utils.MathUtil;
	
	public class MathUtilities
	{
		
		public static function angleDifference(angle1:Number, angle2:Number):Number
		{
			var angleDiff:Number = MathUtil.normalizeAngle(angle1 - angle2);
			//in order to get the shorter angle
			if (Math.abs(angleDiff) > Math.PI / 2)
			{
				angleDiff -= (Math.abs(angleDiff) / angleDiff) * Math.PI*2;
			}
			return angleDiff;
		}
		
		public static function angleDifferenceAbs(angle1:Number, angle2:Number):Number
		{
			return Math.abs(angleDifference(angle1,angle2));
		}
	
	}

}