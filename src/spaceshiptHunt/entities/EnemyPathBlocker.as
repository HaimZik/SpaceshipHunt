package spaceshiptHunt.entities
{
	import nape.geom.Vec2;
	import nape.phys.Body;
	import spaceshiptHunt.entities.Enemy;
	
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
			maxAttackRange = minAttackRange * 1.5;
			attackTriggerRange = minAttackRange * 3;
			firingRate = 0.4;
			aimAccuracy = Math.PI / 4.0;
		}
		
		override protected function decideNextAction():void
		{
			super.decideNextAction();
			if (body.space.timeStamp - pathCheckTime > pathUpdateInterval)
			{
				currentAction = goToPlayerPath;
			}
		}
		
		protected function aimToPlayer():void
		{
			var rotaDiff:Number = rotationDiffrenceToPoint(Player.current.body.position);
			body.applyAngularImpulse(maxAngularAcceleration * rotaDiff);
			if (Math.abs(rotaDiff) < aimAccuracy/2)
			{
				currentAction = attackPlayer;
			}
		}
		
		protected function attackPlayer():void
		{
			if (isPlayerInRange(maxAttackRange))
			{
				if (Math.abs(rotationDiffrenceToPoint(Player.current.body.position)) < aimAccuracy)
				{
					startShooting();
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
		
		protected function goToPlayerPath():void
		{
			if (isPlayerInRange(minAttackRange))
			{
				currentAction = aimToPlayer;
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
				if (isPlayerInRange(minAttackRange))
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