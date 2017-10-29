package spaceshiptHunt.controls
{
	import flash.geom.Point;
	import starling.core.Starling;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.geom.Polygon;
	import starling.rendering.VertexData;
	import starling.utils.Color;
	import starling.utils.Pool;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class TouchJoystick extends Sprite
	{
		
		protected var _radios:Number;
		protected var xAxis:Number;
		protected var yAxis:Number;
		private var analogStick:Mesh;
		
		public function TouchJoystick()
		{
			addEventListener(TouchEvent.TOUCH, onTouch);
			drawJoystick();
		}
		
		protected function onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);
			if (touch)
			{
				if (touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.BEGAN)
				{
					var position:Point = Pool.getPoint();
					touch.getLocation(this, position);
					if (position.length > radios * 1.2)
					{
						position.normalize(radios * 1.2);
					}
					analogStick.x = position.x;
					analogStick.y = position.y;
					Pool.putPoint(position);
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					analogStick.x = 0;
					analogStick.y = 0;
				}
			}
		}
		
		private function drawJoystick():void
		{
			radios = Math.min(550, Starling.current.stage.stageWidth, Starling.current.stage.stageHeight) / 4;
			var joystickShape:Polygon = Polygon.createCircle(0, 0, radios);
			var vertices:VertexData = new VertexData(null, joystickShape.numVertices);
			joystickShape.copyToVertexData(vertices);
			var joystickBase:Mesh = new Mesh(vertices, joystickShape.triangulate());
			analogStick = new Mesh(vertices, joystickShape.triangulate());
			analogStick.alpha = joystickBase.alpha = 0.3;
			analogStick.color = joystickBase.color = Color.WHITE;
			addChild(joystickBase);
			analogStick.scale = 0.6;
			addChild(analogStick);
			pivotY = pivotX = radios;
		}
		
		public function get xAxis():Number
		{
			return Math.min(1, analogStick.x / 160.0);
		}
		
		public function get yAxis():Number
		{
			return Math.min(1, analogStick.y / 160.0);
		}
		
		public function get radios():Number
		{
			return _radios;
		}
		
		public function set radios(value:Number):void
		{
			_radios = value;
			width = height = _radios * 2;
			pivotX = pivotY = _radios;
		}
	
		//public function set yAxis(value:):void 
		//{
		//yAxis = value;
		//}
	
		//public function set xAxis(value:):void 
		//{
		//xAxis = value;
		//}
	
	}

}