package DDLS.ai
{
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSMesh;
	import DDLS.data.DDLSVertex;
	import DDLS.data.PriorityQueue;
	import DDLS.data.math.DDLSGeom2D;
	import DDLS.data.math.DDLSPoint2D;
	import DDLS.iterators.IteratorFromFaceToInnerEdges;
	
	import flash.utils.Dictionary;
	
	public class DDLSAStar
	{
		
		private var _mesh:DDLSMesh;
		
		private var __closedFaces:Array;
		private var __openedFaces:Array;
		private var __entryEdges:Array = [];
		private var __entryX:Array = [];
		private var __entryY:Array = [];
		private var __scoreF:Array = [];
		private var __scoreG:Array = [];
		private var __scoreH:Array = [];
		private var __predecessor:Array = [];
		
		private var __iterEdge:IteratorFromFaceToInnerEdges;
		
		private var _radius:Number;
		private var _radiusSquared:Number;
		private var _diameter:Number;
		private var _diameterSquared:Number;
		
		private var priorityQueue:PriorityQueue;
		
		//helpers pool
		private var vFaceToCheck:Vector.<DDLSFace> = new Vector.<DDLSFace>();
		private var vFaceIsFromEdge:Vector.<DDLSEdge> = new Vector.<DDLSEdge>();
		
		public function DDLSAStar()
		{
			__iterEdge = new IteratorFromFaceToInnerEdges();
			priorityQueue = new PriorityQueue(__scoreF, DDLSFace.largestID);
			__closedFaces = new Array(500);
			__openedFaces = new Array(500);
			for (var i:int = 0; i < 500; i++)
			{
				__closedFaces[i] = null;
				__openedFaces[i] = null;
				__entryX[i] = 0;
				__entryY[i] = 0;
				__scoreG[i] = 0;
				__scoreH[i] = 0;
			}
		}
		
		public function dispose():void
		{
			_mesh = null;
			
			__closedFaces = null;
			priorityQueue = null;
			__openedFaces = null;
			__entryEdges = null;
			__entryX = null;
			__entryY = null;
			__scoreF = null;
			__scoreG = null;
			__scoreH = null;
			__predecessor = null;
		}
		
		public function get radius():Number
		{
			return _radius;
		}
		
		public function set radius(value:Number):void
		{
			_radius = value;
			_radiusSquared = _radius * _radius;
			_diameter = _radius * 2;
			_diameterSquared = _diameter * _diameter;
		}
		
		public function set mesh(value:DDLSMesh):void
		{
			_mesh = value;
		}
		
		public function findPath(fromX:Number, fromY:Number, toX:Number, toY:Number, resultListFaces:Vector.<DDLSFace>, resultListEdges:Vector.<DDLSEdge>):void
		{
			//trace("findPath");
			priorityQueue.reset(DDLSFace.largestID);
			var __fromFace:DDLSFace;
		    var __toFace:DDLSFace;
		    var __curFace:DDLSFace;
			var loc:Object;
			var locEdge:DDLSEdge;
			var locVertex:DDLSVertex;
			loc = DDLSGeom2D.locatePosition(fromX, fromY, _mesh);
			locVertex = loc as DDLSVertex;
			if (locVertex)
			{
				// vertex are always in constraint, so we abort
				return;
			}
			else if ((locEdge = loc as DDLSEdge))
			{
				// if the vertex lies on a constrained edge, we abort
				if (locEdge.isConstrained)
					return;
				
				__fromFace = locEdge.leftFace;
			}
			else
			{
				__fromFace = loc as DDLSFace;
			}
			//
			loc = DDLSGeom2D.locatePosition(toX, toY, _mesh);
			locVertex = loc as DDLSVertex
			if (locVertex)
			{
				if (locVertex.edge)
				{
					__toFace = locVertex.edge.leftFace;
				}
				else
				{
					trace("locVertex.edge was null");
					return;
				}
			}
			else if ((locEdge = loc as DDLSEdge))
				__toFace = locEdge.leftFace;
			else
				__toFace = loc as DDLSFace;
			
			/*__fromFace.colorDebug = 0xFF0000;
			   __toFace.colorDebug = 0xFF0000;
			   trace( "from face:", __fromFace );
			   trace( "to face:", __toFace );*/
			var toFaceId:int = __toFace.id;
			var fromFaceId:int = __fromFace.id;
			__entryEdges[fromFaceId] = null;
			__entryX[fromFaceId] = fromX;
			__entryY[fromFaceId] = fromY;
			__scoreG[fromFaceId] = 0;
			__scoreH[fromFaceId] = Math.sqrt((toX - fromX) * (toX - fromX) + (toY - fromY) * (toY - fromY));
			__scoreF[fromFaceId] = __scoreH[fromFaceId] + __scoreG[fromFaceId];
			priorityQueue.insert(fromFaceId);
			
			var innerEdge:DDLSEdge;
			var neighbourFace:DDLSFace;
			var f:Number;
			var g:Number;
			var h:Number;
			var fromPointX:Number;
			var fromPointY:Number;
			var entryPointX:Number;
			var entryPointY:Number;
			var distancePointX:Number;
			var distancePointY:Number;
			while (true)
			{
				// no path found
				if (priorityQueue.length == 0)
				{
					//trace("DDLSAStar no path found");
					__curFace = null;
					break;
				}
				
				// we reached the target face
				var currentFaceID:int = priorityQueue.shiftHighestPriorityItem();
				if (currentFaceID == toFaceId)
				{
					break;
				}
				
				// we continue the search
				__curFace = DDLSFace.getFaceByID(currentFaceID);
				__iterEdge.fromFace = __curFace;
				while ((innerEdge = __iterEdge.next()) != null)
				{
					if (innerEdge.isConstrained)
						continue;
					
					neighbourFace = innerEdge.rightFace;
					var neighbourFaceId:int = neighbourFace.id;
					if (!__closedFaces[neighbourFaceId])
					{
						if (currentFaceID != fromFaceId && _radius > 0 && !isWalkableByRadius(__entryEdges[currentFaceID], __curFace, innerEdge))
						{
//							trace("- NOT WALKABLE -");
//							trace( "from", DDLSEdge(__entryEdges[__curFace]).originVertex.id, DDLSEdge(__entryEdges[__curFace]).destinationVertex.id );
//							trace( "to", innerEdge.originVertex.id, innerEdge.destinationVertex.id );
//							trace("----------------");
							continue;
						}
						fromPointX = __entryX[currentFaceID];
						fromPointY = __entryY[currentFaceID];
						entryPointX = (innerEdge.originVertex.pos.x + innerEdge.destinationVertex.pos.x) / 2;
						entryPointY = (innerEdge.originVertex.pos.y + innerEdge.destinationVertex.pos.y) / 2;
						distancePointX = entryPointX - toX;
						distancePointY = entryPointY - toY;
						h = Math.sqrt(distancePointX * distancePointX + distancePointY * distancePointY);
						distancePointX = fromPointX - entryPointX;
						distancePointY = fromPointY - entryPointY;
						g = __scoreG[currentFaceID] + Math.sqrt(distancePointX * distancePointX + distancePointY * distancePointY);
						f = h + g;
						if (!__openedFaces[neighbourFaceId])
						{
							__entryEdges[neighbourFaceId] = innerEdge;
							__entryX[neighbourFaceId] = entryPointX;
							__entryY[neighbourFaceId] = entryPointY;
							__scoreF[neighbourFaceId] = f;
							__scoreG[neighbourFaceId] = g;
							__scoreH[neighbourFaceId] = h;
							__predecessor[neighbourFaceId] = __curFace;
							priorityQueue.insert(neighbourFaceId);
							__openedFaces[neighbourFaceId] = true;
						}
						else if (__scoreF[neighbourFaceId] > f)
						{
							__entryEdges[neighbourFaceId] = innerEdge;
							__entryX[neighbourFaceId] = entryPointX;
							__entryY[neighbourFaceId] = entryPointY;
							__scoreF[neighbourFaceId] = f;
							__scoreG[neighbourFaceId] = g;
							__scoreH[neighbourFaceId] = h;
							__predecessor[neighbourFaceId] = __curFace;
							priorityQueue.decreaseHeuristics(neighbourFaceId);
						}
					}
				}
				__openedFaces[currentFaceID] = null;
				__closedFaces[currentFaceID] = true;
			}
			
			// if we didn't find a path
			if (!__curFace)
			{
				clearTemps();
				return;
			}
			// else we build the path
			resultListFaces.push(__curFace);
			//__curFace.colorDebug = 0x0000FF;
			while (__curFace != __fromFace)
			{
				resultListEdges.unshift(__entryEdges[__curFace.id]);
				//__entryEdges[__curFace].colorDebug = 0xFFFF00;
				//__entryEdges[__curFace].oppositeEdge.colorDebug = 0xFFFF00;
				__curFace = __predecessor[__curFace.id];
				//__curFace.colorDebug = 0x0000FF;
				resultListFaces.unshift(__curFace);
			}
			clearTemps();
		}
		
		// faces with low distance value are at the end of the array
		//private function sortingFaces(a:DDLSFace, b:DDLSFace):Number
		//{
		//if (__scoreF[a] == __scoreF[b])
		//return 0;
		//else if (__scoreF[a] < __scoreF[b])
		//return 1;
		//else
		//return -1;
		//}
		
		//private function sortfaces(startIndex:int, length:int):void
		//{
		//// This is a port of the C++ merge sort algorithm shown here:
		//// http://www.cprogramming.com/tutorial/computersciencetheory/mergesort.html
		//
		//if (length > 1)
		//{
		//var i:int;
		//var endIndex:int = startIndex + length;
		//var halfLength:int = length / 2;
		//var l:int = startIndex; // current position in the left subvector
		//var r:int = startIndex + halfLength; // current position in the right subvector
		//
		//// sort each subvector
		//sortfaces(startIndex, halfLength);
		//sortfaces(startIndex + halfLength, length - halfLength);
		//
		//// merge the vectors, using the buffer vector for temporary storage
		//for (i = 0; i < length; i++)
		//{
		//// Check to see if any elements remain in the left vector; 
		//// if so, we check if there are any elements left in the right vector;
		//// if so, we compare them. Otherwise, we know that the merge must
		//// take the element from the left vector. */
		//if (l < startIndex + halfLength && (r == endIndex || __scoreF[__sortedOpenedFaces[l].id] >= __scoreF[__sortedOpenedFaces[r].id]))
		//{
		//sortBuffer[i] = __sortedOpenedFaces[l];
		//l++;
		//}
		//else
		//{
		//sortBuffer[i] = __sortedOpenedFaces[r];
		//r++;
		//}
		//}
		//
		//// copy the sorted subvector back to the input
		//for (i = startIndex; i < endIndex; i++)
		//__sortedOpenedFaces[i] = sortBuffer[int(i - startIndex)];
		//}
		//}
		
		private function isWalkableByRadius(fromEdge:DDLSEdge, throughFace:DDLSFace, toEdge:DDLSEdge):Boolean
		{
			var vA:DDLSVertex; // the vertex on fromEdge not on toEdge
			var vB:DDLSVertex; // the vertex on toEdge not on fromEdge
			var vC:DDLSVertex; // the common vertex of the 2 edges (pivot)
			
			// we identify the points
			if (fromEdge.originVertex == toEdge.originVertex)
			{
				vA = fromEdge.destinationVertex;
				vB = toEdge.destinationVertex;
				vC = fromEdge.originVertex;
			}
			else if (fromEdge.destinationVertex == toEdge.destinationVertex)
			{
				vA = fromEdge.originVertex;
				vB = toEdge.originVertex;
				vC = fromEdge.destinationVertex;
			}
			else if (fromEdge.originVertex == toEdge.destinationVertex)
			{
				vA = fromEdge.destinationVertex;
				vB = toEdge.originVertex;
				vC = fromEdge.originVertex;
			}
			else if (fromEdge.destinationVertex == toEdge.originVertex)
			{
				vA = fromEdge.originVertex;
				vB = toEdge.destinationVertex;
				vC = fromEdge.destinationVertex;
			}
			
			var dot:Number;
			var result:Boolean;
			var distSquared:Number;
			
			// if we have a right or obtuse angle on CAB
			dot = (vC.pos.x - vA.pos.x) * (vB.pos.x - vA.pos.x) + (vC.pos.y - vA.pos.y) * (vB.pos.y - vA.pos.y);
			if (dot <= 0)
			{
				// we compare length of AC with radius
				distSquared = (vC.pos.x - vA.pos.x) * (vC.pos.x - vA.pos.x) + (vC.pos.y - vA.pos.y) * (vC.pos.y - vA.pos.y);
				if (distSquared >= _diameterSquared)
					return true;
				else
					return false;
			}
			
			// if we have a right or obtuse angle on CBA
			dot = (vC.pos.x - vB.pos.x) * (vA.pos.x - vB.pos.x) + (vC.pos.y - vB.pos.y) * (vA.pos.y - vB.pos.y);
			if (dot <= 0)
			{
				// we compare length of BC with radius
				distSquared = (vC.pos.x - vB.pos.x) * (vC.pos.x - vB.pos.x) + (vC.pos.y - vB.pos.y) * (vC.pos.y - vB.pos.y);
				if (distSquared >= _diameterSquared)
					return true;
				else
					return false;
			}
			
			// we identify the adjacent edge (facing pivot vertex)
			var adjEdge:DDLSEdge;
			if (throughFace.edge != fromEdge && throughFace.edge.oppositeEdge != fromEdge && throughFace.edge != toEdge && throughFace.edge.oppositeEdge != toEdge)
				adjEdge = throughFace.edge;
			else if (throughFace.edge.nextLeftEdge != fromEdge && throughFace.edge.nextLeftEdge.oppositeEdge != fromEdge && throughFace.edge.nextLeftEdge != toEdge && throughFace.edge.nextLeftEdge.oppositeEdge != toEdge)
				adjEdge = throughFace.edge.nextLeftEdge;
			else
				adjEdge = throughFace.edge.prevLeftEdge;
			
			// if the adjacent edge is constrained, we check the distance of orthognaly projected
			if (adjEdge.isConstrained)
			{
				var proj:DDLSPoint2D = new DDLSPoint2D(vC.pos.x, vC.pos.y);
				DDLSGeom2D.projectOrthogonaly(proj, adjEdge);
				distSquared = (proj.x - vC.pos.x) * (proj.x - vC.pos.x) + (proj.y - vC.pos.y) * (proj.y - vC.pos.y);
				if (distSquared >= _diameterSquared)
					return true;
				else
					return false;
			}
			else // if the adjacent is not constrained
			{
				var distSquaredA:Number = (vC.pos.x - vA.pos.x) * (vC.pos.x - vA.pos.x) + (vC.pos.y - vA.pos.y) * (vC.pos.y - vA.pos.y);
				var distSquaredB:Number = (vC.pos.x - vB.pos.x) * (vC.pos.x - vB.pos.x) + (vC.pos.y - vB.pos.y) * (vC.pos.y - vB.pos.y);
				if (distSquaredA < _diameterSquared || distSquaredB < _diameterSquared)
				{
					return false;
				}
				else
				{
					vFaceToCheck.length = 0;
					vFaceIsFromEdge.length = 0;
					var facesDone:Dictionary = new Dictionary();
					vFaceIsFromEdge.push(adjEdge);
					if (adjEdge.leftFace == throughFace)
					{
						vFaceToCheck.push(adjEdge.rightFace);
						facesDone[adjEdge.rightFace] = true;
					}
					else
					{
						vFaceToCheck.push(adjEdge.leftFace);
						facesDone[adjEdge.leftFace] = true;
					}
					
					var currFace:DDLSFace;
					var faceFromEdge:DDLSEdge;
					var currEdgeA:DDLSEdge;
					var nextFaceA:DDLSFace;
					var currEdgeB:DDLSEdge;
					var nextFaceB:DDLSFace;
					while (vFaceToCheck.length > 0)
					{
						currFace = vFaceToCheck.shift();
						faceFromEdge = vFaceIsFromEdge.shift();
						
						// we identify the 2 edges to evaluate
						if (currFace.edge == faceFromEdge || currFace.edge == faceFromEdge.oppositeEdge)
						{
							currEdgeA = currFace.edge.nextLeftEdge;
							currEdgeB = currFace.edge.nextLeftEdge.nextLeftEdge;
						}
						else if (currFace.edge.nextLeftEdge == faceFromEdge || currFace.edge.nextLeftEdge == faceFromEdge.oppositeEdge)
						{
							currEdgeA = currFace.edge;
							currEdgeB = currFace.edge.nextLeftEdge.nextLeftEdge;
						}
						else
						{
							currEdgeA = currFace.edge;
							currEdgeB = currFace.edge.nextLeftEdge;
						}
						
						// we identify the faces related to the 2 edges
						if (currEdgeA.leftFace == currFace)
							nextFaceA = currEdgeA.rightFace;
						else
							nextFaceA = currEdgeA.leftFace;
						if (currEdgeB.leftFace == currFace)
							nextFaceB = currEdgeB.rightFace;
						else
							nextFaceB = currEdgeB.leftFace;
						
						// we check if the next face is not already in pipe
						// and if the edge A is close to pivot vertex
						if (!facesDone[nextFaceA] && DDLSGeom2D.distanceSquaredVertexToEdge(vC, currEdgeA) < _diameterSquared)
						{
							// if the edge is constrained
							if (currEdgeA.isConstrained)
							{
								// so it is not walkable
								return false;
							}
							else
							{
								// if the edge is not constrained, we continue the search
								vFaceToCheck.push(nextFaceA);
								vFaceIsFromEdge.push(currEdgeA);
								facesDone[nextFaceA] = true;
							}
						}
						
						// we check if the next face is not already in pipe
						// and if the edge B is close to pivot vertex
						if (!facesDone[nextFaceB] && DDLSGeom2D.distanceSquaredVertexToEdge(vC, currEdgeB) < _diameterSquared)
						{
							// if the edge is constrained
							if (currEdgeB.isConstrained)
							{
								// so it is not walkable
								return false;
							}
							else
							{
								// if the edge is not constrained, we continue the search
								vFaceToCheck.push(nextFaceB);
								vFaceIsFromEdge.push(currEdgeB);
								facesDone[nextFaceB] = true;
							}
						}
					}
					
					// if we didn't previously meet a constrained edge
					return true;
				}
			}
			
			return true;
		}
		
		private function clearTemps():void
		{
			//var length:int = __entryX.length;
			//for (var i:int = 0; i < length; i++)
			//{
			//if (__entryX[i])
			//{
			//__entryX[i] = undefined;
			//__entryY[i] = undefined;
			//__scoreF[i] = undefined;
			//__scoreG[i] = undefined;
			//__scoreH[i] = undefined;
			//__predecessor[i] = undefined;
			//__entryEdges[i] = undefined;
			//}
			//}
			var length:int = __openedFaces.length;
			for (var j:int = 0; j < length; j++)
			{
				if (__closedFaces[j])
				{
					__closedFaces[j] = null;
				}
				else if (__openedFaces[j])
					__openedFaces[j] = null;
			}
		}
	
	}
}