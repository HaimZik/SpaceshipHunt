package spaceshiptHunt.controls 
{
	import starling.display.Mesh;
	import starling.utils.Color;
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Flightstick extends TouchJoystick 
	{
		
		public function Flightstick(isHorizontal:Boolean=true) 
		{
			super(isHorizontal);
		}
		
		override protected function drawJoystick():void 
		{
			super.drawJoystick();
			var fireButtonUpper:Mesh = new Mesh(circleVertices.clone(), circleIndices.clone());
			var fireButtonDown:Mesh = new Mesh(circleVertices.clone(), circleIndices.clone());
			var buttonColor:uint = Color.RED;
			fireButtonUpper.color = buttonColor;
			var shadowDarkness:uint = 100;
			fireButtonDown.color = Color.setRed(buttonColor, Color.getRed(buttonColor) - shadowDarkness);
			fireButtonDown.touchable = false;
			fireButtonUpper.touchable = false;
			analogStick.addChild(fireButtonDown);
			analogStick.addChild(fireButtonUpper);
			fireButtonDown.scaleX = 0.6;
			fireButtonDown.scaleY = 0.6;
			fireButtonUpper.scaleX = 0.6;
			fireButtonUpper.scaleY = 0.6;
			fireButtonUpper.y -= 12;
		}
		
	}

}