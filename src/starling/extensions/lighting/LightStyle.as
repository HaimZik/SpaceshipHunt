// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2015 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions.lighting
{
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import starling.core.starling_internal;
	
	import starling.display.Mesh;
	import starling.rendering.MeshEffect;
	import starling.rendering.RenderState;
	import starling.rendering.VertexData;
	import starling.rendering.VertexDataFormat;
	import starling.styles.MeshStyle;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;
	import avm2.intrinsics.memory.sf32;
	import avm2.intrinsics.memory.si32;
	import avm2.intrinsics.memory.lf32;
	import avm2.intrinsics.memory.si8;
	
	public class LightStyle extends MeshStyle
	{
		public static const VERTEX_FORMAT:VertexDataFormat = LightEffect.VERTEX_FORMAT;
		private static const axisAttributeSize:int = VERTEX_FORMAT.getSize("xAxis");
		private static const xAxisAttributeOffset:int = VERTEX_FORMAT.getOffset("xAxis");
		
		private var _light:LightSource;
		private var _normalTexture:Texture;
		
		// helpers
		private var sPoint:Point = new Point();
		private var sMatrix:Matrix = new Matrix();
		private var sMatrix3D:Matrix3D = new Matrix3D();
		private var sMatrixAlt3D:Matrix3D = new Matrix3D();
		
		public function LightStyle(normalTexture:Texture = null)
		{
			_normalTexture = normalTexture;
		}
		
		/** Sets the texture coordinates of the specified vertex within the normal texture
		 *  to the given values. */
		private function setNormalTexCoords(vertexID:int, u:Number, v:Number):void
		{
			if (_normalTexture)
				_normalTexture.setTexCoords(vertexData, vertexID, "normalTexCoords", u, v);
			else
				vertexData.setPoint(vertexID, "normalTexCoords", u, v);
			
			setRequiresRedraw();
		}
		
		override public function setTexCoords(vertexID:int, u:Number, v:Number):void
		{
			// In this case, it makes sense to simply sync the texture coordinates of the
			// standard texture with those of the normal texture.
			
			setNormalTexCoords(vertexID, u, v);
			super.setTexCoords(vertexID, u, v);
		}
		
		override public function copyFrom(meshStyle:MeshStyle):void
		{
			var litMeshStyle:LightStyle = meshStyle as LightStyle;
			if (litMeshStyle)
			{
				_light = litMeshStyle._light;
				_normalTexture = litMeshStyle._normalTexture;
			}
			super.copyFrom(meshStyle);
		}
		
		[inline]
		override public final function batchVertexData(targetStyle:MeshStyle, targetVertexID:int = 0, matrix:Matrix = null, vertexID:int = 0, numVertices:int = -1):void
		{
			super.batchVertexData(targetStyle, targetVertexID, matrix, vertexID, numVertices);
			
			if (matrix)
			{
				// when the mesh is transformed, the directions of the normal vectors must change,
				// too. To be able to rotate them correctly in the shaders, we store the direction
				// of x- and y-axis in the vertex data. (The z-axis is the cross product of x & y.)
				
				var targetLightStyle:LightStyle = targetStyle as LightStyle;
				var targetVertexData:VertexData = targetLightStyle.vertexData;
				sMatrix.setTo(matrix.a, matrix.b, matrix.c, matrix.d, 0, 0);
				copyAxisAttributesTo(targetVertexData, targetVertexID, sMatrix, vertexID, numVertices);
			}
		}
		
		
		
		private final function copyAxisAttributesTo(target:VertexData, targetVertexID:int, matrix:Matrix, vertexID:int, numVertices:int):void
		{
			var _numVertices:int = vertexData.numVertices;
			if (numVertices < 0 || vertexID + numVertices > _numVertices)
				numVertices = _numVertices - vertexID;
			
			if (target.numVertices < targetVertexID + numVertices)
				target.numVertices = targetVertexID + numVertices;
			
			var targetData:ByteArray = target.rawData;
			var targetDelta:int = target.vertexSize -axisAttributeSize*2;
			var pos:int = targetVertexID * target.vertexSize + xAxisAttributeOffset;
			var i:int;
			if (VertexData.starling_internal::tryAssignToDomainMemory(targetData, (targetDelta + 16) * numVertices))
			{
				for (i = 0; i < numVertices; ++i)
				{
					// Write float number into targetData.
					sf32(matrix.a, pos);
					pos += 4;
					sf32(matrix.b, pos);
					pos += 4;
					sf32(matrix.c, pos);
					pos += 4;
					sf32(matrix.d, pos);
					pos += 4 + targetDelta;
				}
			}
			else
			{
				targetData.position = pos;
				for (i = 0; i < numVertices; ++i)
				{	
					targetData.writeFloat(matrix.a);
					targetData.writeFloat(matrix.b);
					targetData.writeFloat(matrix.c);
					targetData.writeFloat(matrix.d);
					targetData.position += targetDelta;
				}
			}
		}	
		
		override public function canBatchWith(meshStyle:MeshStyle):Boolean
		{
			var litMeshStyle:LightStyle = meshStyle as LightStyle;
			if (litMeshStyle && super.canBatchWith(meshStyle))
			{
				var newNormalTexture:Texture = litMeshStyle._normalTexture;
				
				if (_light != litMeshStyle._light)
					return false;
				else if (_normalTexture == null && newNormalTexture == null)
					return true;
				else if (_normalTexture && newNormalTexture)
					return _normalTexture.base == newNormalTexture.base;
				else
					return false;
			}
			else
				return false;
		}
		
		override public function createEffect():MeshEffect
		{
			return new LightEffect();
		}
		
		override public function updateEffect(effect:MeshEffect, state:RenderState):void
		{
			var lightEffect:LightEffect = effect as LightEffect;
			lightEffect.normalTexture = _normalTexture;
			
			if (_light)
			{
				// transformation matrix to the light's base object (should be the stage)
				_light.getTransformationMatrix3D(null, sMatrix3D);
				
				// transformation matrix from the stage to the current coordinate system
				if (state.is3D)
					sMatrixAlt3D.copyFrom(state.modelviewMatrix3D);
				else
					MatrixUtil.convertTo3D(state.modelviewMatrix, sMatrixAlt3D);
				
				// combine those matrices
				sMatrixAlt3D.invert();
				sMatrix3D.append(sMatrixAlt3D);
				
				// in the local coordinate system of the light, its source is at [0, 0, 0]!
				MatrixUtil.transformCoords3D(sMatrix3D, 0, 0, 0, lightEffect.lightPosition);
				
				lightEffect.diffuseColor = Color.multiply(_light.color, _light.brightness);
				lightEffect.ambientColor = Color.multiply(_light.ambientColor, _light.ambientBrightness);
			}
			
			super.updateEffect(effect, state);
		}
		
		override public function get vertexFormat():VertexDataFormat
		{
			return VERTEX_FORMAT;
		}
		
		override protected function onTargetAssigned(target:Mesh):void
		{
			var numVertices:int = vertexData.numVertices;
			
			for (var i:int = 0; i < numVertices; ++i)
			{
				getTexCoords(i, sPoint);
				setNormalTexCoords(i, sPoint.x, sPoint.y);
				vertexData.setPoint(i, "xAxis", 1, 0);
				vertexData.setPoint(i, "yAxis", 0, 1);
			}
		}
		
		public function get normalTexture():Texture
		{
			return _normalTexture;
		}
		
		public function set normalTexture(value:Texture):void
		{
			if (value != _normalTexture)
			{
				if (target)
				{
					for (var i:int = 0; i < vertexData.numVertices; ++i)
					{
						getTexCoords(i, sPoint);
						if (value)
							value.setTexCoords(vertexData, i, "normalTexCoords", sPoint.x, sPoint.y);
					}
				}
				
				_normalTexture = value;
				setRequiresRedraw();
			}
		}
		
		public function get light():LightSource
		{
			return _light;
		}
		
		public function set light(value:LightSource):void
		{
			if (_light != value)
			{
				_light = value;
				setRequiresRedraw();
			}
		}
	}
}
