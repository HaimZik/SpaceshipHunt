package spaceshiptHunt.controls
{
	import flash.geom.Point;
	import flash.system.Capabilities;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.geom.Polygon;
	import starling.rendering.IndexData;
	import starling.rendering.VertexData;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starling.utils.SystemUtil;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class TouchJoystick extends Sprite
	{
		public var isHorizontal:Boolean;
		public var isDoubleTaping:Boolean;
		protected var _radius:Number;
		protected var extraTouchRadius:Number = 40;
		protected var touchRadiusSqr:Number;
		protected var xAxis:Number;
		protected var yAxis:Number;
		protected var analogStick:Sprite;
		protected var circleVertices:VertexData;
		protected var circleIndices:IndexData;
		
		public function TouchJoystick(isHorizontal:Boolean = false)
		{
			this.isHorizontal = isHorizontal;
			addEventListener(TouchEvent.TOUCH, onTouch);
			var circle:Polygon = Polygon.createCircle(0, 0, radios, 13);
			circleVertices = new VertexData(null, circle.numVertices);
			circle.copyToVertexData(circleVertices);
			circleIndices = circle.triangulate();
			drawJoystick();
		}
		
		protected function onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);
			if (touch)
			{
				if (touch.phase == TouchPhase.BEGAN)
				{
					isDoubleTaping = touch.tapCount > 1;
				}
				if (touch.phase == TouchPhase.MOVED || touch.phase == TouchPhase.BEGAN)
				{
					var position:Point = Pool.getPoint();
					touch.getLocation(this, position);
					if (position.length > radios)
					{
						position.normalize(radios);
					}
					analogStick.x = position.x;
					if (!isHorizontal)
					{
						analogStick.y = position.y;
					}
					Pool.putPoint(position);
				}
				else if (touch.phase == TouchPhase.ENDED)
				{
					analogStick.x = 0;
					analogStick.y = 0;
				}
			}
		}
		
		protected function drawJoystick():void
		{
			if (SystemUtil.isDesktop)
			{
				// Math.min(512, Starling.current.stage.stageWidth, Starling.current.stage.stageHeight) / 4;	
				radios = Capabilities.screenDPI;
			}
			else
			{
				radios = Capabilities.screenDPI * 0.4;
			}
			var joystickBase:Mesh = new Mesh(circleVertices.clone(), circleIndices.clone());
			if (isHorizontal)
			{
				joystickBase.scaleY = 0.8;
			}
			analogStick = new Sprite();
			var analogStickMesh:Mesh = new Mesh(circleVertices.clone(), circleIndices.clone());
			analogStickMesh.color = joystickBase.color = Color.WHITE;
			analogStickMesh.alpha = joystickBase.alpha = 0.3;
			analogStick.addChild(analogStickMesh);
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
			return _radius;
		}
		
		
		override public function hitTest(localPoint:Point):DisplayObject 
		{
			if (!visible || !touchable || !hitTestMask(localPoint)) return null;
			if ((localPoint.x - analogStick.x) * (localPoint.x - analogStick.x) + (localPoint.y - analogStick.y) * (localPoint.y - analogStick.y) < touchRadiusSqr)
			{
				return this;
			}
			return null;
		}
		
		public function set radios(value:Number):void
		{
			_radius = value;
			touchRadiusSqr = Math.pow(_radius + extraTouchRadius, 2);
			width = (width / height) * _radius * 2;
			height = _radius * 2;
			pivotX = pivotY = _radius;
			var circle:Polygon = Polygon.createCircle(0, 0, _radius, 13);
			circleVertices = new VertexData(null, circle.numVertices);
			circle.copyToVertexData(circleVertices);
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