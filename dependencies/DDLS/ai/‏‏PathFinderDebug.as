package DDLS.ai
{
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSMesh;
	import DDLS.data.HitTestable;
	import DDLS.data.math.DDLSGeom2D;
	
	public class PathFinder
	{
		public var hitTester:HitTestable;
		private var _mesh:DDLSMesh;
		private var _astar:AStar;
		private var _funnel:Funnel;
		private var _entity:DDLSEntityAI;
		private var _radius:Number;
		
		private var __listFaces:Vector.<DDLSFace>;
		private var __listEdges:Vector.<DDLSEdge>;
		
		public function PathFinder(hitTester:HitTestable)
		{
			_astar = new AStar();
			_funnel = new Funnel();
			this.hitTester = hitTester;
			__listFaces = new Vector.<DDLSFace>();
			__listEdges = new Vector.<DDLSEdge>();
		}
		
		public function dispose():void
		{
			_mesh = null;
			_astar.dispose();
			_astar = null;
			_funnel.dispose();
			_funnel = null;
			__listEdges = null;
			__listFaces = null;
		}
		
		public function get entity():DDLSEntityAI
		{
			return _entity;
		}
		
		public function set entity(value:DDLSEntityAI):void
		{
			_entity = value;
		}
		
		public function get mesh():DDLSMesh
		{
			return _mesh;
		}
		
		public function set mesh(value:DDLSMesh):void
		{
			_mesh = value;
			_astar.mesh = _mesh;
		}
		
		public function findPath(toX:Number, toY:Number, resultPath:Vector.<Number>):void
		{
			if (!_mesh)
				throw new Error("Mesh missing");
			if (!_entity)
			{
				throw new Error("Entity missing");
			}
			//_entity.radius = 0;
			_astar.radius = _entity.radius;
			_funnel.radius = _entity.radius;
			resultPath.length = 0;
			__listFaces.length = 0;
			__listEdges.length = 0;
			if (DDLSGeom2D.isCircleIntersectingAnyConstraint(toX, toY, _entity.radius, _mesh))
			{
				return;
			}
			var constraintCircleRadius:Number = 25; //32
			var approximateObjectRadius:Number = _entity.radius + constraintCircleRadius;
			var offsetLength:Number = approximateObjectRadius * 2 + 1.0;
			var forwardDirectionX:Number = _entity.dirNormX * offsetLength;
			var forwardDirectionY:Number = _entity.dirNormY * offsetLength;
			//if (_entity.approximateObject && hitTester)
			//{
				//if (!tryFindPathOrthogonal(forwardDirectionX, forwardDirectionY, toX, toY, resultPath))
				//{
					//trace("not Orthogonal");
				////	tryFindPathDiagonal(offsetLength, toX, toY, resultPath);
				//} else
				//{
					//trace("Orthogonal");
				//}
			//}
		//	else
			{
				tryFindPath(1,0,100,100, resultPath); 
			//	tryFindPath(0, 0, toX, toY, resultPath)
			}
		}
		
		protected function tryFindPathDiagonal(offsetLength:Number, toX:Number, toY:Number, resultPath:Vector.<Number>):void
		{
			var angle:Number = Math.atan2(_entity.dirNormY, _entity.dirNormX) + Math.PI / 4;
			var directionX:Number = Math.cos(angle);
			var directionY:Number = Math.sin(angle);
			tryFindPathOrthogonal(directionX * offsetLength, directionY * offsetLength, toX, toY, resultPath)
		}
		
		protected function tryFindPathOrthogonal(forwardDirectionX:Number, forwardDirectionY:Number, toX:Number, toY:Number, resultPath:Vector.<Number>):Boolean
		{
			var dir:String = "forward";
		//	if (!tryFindPath(forwardDirectionX, forwardDirectionY, toX, toY, resultPath)) //forward
			{
				dir = "right";
			//	if (!tryFindPath(forwardDirectionY, -forwardDirectionX, toX, toY, resultPath)) //right
				{
				dir = "left";
		//			if (!tryFindPath(-forwardDirectionY, forwardDirectionX, toX, toY, resultPath)) //left
					{
						//	trace("not left");
						//	return false;
						trace("behind");
						return tryFindPath(-forwardDirectionX*0, -forwardDirectionY*0, toX+1200, toY-400, resultPath); //behind
					}
				}
			}
			trace(dir);
			return true;
		}
		
		protected function tryFindPath(directionX:Number, directionY:Number, toX:Number, toY:Number, resultPath:Vector.<Number>):Boolean
		{
		//	if (!isPathBlocked(directionX, directionY))
			{
				_astar.findPath(_entity.x-100, _entity.y-100,_entity.x,_entity.y+300, __listFaces, __listEdges);
				if (__listFaces.length != 0)
				{
					_funnel.findPath(_entity.x-100, _entity.y-100,_entity.x,_entity.y+300, __listFaces, __listEdges, resultPath);
					return true;
				}
			}
			return false;
		}
		
		private function isPathBlocked(directionX:Number, directionY:Number):Boolean
		{
			//if (!(directionX == 0 && directionY == 0) && hitTester.hitTestLine(_entity.x, _entity.y, directionX, directionY))
			//{
				//trace("hit");
				//return true;
			//}
			//trace("not hit");
			return DDLSGeom2D.isCircleIntersectingAnyConstraint(_entity.x + directionX, _entity.y + directionY, _entity.radius, _mesh);
		}
		
		public function findPathFrom(fromX:Number, fromY:Number, toX:Number, toY:Number, resultPath:Vector.<Number>):void
		{
			resultPath.length = 0;
			__listFaces.length = 0;
			__listEdges.length = 0;
			_astar.findPath(fromX, fromY, toX, toY, __listFaces, __listEdges);
			if (__listFaces.length != 0)
			{
				_funnel.findPath(fromX, fromY, toX, toY, __listFaces, __listEdges, resultPath);
			}
		}
	
	}
}