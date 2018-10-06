// =================================================================================================
//
//	copied from Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package DDLS.factories
{
	import DDLS.data.DDLSEdge;
	import DDLS.data.DDLSFace;
	import DDLS.data.DDLSVertex;
	import DDLS.data.math.DDLSPoint2D;
	import flash.errors.IllegalOperationError;
	
	/** An object pool for geometric objects.
	 *
	 *  <p>If you want to retrieve an object, but the pool does not contain any more instances,
	 *  it will silently create a new one.</p>
	 *
	 *  <p>It's important that you use the pool in a balanced way, i.e. don't just "get" or "put"
	 *  alone! Always make the calls in pairs; whenever you get an object, be sure to put it back
	 *  later, and the other way round. Otherwise, the pool will empty or (even worse) grow
	 *  in size uncontrolled.</p>
	 */
	public class DDLSPool
	{
		private static var sPoints:Vector.<DDLSPoint2D> = new <DDLSPoint2D>[];
		private static var sDDLSFaces:Vector.<DDLSFace> = new <DDLSFace>[];
		private static var sDDLSEdges:Vector.<DDLSEdge> = new <DDLSEdge>[];
		private static var sDDLSVertex:Vector.<DDLSVertex> = new <DDLSVertex>[];
		private static var sDDLSEdgeVector:Vector.<Vector.<DDLSEdge>> = new <Vector.<DDLSEdge>>[];
		
		/** @private */
		public function DDLSPool()
		{
			throw new IllegalOperationError("Called contractor for abstract static class");
		}
		
		/** Retrieves a Point instance from the pool. */
		public static function getPoint(x:Number = 0, y:Number = 0):DDLSPoint2D
		{
			if (sPoints.length == 0)
				return new DDLSPoint2D(x, y);
			else
			{
				var point:DDLSPoint2D = sPoints.pop();
				point.x = x;
				point.y = y;
				return point;
			}
		}
		
		/** Stores a Point instance in the pool.
		 *  Don't keep any references to the object after moving it to the pool! */
		public static function putPoint(point:DDLSPoint2D):void
		{
			sPoints[sPoints.length] = point;
		}
		
		public static function getDDLSFace():DDLSFace
		{
			if (sDDLSFaces.length == 0)
				return new DDLSFace();
			else
			{
				var face:DDLSFace = sDDLSFaces.pop();
				return face;
			}
		}
		
		public static function putDDLSFace(face:DDLSFace):void
		{
			face.dispose();
			sDDLSFaces[sDDLSFaces.length] = face;
		}
		
		public static function getDDLSVertex():DDLSVertex
		{
			if (sDDLSVertex.length == 0)
				return new DDLSVertex();
			else
			{
				var vertex:DDLSVertex = sDDLSVertex.pop();
				return vertex;
			}
		}
		
		public static function putDDLSVertex(vertex:DDLSVertex):void
		{
			vertex.dispose();
			sDDLSVertex[sDDLSVertex.length] = vertex;
		}
		
		public static function getDDLSEdge():DDLSEdge
		{
			if (sDDLSEdges.length == 0)
				return new DDLSEdge();
			else
			{
				var edge:DDLSEdge = sDDLSEdges.pop();
				return edge;
			}
		}
		
		public static function putDDLSEdge(edge:DDLSEdge):void
		{
			edge.dispose();
			sDDLSEdges[sDDLSEdges.length] = edge;
		}
		
		public static function getDDLSEdgeVector(length:int = 0):Vector.<DDLSEdge>
		{
			if (sDDLSEdgeVector.length == 0)
				return new Vector.<DDLSEdge>(length);
			else
			{
				var edgeVector:Vector.<DDLSEdge> = sDDLSEdgeVector.pop();
				edgeVector.length = length;
				return edgeVector;
			}
		}
		
		public static function sliceDDLSEdgeVector(clonedVector:Vector.<DDLSEdge>, fromIndex:int = 0, toIndex:int = 16777215):Vector.<DDLSEdge>
		{
			var edgeVector:Vector.<DDLSEdge>;
			var clonedVectorLength:int = Math.min(clonedVector.length, toIndex);
			if (sDDLSEdgeVector.length == 0)
			{
				edgeVector = new Vector.<DDLSEdge>(clonedVectorLength - fromIndex);
			}
			else
			{
				edgeVector = sDDLSEdgeVector.pop();
				edgeVector.length = clonedVectorLength - fromIndex;
			}
			for (var i:int = fromIndex; i < clonedVectorLength; i++)
			{
				edgeVector[i - fromIndex] = clonedVector[i];
			}
			return edgeVector;
		}
		
		public static function putDDLSEdgeVector(edgeVector:Vector.<DDLSEdge>):void
		{
			edgeVector.length = 0;
			sDDLSEdgeVector[sDDLSEdgeVector.length] = edgeVector;
		}
	
	}
}
