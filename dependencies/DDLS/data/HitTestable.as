package DDLS.data
{
	import DDLS.ai.DDLSEntityAI;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public interface HitTestable  
	{		
	   function hitTestLine(fromX:Number,fromY:Number,directionX:Number, directionY:Number):Boolean;	
	}
	
}