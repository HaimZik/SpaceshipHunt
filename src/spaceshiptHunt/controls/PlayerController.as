package spaceshiptHunt.controls
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import flash.display.StageDisplayState;
	import flash.events.MouseEvent;
	import flash.ui.Keyboard;
	import input.Key;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import nape.geom.Vec2;
	import spaceshiptHunt.entities.Player;
	import spaceshiptHunt.utils.MathUtilities;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchPhase;
	import starling.utils.MathUtil;
	import starling.utils.SystemUtil;
	
	public class PlayerController
	{
		
		//keyboardSetup
		protected static var upKey:uint = Keyboard.W;
		protected static var downKey:uint = Keyboard.S;
		protected static var rightKey:uint = Keyboard.D;
		protected static var leftKey:uint = Keyboard.A;
		protected static var moveAimForwardKey:uint = Keyboard.UP;
		protected static var moveAimBackwardKey:uint = Keyboard.DOWN;
		protected static var rotateAimRightKey:uint = Keyboard.RIGHT;
		protected static var rotateAimLeftKey:uint = Keyboard.LEFT;
		protected static var fireKey:uint = Keyboard.SPACE;
		protected static var alternativeFireKey:uint = Keyboard.Z;
		
		protected var leftAnalogStick:TouchJoystick;
		protected var rightJoystick:TouchJoystick;
		protected var crossTarget:Image;
		protected var minCrossTargetDistance:Number;
		protected var maxCrossTargetDistance:Number;
		protected var rightStickAxis:Vec2 = new Vec2();
		protected var lastDirectionChange:Number;
		protected var turningSpeedRatio:Number = 120.0;
		protected var aimAngularAcceleration:Number;
		protected var aimFriction:Number;
		protected const DEFAULT_AIM_FRICTION:Number = 0.2;
		protected const TOUCH_AIM_FRICTION:Number = 0.65;
		protected const RIGHT_JOYSTICK_TOUCH_AIM_FRICTION:Number = 0.3;
		protected const TOUCH_AIM_ANGULAR_ACCELERATION:Number = 0.050;
		protected const DEFAULT_AIM_ANGULAR_ACCELERATION:Number = 0.028;
		protected var lockDirectionDelay:Number = 1.5;
		protected var _player:Player;
		protected var xboxController:Xbox360Controller;
		
		public function PlayerController(playerToControl:Player, leftJoystick:TouchJoystick, rightJoystick:TouchJoystick, crossTarget:Image)
		{
			this.crossTarget = crossTarget;
			this.leftAnalogStick = leftJoystick;
			this.rightJoystick = rightJoystick;
			player = playerToControl;
			crossTarget.alignPivot();
			minCrossTargetDistance = 300.0;
			maxCrossTargetDistance = 400.0;
			crossTarget.x = player.body.position.x;
			crossTarget.y = player.body.position.y - minCrossTargetDistance;
			Key.addKeyUpCallback(fireKey, player.stopShooting);
			Key.addKeyUpCallback(alternativeFireKey, player.stopShooting);
		}
		
		public function get player():Player
		{
			return _player;
		}
		
		public function set player(value:Player):void
		{
			if (_player)
			{
				_player.graphics.removeEventListener(Event.REMOVED, onPlayerDeath);
			}
			_player = value;
			if (_player)
			{
				_player.graphics.addEventListener(Event.REMOVED, onPlayerDeath);
			}
		}
		
		public function update():void
		{
			if (SystemUtil.isDesktop)
			{
				handleKeyboardInput();
			}
			if (player.impulse.lsq() == 0)
			{
				handleJoystickInput();
			}
			handleCrossTargetControls();
			if (Math.abs(player.impulse.x) > 0.5 || Math.abs(rightStickAxis.x) > 0.2)
			{
				lastDirectionChange = Starling.juggler.elapsedTime;
			}
		}
		
		public function onFocusReturn():void
		{
			if (!(SystemUtil.isDesktop && (Key.isDown(fireKey) || Key.isDown(alternativeFireKey))) &&!(xboxController && xboxController.rt.held))
			{
				if (player)
				{
					player.stopShooting();
				}
			}
		}
		
		private function handleJoystickInput():void
		{
			if (ControllerInput.hasRemovedController() && ControllerInput.getRemovedController() == xboxController)
			{
				xboxController = null;
			}
			var xAxis:Number = leftAnalogStick.xAxis;
			var yAxis:Number = leftAnalogStick.yAxis;
			if (Math.abs(rightJoystick.xAxis) != 0)
			{
				rightStickAxis.x += rightJoystick.xAxis;
				aimFriction = RIGHT_JOYSTICK_TOUCH_AIM_FRICTION;
				aimAngularAcceleration = DEFAULT_AIM_ANGULAR_ACCELERATION;
			}
			if (xboxController)
			{
				if (xAxis == 0 && yAxis == 0)
				{
					xAxis = xboxController.leftStick.x;
					yAxis = -xboxController.leftStick.y;
					if (Math.abs(xAxis) < 0.1)
					{
						xAxis = 0;
					}
					if (Math.abs(yAxis) < 0.1)
					{
						yAxis = 0;
					}
					var rightStickX:Number = xboxController.rightStick.x;
					if (Math.abs(rightStickX) > 0.1)
					{
						rightStickAxis.x += rightStickX;
						aimFriction = DEFAULT_AIM_FRICTION;
						aimAngularAcceleration = DEFAULT_AIM_ANGULAR_ACCELERATION;
					}
					if (xboxController.rt.held)
					{
						player.startShooting();
					}
					else if (xboxController.rt.released)
					{
						player.stopShooting();
					}
				}
			}
			else if (ControllerInput.hasReadyController())
			{
				xboxController = ControllerInput.getReadyController() as Xbox360Controller;
			}
			if (xAxis != 0)
			{
				var easeOutAmount:Number = 2.0;
				xAxis = xAxis / Math.abs(xAxis) * Math.pow(Math.abs(xAxis), easeOutAmount);
			}
			player.impulse.x = xAxis;
			player.impulse.y = yAxis;
		}
		
		protected function onPlayerDeath(e:Event):void
		{
			//	player = null;
		}
		
		protected function handleCrossTargetControls():void
		{
			var crossTargetOffset:Vec2 = Vec2.get(crossTarget.x, crossTarget.y).subeq(player.body.position);
			if (Math.abs(rightStickAxis.x) > 0.01)
			{
				crossTargetOffset.angle += rightStickAxis.x * aimAngularAcceleration;
				//if (Math.abs(rightStickAxis.x) > 0.05) //!SystemUtil.isDesktop)
				//{
				rightStickAxis.x = rightStickAxis.x * aimFriction;
					//}
					//else
					//{
					//rightStickAxis.x = 0;
					//}
			}
			else
			{
				rightStickAxis.x = 0;
			}
			MathUtilities.clampVector(crossTargetOffset, minCrossTargetDistance, maxCrossTargetDistance);
			var angleDiff:Number = MathUtilities.angleDifference(crossTargetOffset.angle + Math.PI / 2, player.body.rotation);
			var timeSinceLastDirectionChange:Number = Starling.juggler.elapsedTime - lastDirectionChange;
			if (timeSinceLastDirectionChange > lockDirectionDelay)
			{
				crossTargetOffset.rotate(-angleDiff / 6.0);
			}
			else if (Math.abs(angleDiff) > 0.2)
			{
				player.impulse.y /= 2.0;
			}
			crossTarget.x = crossTargetOffset.x + player.body.position.x;
			crossTarget.y = crossTargetOffset.y + player.body.position.y;
			player.rotateTowards(crossTargetOffset.angle);
			crossTargetOffset.dispose();
		}
		
		private function handleKeyboardInput():void
		{
			if (Key.isDown(fireKey) || Key.isDown(alternativeFireKey))
			{
				player.startShooting();
			}
			// movement
			if (Key.isDown(upKey))
			{
				player.impulse.y = -1.0;
			}
			else if (Key.isDown(downKey))
			{
				player.impulse.y = 1.0;
			}
			if (Key.isDown(leftKey))
			{
				player.impulse.x = -1.0;
			}
			else if (Key.isDown(rightKey))
			{
				player.impulse.x = 1.0;
			}
			//moving aim
			if (Key.isDown(rotateAimLeftKey))
			{
				aimFriction = DEFAULT_AIM_FRICTION;
				aimAngularAcceleration = DEFAULT_AIM_ANGULAR_ACCELERATION;
				rightStickAxis.x += -1.0;
			}
			else if (Key.isDown(rotateAimRightKey))
			{
				aimFriction = DEFAULT_AIM_FRICTION;
				aimAngularAcceleration = DEFAULT_AIM_ANGULAR_ACCELERATION;
				rightStickAxis.x += 1.0;
			}
		}
		
		public function handleGameAreaTouch(touch:Touch):void
		{
			if (touch.phase == TouchPhase.MOVED && (!SystemUtil.isDesktop || Starling.current.nativeStage.displayState == StageDisplayState.NORMAL))
			{
				onSwipe(touch.globalX - touch.previousGlobalX, touch.previousGlobalY - touch.globalY);
			}
		}
		
		public function onSwipe(swipeVelocityX:Number, swipeVelocityY:Number):void
		{
			if (swipeVelocityX != 0)
			{
				aimFriction = TOUCH_AIM_FRICTION;
				aimAngularAcceleration = TOUCH_AIM_ANGULAR_ACCELERATION;
				var easeOutAmount:Number = 2;
				swipeVelocityX = swipeVelocityX / Math.abs(swipeVelocityX) * Math.pow(Math.abs(swipeVelocityX), easeOutAmount);
				rightStickAxis.x += swipeVelocityX / turningSpeedRatio;
				rightStickAxis.x = MathUtil.clamp(rightStickAxis.x, -1.0, 1.0);
			}
		}
		
		public function onMouseMove(e:MouseEvent):void
		{
			onSwipe(e.movementX, -e.movementY);
		}
	
	}

}