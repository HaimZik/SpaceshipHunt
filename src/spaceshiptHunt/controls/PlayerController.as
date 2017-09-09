package spaceshiptHunt.controls
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import flash.ui.Keyboard;
	import input.Key;
	import io.arkeus.ouya.ControllerInput;
	import nape.geom.Vec2;
	import spaceshiptHunt.entities.Player;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import spaceshiptHunt.utils.MathUtilities;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.events.Event;
	import starling.display.DisplayObject;
	
	public class PlayerController
	{
		
		//keyboardSetup
		protected static var alternativeFireKey:uint = Keyboard.SPACE;
		protected static var fireKey:uint = Keyboard.Z;
		protected static var upKey:uint = Keyboard.UP;
		protected static var downKey:uint = Keyboard.DOWN;
		protected static var rightKey:uint = Keyboard.RIGHT;
		protected static var leftKey:uint = Keyboard.LEFT;
		
		protected var analogStick:Mesh;
		protected var crossTarget:Image;
		protected var minCrossTargetDistance:Number;
		protected var maxCrossTargetDistance:Number;
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
			var aimVector:Vec2 = Vec2.get(crossTarget.x, crossTarget.y).subeq(player.body.position);
			var crossTargetOffset:Vec2 = Vec2.get(crossTarget.x, crossTarget.y).subeq(player.body.position);
			if (MathUtilities.angleDifferenceAbs(player.body.velocity.angle - Math.PI / 2, player.body.rotation) < 0.1)
			{
				if (Math.abs(angleDiff) < 0.2)
				{
					crossTargetOffset.rotate(angleDiff);
				}
			//	trace(angleDiff);
			}
			if (aimVector.lsq() < minCrossTargetDistance * minCrossTargetDistance)
			{
				crossTargetOffset.length = minCrossTargetDistance;
				crossTarget.x = crossTargetOffset.x + player.body.position.x;
				crossTarget.y = crossTargetOffset.y + player.body.position.y;
				crossTargetOffset.dispose();
			}
			else if (aimVector.lsq() > maxCrossTargetDistance * maxCrossTargetDistance)
			{
				crossTargetOffset.length = maxCrossTargetDistance;
				crossTarget.x = crossTargetOffset.x + player.body.position.x;
				crossTarget.y = crossTargetOffset.y + player.body.position.y;
				crossTargetOffset.dispose();
			}
			player.rotateTowards(aimVector.angle);
			aimVector.dispose();
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
		
		protected function onPlayerDeath(e:Event):void
		{
			player = null;
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
				if (Math.abs(xboxController.rightStick.x) + Math.abs(xboxController.rightStick.y) > 0.1)
				{
					var aimAngleSpeed:Number = 0.05;
					var aimDistanceSpeed:Number = 20.0;
					var crossTargetOffset:Vec2 = Vec2.get(crossTarget.x, crossTarget.y).subeq(player.body.position);
					crossTargetOffset.length += xboxController.rightStick.y * aimDistanceSpeed;
					crossTargetOffset.angle += xboxController.rightStick.x * aimAngleSpeed;
					var crossTargetPos:Vec2 = crossTargetOffset.add(player.body.position, true);
					crossTarget.x = crossTargetPos.x;
					crossTarget.y = crossTargetPos.y;
					crossTargetOffset.dispose();
					crossTargetPos.dispose();
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
	
	}

}