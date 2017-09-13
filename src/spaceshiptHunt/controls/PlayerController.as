package spaceshiptHunt.controls
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import flash.ui.Keyboard;
	import input.Key;
	import io.arkeus.ouya.ControllerInput;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import nape.geom.Vec2;
	import spaceshiptHunt.entities.Player;
	import spaceshiptHunt.utils.MathUtilities;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.events.Event;
	
	public class PlayerController
	{
		
		//keyboardSetup
		protected static var alternativeFireKey:uint = Keyboard.SPACE;
		protected static var fireKey:uint = Keyboard.Z;
		protected static var upKey:uint = Keyboard.UP;
		protected static var downKey:uint = Keyboard.DOWN;
		protected static var rightKey:uint = Keyboard.RIGHT;
		protected static var leftKey:uint = Keyboard.LEFT;
		
		protected var lastDirectionChange:Number;
		protected var analogStick:Mesh;
		protected var crossTarget:Image;
		protected var minCrossTargetDistance:Number;
		protected var maxCrossTargetDistance:Number;
		protected var rightStickAxis:Vec2 = new Vec2();
		private var _player:Player;
		private var xboxController:Xbox360Controller;
		
		CONFIG::debug
		{
			fireKey = Keyboard.NUMPAD_ADD;
			upKey = Keyboard.W;
			downKey = Keyboard.S;
			rightKey = Keyboard.D;
			leftKey = Keyboard.A;
		}
		
		public function PlayerController(playerToControl:Player, analogStick:Mesh, crossTarget:Image)
		{
			this.crossTarget = crossTarget;
			this.analogStick = analogStick;
			player = playerToControl;
			crossTarget.alignPivot();
			minCrossTargetDistance = 200.0;
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
			if (CONFIG::mobile == false)
			{
				handleKeyboardInput();
			}
			if (player.impulse.lsq() == 0)
			{
				handleJoystickInput();
			}
			handleCrossTargetControls();
		}
		
		public function onFocusReturn():void
		{
			if (xboxController)
			{
				if (!xboxController.rt.held)
				{
					if (player)
					{
						player.stopShooting();
					}
				}
			}
		}
		
		private function handleJoystickInput():void
		{
			if (ControllerInput.hasRemovedController() && ControllerInput.getRemovedController() == xboxController)
			{
				xboxController = null;
			}
			var xAxis:Number;
			var yAxis:Number;
			var turningSpeed:Number;
			xAxis = Math.min(1, analogStick.x / 160);
			yAxis = Math.min(1, analogStick.y / 160);
			if (xboxController && Math.abs(xAxis) + Math.abs(yAxis) == 0)
			{
				xAxis = xboxController.leftStick.x;
				yAxis = -xboxController.leftStick.y;
				if (Math.abs(xAxis) + Math.abs(yAxis) < 0.1)
				{
					xAxis = 0;
					yAxis = 0;
				}
				if (xboxController.rt.held)
				{
					player.startShooting();
				}
				else if (xboxController.rt.released)
				{
					player.stopShooting();
				}
				rightStickAxis.setxy(xboxController.rightStick.x, xboxController.rightStick.y);
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
			player = null;
		}
		
		protected function handleCrossTargetControls():void
		{
			var crossTargetOffset:Vec2 = Vec2.get(crossTarget.x, crossTarget.y).subeq(player.body.position);
			if (rightStickAxis.lsq() > 0.1)
			{
				var aimAngleSpeed:Number = 0.05;
				var aimDistanceSpeed:Number = 20.0;
				crossTargetOffset.length += rightStickAxis.y * aimDistanceSpeed;
				crossTargetOffset.angle += rightStickAxis.x * aimAngleSpeed;
				rightStickAxis.setxy(0, 0);
			}
			else if (player.body.velocity.lsq() > 0 && Math.abs(player.body.angularVel) < 0.1)
			{
				if (MathUtilities.angleDifferenceAbs(player.body.velocity.angle + Math.PI / 2, player.body.rotation) < 0.1)
				{
					var angleDiff:Number = MathUtilities.angleDifference(crossTargetOffset.angle + Math.PI / 2, player.body.rotation);
					if (Math.abs(angleDiff) < 0.2)
					{
						crossTargetOffset.rotate(-angleDiff);
					}
				}
			}
			MathUtilities.clampVector(crossTargetOffset, minCrossTargetDistance, maxCrossTargetDistance);
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
			if (Key.isDown(upKey))
			{
				player.impulse.y = -1.0;
				if (Key.isDown(leftKey))
				{
					player.impulse.x = -1.0;
				}
				else if (Key.isDown(rightKey))
				{
					player.impulse.x = 1.0;
				}
			}
			else if (Key.isDown(downKey))
			{
				player.impulse.y = 1.0;
				if (Key.isDown(leftKey))
				{
					player.impulse.x = -1.0;
				}
				else if (Key.isDown(rightKey))
				{
					player.impulse.x = 1.0;
				}
			}
			else if (Key.isDown(leftKey))
			{
				player.impulse.x = -1.0;
			}
			else if (Key.isDown(rightKey))
			{
				player.impulse.x = 1.0;
			}
		}
	
	}

}