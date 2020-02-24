package spaceshiptHunt.controls
{
	import starling.display.Mesh;
	import starling.geom.Polygon;
	import starling.utils.Color;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class DashJoystick extends TouchJoystick
	{
		protected var arrowColor:Vector.<uint> = new <uint>[Color.GREEN, Color.YELLOW, Color.RED];
		protected var arrowEdgeColor:Vector.<uint> = new Vector.<uint>(3);
		protected var arrowRatioToRadius:Number = 0.5;
		protected var disabledSaturation:Number = 0.4;
		protected var arrowAlignment:Number = 0.65;
		protected var distanceBetweenArrows:Number = 15.0 * 1.2;
		protected var arrowVertices:VertexData;
		protected var arrowIndices:IndexData;
		protected var rightArrows:Vector.<Mesh>;
		protected var leftArrows:Vector.<Mesh>;
		
		public function DashJoystick(isHorizontal:Boolean = false)
		{
			rightArrows = new Vector.<Mesh>(3);
			leftArrows = new Vector.<Mesh>(3);
			arrowVertices = new VertexData(null, 3);
			arrowIndices = new IndexData(3);
			arrowIndices.addTriangle(0, 1, 2);
			arrowEdgeColor[0] = Color.interpolate(arrowColor[0], arrowColor[1], 0.8);
			arrowEdgeColor[1] = Color.interpolate(Color.interpolate(arrowColor[0], arrowColor[1], 0.6), arrowColor[2], 0.9);
			arrowEdgeColor[2] = arrowColor[2];
			super(isHorizontal);
		}
		
		override protected function drawJoystick():void
		{
			super.drawJoystick();
			var analogStickIndex:int = getChildIndex(analogStick);
			for (var i:int = 0; i < leftArrows.length; i++)
			{
				rightArrows[i] = new Mesh(arrowVertices.clone(), arrowIndices.clone());
				leftArrows[i] = new Mesh(arrowVertices.clone(), arrowIndices.clone());
				leftArrows[i].touchable = false ;
				rightArrows[i].touchable = false;
				leftArrows[i].alpha=rightArrows[i].alpha = (joystickAlpha * 1.8 + 0.4) / 2.0;
				rightArrows[i].x = _radius * arrowAlignment + distanceBetweenArrows * i;
				leftArrows[i].x = -_radius * arrowAlignment - distanceBetweenArrows * i;
				leftArrows[i].scaleX = -1;
				addChildAt(leftArrows[i], analogStickIndex+1+i);
				addChildAt(rightArrows[i], analogStickIndex+2+i*2);
			}
			
			for (var j:int = leftArrows.length-1; j >=0; j--) 
			{
			//addChildAt(leftArrows[j], analogStickIndex);
			//addChildAt(rightArrows[j],analogStickIndex);	
			}
			colouriseArrows(rightArrows, 0, rightArrows.length);//, disabledSaturation);
			colouriseArrows(leftArrows, 0, rightArrows.length);//, disabledSaturation);
		}
		
		protected function colouriseArrows(arrow:Vector.<Mesh>,fromIndex:int, count:int, saturation:Number = 1):void
		{
			if (fromIndex == 0)
			{
				arrow[0].color = arrowColor[0];
			}
			if (fromIndex + count > 1 && fromIndex <= 1)
			{
				arrow[1].color = Color.interpolate(arrowColor[0], arrowColor[1], 0.6);
			}
			if (fromIndex + count > 2 && fromIndex <= 2)
			{
				arrow[2].color = Color.interpolate(arrowColor[1], arrowColor[2], 0.7);
			}
			for (var i:int = fromIndex; i < fromIndex + count; i++)
			{
				arrow[i].color = Color.interpolate(Color.GRAY, arrow[i].color, saturation);
				arrow[i].setVertexColor(2, Color.interpolate(Color.GRAY, arrowEdgeColor[i], saturation));
			}
		}
		
		public function onDash():void
		{
			colouriseArrows(rightArrows, 0, rightArrows.length);
			colouriseArrows(leftArrows,0, rightArrows.length);
			//colouriseArrows(0, rightArrows.length - 2);
			//colouriseArrows(1,1,0.3+disabledSaturation*0.7);
			for (var i:int = 0; i < rightArrows.length; i++)
			{
				rightArrows[i].alpha = 0.9;//(3 - i) * 0.3;
				leftArrows[i].alpha = 0.9;//(3 - i) * 0.3;
			}
		}
		
		override public function set radios(value:Number):void
		{
			super.radios = value;
			var arrowHeight:Number = _radius * arrowRatioToRadius;
			arrowVertices.setPoint(0, "position", 0, -arrowHeight);
			arrowVertices.setPoint(1, "position", 0, arrowHeight);
			arrowVertices.setPoint(2, "position", arrowHeight * 0.5, 0);
		}
	
	}

}