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
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.utils.MathUtil;
	
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
			minCrossTargetDistance = 200;
			var crossTargetOffset:Vec2 = Vec2.get(0, -minCrossTargetDistance);
			var crossTargetPos:Vec2 = crossTargetOffset.add(player.body.position, true);
			crossTarget.x = crossTargetPos.x;
			crossTarget.y = crossTargetPos.y;
			crossTargetPos.dispose();
			Key.addKeyUpCallback(fireKey, player.stopShooting);
			Key.addKeyUpCallback(alternativeFireKey, player.stopShooting);
		}
		
		public function update():void
		{
			if (CONFIG::mobile == false)
			{
				handleKeyboardInput();
			}
			handleJoystickInput();
			var aimVector:Vec2 = Vec2.weak(crossTarget.x, crossTarget.y).subeq(player.body.position);
			if (aimVector.lsq() < minCrossTargetDistance*minCrossTargetDistance)
			{
				var crossTargetOffset:Vec2 = Vec2.get(crossTarget.x, crossTarget.y).subeq(player.body.position);
				crossTargetOffset.length = minCrossTargetDistance;
				var crossTargetPos:Vec2 = crossTargetOffset.add(player.body.position, true);
				crossTarget.x = crossTargetPos.x;
				crossTarget.y = crossTargetPos.y;
				crossTargetOffset.dispose();
				crossTargetPos.dispose();
			}
			player.rotateTowards(MathUtil.normalizeAngle(aimVector.angle));
		}
		
		public function get player():Player
		{
			return _player;
		}
		
		public function set player(value:Player):void
		{
			_player = value;
		}
		
		private function handleKeyboardInput():void
		{
			if (Key.isDown(fireKey) || Key.isDown(alternativeFireKey))
			{
				player.startShooting();
			}
			if (Key.isDown(upKey))
			{
				player.leftImpulse.y = player.rightImpulse.y = -player.maxAcceleration;
				if (Key.isDown(leftKey))
				{
					player.leftImpulse.y -= player.maxAcceleration;
					player.rightImpulse.y += player.maxTurningAcceleration / 3;
				}
				else if (Key.isDown(rightKey))
				{
					player.leftImpulse.y += player.maxTurningAcceleration / 3;
					player.rightImpulse.y -= player.maxAcceleration;
				}
			}
			else if (Key.isDown(downKey))
			{
				player.leftImpulse.y = player.rightImpulse.y = player.maxAcceleration;
				if (Key.isDown(leftKey))
				{
					player.leftImpulse.y -= player.maxAcceleration;
					player.rightImpulse.y += player.maxTurningAcceleration / 3;
				}
				else if (Key.isDown(rightKey))
				{
					player.leftImpulse.y += player.maxTurningAcceleration / 3;
					player.rightImpulse.y -= player.maxAcceleration;
				}
			}
			else if (Key.isDown(leftKey))
			{
				player.leftImpulse.y -= player.maxAcceleration;
				player.rightImpulse.y += player.maxTurningAcceleration;
			}
			else if (Key.isDown(rightKey))
			{
				player.leftImpulse.y += player.maxTurningAcceleration;
				player.rightImpulse.y -= player.maxAcceleration;
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
			if (xboxController)
			{
				if (Math.abs(xAxis) + Math.abs(yAxis) == 0)
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
			if (Math.abs(xAxis) + Math.abs(yAxis) > 0)
			{
				if (xAxis != 0)
				{
					var easeOutAmount:Number = 0.9;
					xAxis = xAxis / Math.abs(xAxis) * Math.pow(Math.abs(xAxis), easeOutAmount);
				}
					//turningSpeed = player.maxTurningAcceleration * xAxis;
					//player.leftImpulse.y = player.maxAcceleration * yAxis + turningSpeed;
					//player.rightImpulse.y = player.maxAcceleration * yAxis - turningSpeed;
			}
			player.impulse.x = xAxis;
			player.impulse.y = yAxis;
		}
	
	}

}