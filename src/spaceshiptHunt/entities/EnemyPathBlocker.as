package spaceshiptHunt.entities
{
	import nape.geom.RayResult;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import spaceshiptHunt.entities.Enemy;
	import spaceshiptHunt.level.Environment;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.filters.GlowFilter;
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class EnemyPathBlocker extends Enemy
	{
		protected var minAttackRange:Number;
		protected var maxAttackRange:Number;
		protected var attackTriggerRange:Number;
		protected var aimAccuracy:Number;
		protected var minDisatnceFromWall:Number;
		protected var lastBackwardBlockedCheck:Number;
		protected var _isBackwardBlocked:Boolean = false;
		protected var dodgeDirX:Number = 1;
		protected var backwardBlockedCheckRate:Number;
		
		public function EnemyPathBlocker(position:Vec2)
		{
			super(position);
			weaponsPlacement["fireCannon"] = Vec2.get(8, -37);
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			this.gunType = "fireCannon";
			minAttackRange = 500.0;
			minDisatnceFromWall = 100.0;
			maxAttackRange = minAttackRange * 1.3;
			attackTriggerRange = minAttackRange * 3;
			firingRate = 0.4;
			aimAccuracy = Math.PI / 8; //4.0;
			lastBackwardBlockedCheck = Starling.juggler.elapsedTime;
			backwardBlockedCheckRate = 0.8;
		}
		
		override protected function decideNextAction():void
		{
			super.decideNextAction();
			if (timeStamp - pathCheckTime > pathUpdateInterval)
			{
				currentAction = goToPlayerPath;
			}
		}
		
		protected function aimToPlayer():void
		{
			var predictedPosition:Vec2 = playerPredictedPosition();
			var rotaDiff:Number = rotationDiffrenceToPoint(predictedPosition);
			predictedPosition.dispose();
			body.applyAngularImpulse(maxAngularAcceleration * rotaDiff);
			if (bulletsLeft > 0)
			{
				dodge(0.3);
				if (Math.abs(rotaDiff) < aimAccuracy / 2)
				{
					currentAction = attackPlayer;
				}
				if (!isPlayerInRange(minDisatnceFromWall * 2) && isBackwardBlocked()) //isPathBlocked())
				{
					currentAction = goToPlayerPath;
				}
			}
			else
			{
				dodge();
				if (Starling.juggler.elapsedTime - lastReloadTime > reloadTime)
				{
					bulletsLeft += maxBullets;
				}
			}
		}
		
		protected function dodge(speed:Number = 1):void
		{
			var dirVec:Vec2 = Vec2.fromPolar(pathfindingAgent.radius, body.rotation * dodgeDirX);
			tempRay.origin.set(body.position).addeq(dirVec);
			tempRay.direction.set(dirVec);
			tempRay.maxDistance = 175;
			dirVec.dispose();
			var rayResult:RayResult = body.space.rayCast(tempRay, false);
			if (rayResult == null)
			{
				impulse.x = speed * dodgeDirX;
			}
			else
			{
				dodgeDirX *= -1;
				rayResult.dispose();
			}
		}
		
		protected function playerPredictedPosition():Vec2
		{
			if (Player.current.body.velocity.lsq() > 20000.0)
			{
				return Player.current.body.position.add(Player.current.body.velocity.mul(0.2, true));
			}
			return Player.current.body.position.add(Player.current.body.velocity.mul(0.1, true));
		}
		
		protected function attackPlayer():void
		{
			if (isPlayerInRange(maxAttackRange) && !(!isPlayerInRange(minDisatnceFromWall * 2) && isBackwardBlocked()))
			{
				var predictedPosition:Vec2 = playerPredictedPosition();
				var angleToPlayer:Number = Math.abs(rotationDiffrenceToPoint(predictedPosition));
				predictedPosition.dispose();
				if (bulletsLeft > 0 && angleToPlayer < aimAccuracy)
				{
					startShooting();
					if (angleToPlayer > aimAccuracy)
					{
						aimToPlayer();
					}
				}
				else
				{
					stopShooting();
					currentAction = aimToPlayer;
				}
			}
			else
			{
				stopShooting();
				if (isPlayerInRange(attackTriggerRange))
				{
					goToEntity(Player.current.pathfindingAgent);
				}
				else
				{
					currentAction = decideNextAction;
				}
			}
		
		}
		
		protected function isBackwardBlocked():Boolean
		{
			if (Starling.juggler.elapsedTime - lastBackwardBlockedCheck < backwardBlockedCheckRate)
			{
				return _isBackwardBlocked;
			}
			lastBackwardBlockedCheck = Starling.juggler.elapsedTime;
			tempRay.origin = this.body.position;
			var backwardDirVector:Vec2 = Vec2.fromPolar(1, body.rotation);
			backwardDirVector.rotate(Math.PI / 2);
			tempRay.direction.setxy(backwardDirVector.x, backwardDirVector.y);
			backwardDirVector.dispose();
			tempRay.maxDistance = minDisatnceFromWall;
			var rayResult:RayResult = body.space.rayCast(tempRay, false, Environment.STATIC_OBSTACLES_FILTER);
			_isBackwardBlocked = rayResult != null;
			if (_isBackwardBlocked)
			{
				rayResult.dispose();
			}
			return _isBackwardBlocked;
		}
		
		protected function goToPlayerPath():void
		{
			if (isPlayerInRange(minAttackRange))
			{
				if (isBackwardBlocked())
				{
					goToEntity(Player.current.pathfindingAgent);
				}
				else
				{
					currentAction = aimToPlayer;
				}
			}
			else
			{
				var playerPredictedPath:Vector.<Number> = PreyEnemy.current.playerPredictedPath;
				if (playerPredictedPath.length > 0)
				{
					var closestPoint:Vec2 = closestPointFromPath(playerPredictedPath);
					if (!(closestPoint.x == 0 && closestPoint.y == 0))
					{
						goTo(closestPoint.x, closestPoint.y);
					}
					else
					{
						currentAction = decideNextAction;
					}
					closestPoint.dispose();
				}
			}
		}
		
		override protected function followPath():void
		{
			if (!chasingTarget && isPlayerInRange(attackTriggerRange))
			{
				goToEntity(Player.current.pathfindingAgent);
			}
			else
			{
				if (isPlayerInRange(minAttackRange) && !(!isPlayerInRange(minDisatnceFromWall * 2) && isBackwardBlocked()))
				{
					currentAction = aimToPlayer;
					chasingTarget = null;
				}
				else
				{
					super.followPath();
				}
			}
		}
		
		protected function closestPointFromPath(path:Vector.<Number>):Vec2
		{
			var distanceToClosestPoint:Number = Number.MAX_VALUE;
			var i:int = 0;
			var lineStart:Vec2 = Vec2.get(path[i], path[++i]);
			var closestPoint:Vec2 = Vec2.get();
			var safeDistance:Number = pathfindingAgentSafeDistance * 2 + pathfindingAgent.radiusSquared + Player.current.pathfindingAgent.radiusSquared;
			for (; i < path.length - 2; )
			{
				var lineEnd:Vec2 = Vec2.get(path[++i], path[++i]);
				if (distanceSquaredFromPlayer(lineEnd) > safeDistance)
				{
					if (distanceSquaredFromPlayer(lineStart) > safeDistance)
					{
						var closestPointFromLine:Vec2 = findClosestPoint(lineStart, lineEnd);
						var distanceToPoint:Number = Vec2.distance(closestPointFromLine, body.position);
						if (distanceToPoint < distanceToClosestPoint && distanceSquaredFromPlayer(closestPointFromLine) > safeDistance)
						{
							distanceToClosestPoint = distanceToPoint;
							closestPoint.set(closestPointFromLine);
						}
						closestPointFromLine.dispose();
					}
					else
					{
						var safePos:Vec2 = lineStart.sub(lineEnd);
						safePos.length = distanceSquaredFromPlayer(lineStart);
						safePos.addeq(lineStart);
						closestPoint.set(findClosestPoint(safePos, lineEnd, true));
						lineStart.dispose();
						lineEnd.dispose();
						return closestPoint;
					}
				}
				else if (distanceSquaredFromPlayer(lineStart) > safeDistance)
				{
					var safePoint:Vec2 = lineStart.sub(lineEnd);
					safePoint.length = distanceSquaredFromPlayer(lineEnd);
					safePoint = lineEnd.sub(safePoint);
					closestPoint.set(findClosestPoint(lineStart, safePoint, true));
					lineStart.dispose();
					lineEnd.dispose();
					return closestPoint;
				}
				lineStart.dispose();
				lineStart = lineEnd;
			}
			lineStart.dispose();
			return closestPoint;
		}
		
		protected function distanceSquaredFromPlayer(pos:Vec2):Number
		{
			if (Enemy.enemiesSeePlayerCounter > 0)
			{
				return Vec2.dsq(Player.current.body.position, pos);
			}
			else
			{
				return Math.min(Vec2.dsq(lastSeenPlayerPos, pos), Vec2.dsq(Player.current.body.position, pos));
			}
		}
		
		protected function findClosestPoint(lineStart:Vec2, lineEnd:Vec2, weak:Boolean = false):Vec2
		{
			var closestPoint:Vec2 = Vec2.get(0, 0, weak);
			var line:Vec2 = lineEnd.sub(lineStart);
			var length:Number = line.length;
			line.muleq(1 / length);
			var startToCircle:Vec2 = Vec2.get(pathfindingAgent.x + body.velocity.x - lineStart.x, pathfindingAgent.y + body.velocity.y - lineStart.y);
			var lineDotCircle:Number = startToCircle.dot(line);
			if (lineDotCircle < 0)
			{
				closestPoint.set(lineStart);
			}
			else if (lineDotCircle > length)
			{
				closestPoint.set(lineEnd);
			}
			else
			{
				closestPoint.set(lineStart.sub(line.muleq(lineDotCircle), true));
			}
			line.dispose();
			startToCircle.dispose();
			return closestPoint;
		}
		
		protected function rotationDiffrenceToPoint(pos:Vec2):Number
		{
			var directionVector:Vec2 = pos.sub(body.position);
			var rotaDiff:Number = directionVector.angle + Math.PI / 2 - body.rotation;
			directionVector.dispose();
			if (Math.abs(rotaDiff) > Math.PI / 2)
			{
				//in order for the ship to rotate in the shorter angle
				rotaDiff -= (Math.abs(rotaDiff) / rotaDiff) * Math.PI * 2;
			}
			return rotaDiff;
		}
		
		protected function isPlayerInRange(range:Number):Boolean
		{
			return canViewPlayer && Vec2.dsq(Player.current.body.position, body.position) < range * range;
		}
	
	}

}