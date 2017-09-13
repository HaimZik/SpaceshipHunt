package spaceshiptHunt.utils
{
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	
	import nape.geom.Vec2;
	import starling.utils.MathUtil;
	
	public class MathUtilities
	{
		
		public static function angleDifference(angle1:Number, angle2:Number):Number
		{
			var angleDiff:Number = MathUtil.normalizeAngle(angle1 - angle2);
			return angleDiff;
		}
		
		public static function angleDifferenceAbs(angle1:Number, angle2:Number):Number
		{
			return Math.abs(angleDifference(angle1, angle2));
		}
		
		public static function clampVector(vector:Vec2, minLength:Number, maxLength:Number):void
		{
			if (vector.lsq() < minLength * minLength)
			{
				vector.length = minLength;
			}
			else if (vector.lsq() > maxLength * maxLength)
			{
				vector.length = maxLength;
			}
		}
	
	}

}