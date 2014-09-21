package away3d.tools.helpers
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.Object3D;
	import away3d.core.base.SubGeometryBase;
	import away3d.core.base.TriangleSubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.core.geom.Box;
	import away3d.entities.Mesh;
	import away3d.materials.MaterialBase;
	import away3d.materials.utils.DefaultMaterialManager;
	import away3d.tools.utils.Bounds;
	import away3d.tools.utils.GeomUtil;

	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;

	use namespace arcane;
	
	/**
	 * Helper Class for the Mesh object <code>MeshHelper</code>
	 * A series of methods usually usefull for mesh manipulations
	 */
	
	public class MeshHelper
	{
		private static const LIMIT:uint = 196605;
		
		/**
		 * Returns the boundingRadius of an Entity of a Mesh.
		 * @param mesh        Mesh. The mesh to get the boundingRadius from.
		 */
		public static function boundingRadius(mesh:Mesh):Number
		{
			var radius:Number;
			try {
				var aabb:Box = mesh.bounds.aabb;
				var minX:Number = aabb.x;
				var minY:Number = aabb.y - aabb.height;
				var minZ:Number = aabb.z;
				var maxX:Number = aabb.x + aabb.width;
				var maxY:Number = aabb.y;
				var maxZ:Number = aabb.z + aabb.depth;
				radius = Math.max((maxX - minX)*Object3D(mesh).scaleX, (maxY - minY)*Object3D(mesh).scaleY, (maxZ - minZ)*Object3D(mesh).scaleZ);
			} catch (e:Error) {
				Bounds.getMeshBounds(mesh);
				radius = Math.max((Bounds.maxX - Bounds.minX)*Object3D(mesh).scaleX, (Bounds.maxY - Bounds.minY)*Object3D(mesh).scaleY, (Bounds.maxZ - Bounds.minZ)*Object3D(mesh).scaleZ);
			}
			
			return radius*.5;
		}
		
		/**
		 * Returns the boundingRadius of a ObjectContainer3D
		 * @param container        ObjectContainer3D. The ObjectContainer3D and its children to get the boundingRadius from.
		 */
		public static function boundingRadiusContainer(container:ObjectContainer3D):Number
		{
			Bounds.getObjectContainerBounds(container);
			var radius:Number = Math.max((Bounds.maxX - Bounds.minX)*Object3D(container).scaleX, (Bounds.maxY - Bounds.minY)*Object3D(container).scaleY, (Bounds.maxZ - Bounds.minZ)*Object3D(container).scaleZ);
			return radius*.5;
		}
		
		/**
		 * Recenter geometry
		 * @param mesh                Mesh. The Mesh to recenter in its own objectspace
		 * @param keepPosition    Boolean. KeepPosition applys the offset to the object position. Object is "visually" at same position.
		 */
		public static function recenter(mesh:Mesh, keepPosition:Boolean = true):void
		{
			Bounds.getMeshBounds(mesh);
			
			var dx:Number = (Bounds.minX + Bounds.maxX)*.5;
			var dy:Number = (Bounds.minY + Bounds.maxY)*.5;
			var dz:Number = (Bounds.minZ + Bounds.maxZ)*.5;
			
			applyPosition(mesh, -dx, -dy, -dz);
			
			if (!keepPosition) {
				mesh.x -= dx;
				mesh.y -= dy;
				mesh.z -= dz;
			}
		}
		
		/**
		 * Recenter geometry of all meshes found into container
		 * @param mesh                Mesh. The Mesh to recenter in its own objectspace
		 * @param keepPosition    Boolean. KeepPosition applys the offset to the object position. Object is "visually" at same position.
		 */
		public static function recenterContainer(obj:ObjectContainer3D, keepPosition:Boolean = true):void
		{
			var child:ObjectContainer3D;
			
			if (obj is Mesh && ObjectContainer3D(obj).numChildren == 0)
				recenter(Mesh(obj), keepPosition);
			
			for (var i:uint = 0; i < ObjectContainer3D(obj).numChildren; ++i) {
				child = ObjectContainer3D(obj).getChildAt(i) as ObjectContainer3D;
				recenterContainer(child, keepPosition);
			}
		
		}
		
		/**
		 * Applys the rotation values of a mesh in object space and resets rotations to zero.
		 * @param mesh                Mesh. The Mesh to alter
		 */
		public static function applyRotations(mesh:Mesh):void
		{
			var i:uint, j:uint, len:uint, vStride:uint, vOffs:uint, nStride:uint, nOffs:uint;
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<SubGeometryBase> = geometry.subGeometries;
			var positions:Vector.<Number>;
			var normals:Vector.<Number>;
			var numSubGeoms:uint = geometries.length;
			var subGeom:TriangleSubGeometry;
			var t:Matrix3D = mesh.transform.clone();
			t.appendScale(1/mesh.scaleX, 1/mesh.scaleY, 1/mesh.scaleZ);
			var holder:Vector3D = new Vector3D();
			
			for (i = 0; i < numSubGeoms; ++i) {
				subGeom = TriangleSubGeometry(geometries[i]);
				if(!subGeom) continue;
				positions = subGeom.positions;
				vOffs = subGeom.getOffset(TriangleSubGeometry.POSITION_DATA);
				vStride = subGeom.getStride(TriangleSubGeometry.POSITION_DATA);
				normals = subGeom.vertexNormals;
				nOffs = subGeom.getOffset(TriangleSubGeometry.NORMAL_DATA);
				nStride = subGeom.getStride(TriangleSubGeometry.NORMAL_DATA);
				len = subGeom.numVertices;
				
				for (j = 0; j < len; j++) {
					//verts
					holder.x = positions[vOffs + j*vStride + 0];
					holder.y = positions[vOffs + j*vStride + 1];
					holder.z = positions[vOffs + j*vStride + 2];
					
					holder = t.deltaTransformVector(holder);
					
					positions[vOffs + j*vStride + 0] = holder.x;
					positions[vOffs + j*vStride + 1] = holder.y;
					positions[vOffs + j*vStride + 2] = holder.z;
					//norms
					holder.x = normals[nOffs + j*nStride + 0];
					holder.y = normals[nOffs + j*nStride + 1];
					holder.z = normals[nOffs + j*nStride + 2];
					
					holder = t.deltaTransformVector(holder);
					holder.normalize();
					
					normals[nOffs + j*nStride + 0] = holder.x;
					normals[nOffs + j*nStride + 1] = holder.y;
					normals[nOffs + j*nStride + 2] = holder.z;
				}
				TriangleSubGeometry(subGeom).updatePositions(positions);
				TriangleSubGeometry(subGeom).updateVertexNormals(normals);
			}
			
			mesh.rotationX = mesh.rotationY = mesh.rotationZ = 0;
		}
		
		/**
		 * Applys the rotation values of each mesh found into an ObjectContainer3D
		 * @param obj                ObjectContainer3D. The ObjectContainer3D to alter
		 */
		public static function applyRotationsContainer(obj:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			
			if (obj is Mesh && ObjectContainer3D(obj).numChildren == 0)
				applyRotations(Mesh(obj));
			
			for (var i:uint = 0; i < ObjectContainer3D(obj).numChildren; ++i) {
				child = ObjectContainer3D(obj).getChildAt(i) as ObjectContainer3D;
				applyRotationsContainer(child);
			}
		
		}
		
		/**
		 * Applys the scaleX, scaleY and scaleZ scale factors to the mesh vertices. Resets the mesh scaleX, scaleY and scaleZ properties to 1;
		 * @param mesh                Mesh. The Mesh to rescale
		 * @param scaleX            Number. The scale factor to apply on all vertices x values.
		 * @param scaleY            Number. The scale factor to apply on all vertices y values.
		 * @param scaleZ            Number. The scale factor to apply on all vertices z values.
		 * @param parent            ObjectContainer3D. If a parent is set, the position of children is also scaled
		 */
		public static function applyScales(mesh:Mesh, scaleX:Number, scaleY:Number, scaleZ:Number, parent:ObjectContainer3D = null):void
		{
			if (scaleX == 1 && scaleY == 1 && scaleZ == 1)
				return;
			
			if (mesh.animator) {
				mesh.scaleX = scaleX;
				mesh.scaleY = scaleY;
				mesh.scaleZ = scaleZ;
				return;
			}
			
			var i:uint, j:uint, len:uint, vStride:uint, vOffs:uint;
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<SubGeometryBase> = geometry.subGeometries;
			var positions:Vector.<Number>;
			var numSubGeoms:uint = geometries.length;
			var subGeom:TriangleSubGeometry;
			
			for (i = 0; i < numSubGeoms; ++i) {
				subGeom = TriangleSubGeometry(geometries[i]);
				if(!subGeom) continue;
				vOffs = subGeom.getOffset(TriangleSubGeometry.POSITION_DATA);
				vStride = subGeom.getStride(TriangleSubGeometry.POSITION_DATA);
				positions = subGeom.positions;
				len = subGeom.numVertices;
				
				for (j = 0; j < len; j++) {
					positions[vOffs + j*vStride + 0] *= scaleX;
					positions[vOffs + j*vStride + 1] *= scaleY;
					positions[vOffs + j*vStride + 2] *= scaleZ;
				}
				
				subGeom.updatePositions(positions);
			}
			
			mesh.scaleX = mesh.scaleY = mesh.scaleZ = 1;
			
			if (parent) {
				mesh.x *= scaleX;
				mesh.y *= scaleY;
				mesh.z *= scaleZ;
			}
		}
		
		/**
		 * Applys the scale properties values of each mesh found into an ObjectContainer3D
		 * @param obj                ObjectContainer3D. The ObjectContainer3D to alter
		 * @param scaleX            Number. The scale factor to apply on all vertices x values.
		 * @param scaleY            Number. The scale factor to apply on all vertices y values.
		 * @param scaleZ            Number. The scale factor to apply on all vertices z values.
		 */
		public static function applyScalesContainer(obj:ObjectContainer3D, scaleX:Number, scaleY:Number, scaleZ:Number, parent:ObjectContainer3D = null):void
		{
			parent = parent;
			
			var child:ObjectContainer3D;
			
			if (obj is Mesh && ObjectContainer3D(obj).numChildren == 0)
				applyScales(Mesh(obj), scaleX, scaleY, scaleZ, obj);
			
			for (var i:uint = 0; i < ObjectContainer3D(obj).numChildren; ++i) {
				child = ObjectContainer3D(obj).getChildAt(i) as ObjectContainer3D;
				applyScalesContainer(child, scaleX, scaleY, scaleZ, obj);
			}
		}
		
		/**
		 * Applys an offset to a mesh at vertices level
		 * @param mesh                Mesh. The Mesh to offset
		 * @param dx                    Number. The offset along the x axis
		 * @param dy                    Number. The offset along the y axis
		 * @param dz                    Number. The offset along the z axis
		 */
		public static function applyPosition(mesh:Mesh, dx:Number, dy:Number, dz:Number):void
		{
			var i:uint, j:uint, len:uint, vStride:uint, vOffs:uint;
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<SubGeometryBase> = geometry.subGeometries;
			var positions:Vector.<Number>;
			var numSubGeoms:uint = geometries.length;
			var subGeom:TriangleSubGeometry;
			
			for (i = 0; i < numSubGeoms; ++i) {
				subGeom = TriangleSubGeometry(geometries[i]);
				if(!subGeom) continue;
				vOffs = subGeom.getOffset(TriangleSubGeometry.POSITION_DATA);
				vStride = subGeom.getStride(TriangleSubGeometry.POSITION_DATA);
				positions = subGeom.positions;
				len = subGeom.numVertices;
				
				for (j = 0; j < len; j++) {
					positions[vOffs + j*vStride + 0] += dx;
					positions[vOffs + j*vStride + 1] += dy;
					positions[vOffs + j*vStride + 2] += dz;
				}
				
				subGeom.updatePositions(positions);
			}
			
			mesh.x -= dx;
			mesh.y -= dy;
			mesh.z -= dz;
		}
		
		/**
		 * Clones a Mesh
		 * @param mesh                Mesh. The mesh to clone
		 * @param newname        [optional] String. new name for the duplicated mesh. Default = "";
		 *
		 * @ returns Mesh
		 */
		public static function clone(mesh:Mesh, newName:String = ""):Mesh
		{
			var geometry:Geometry = mesh.geometry.clone();
			var newMesh:Mesh = new Mesh(geometry, mesh.material);
			newMesh.name = newName;
			
			return newMesh;
		}
		
		/**
		 * Inverts the faces of all the Meshes into an ObjectContainer3D
		 * @param obj        ObjectContainer3D. The ObjectContainer3D to invert.
		 */
		public static function invertFacesInContainer(obj:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			
			if (obj is Mesh && ObjectContainer3D(obj).numChildren == 0)
				invertFaces(Mesh(obj));
			
			for (var i:uint = 0; i < ObjectContainer3D(obj).numChildren; ++i) {
				child = ObjectContainer3D(obj).getChildAt(i) as ObjectContainer3D;
				invertFacesInContainer(child);
			}
		
		}
		
		/**
		 * Inverts the faces of a Mesh
		 * @param mesh        Mesh. The Mesh to invert.
		 * @param invertUV        Boolean. If the uvs are inverted too. Default is false;
		 */
		public static function invertFaces(mesh:Mesh, invertU:Boolean = false):void
		{
			var i:uint, j:uint, len:uint, tStride:uint, tOffs:uint, nStride:uint, nOffs:uint, uStride:uint, uOffs:uint;
			var geometry:Geometry = mesh.geometry;
			var geometries:Vector.<SubGeometryBase> = geometry.subGeometries;
			var indices:Vector.<uint>;
			var indicesC:Vector.<uint>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;
			var uvs:Vector.<Number>;
			var numSubGeoms:uint = geometries.length;
			var subGeom:TriangleSubGeometry;
			
			for (i = 0; i < numSubGeoms; ++i) {
				subGeom = TriangleSubGeometry(geometries[i]);
				if(!subGeom) continue;
				indices = subGeom.indices;
				indicesC = subGeom.indices.concat();
				
				normals = subGeom.vertexNormals;
				nOffs = subGeom.getOffset(TriangleSubGeometry.NORMAL_DATA);
				nStride = subGeom.getStride(TriangleSubGeometry.NORMAL_DATA);
				
				uvs = subGeom.uvs;
				uOffs = subGeom.getOffset(TriangleSubGeometry.UV_DATA);
				uStride = subGeom.getStride(TriangleSubGeometry.UV_DATA);
				len = subGeom.numVertices;
				
				tangents = subGeom.vertexTangents;
				tOffs = subGeom.getOffset(TriangleSubGeometry.TANGENT_DATA);
				tStride = subGeom.getStride(TriangleSubGeometry.TANGENT_DATA);
				
				for (i = 0; i < indices.length; i += 3) {
					indices[i + 0] = indicesC[i + 2];
					indices[i + 1] = indicesC[i + 1];
					indices[i + 2] = indicesC[i + 0];
				}
				
				for (j = 0; j < len; j++) {
					
					normals[nOffs + j*nStride + 0] *= -1;
					normals[nOffs + j*nStride + 1] *= -1;
					normals[nOffs + j*nStride + 2] *= -1;
					
					tangents[tOffs + j*tStride + 0] *= -1;
					tangents[tOffs + j*tStride + 1] *= -1;
					tangents[tOffs + j*tStride + 2] *= -1;
					
					if (invertU)
						uvs[uOffs + j*uStride + 0] = 1 - uvs[uOffs + j*uStride + 0];
					
				}
				subGeom.updateIndices(indices);
				subGeom.updateUVs(uvs);
				subGeom.updateVertexNormals(normals);
				subGeom.updateVertexTangents(tangents);
			}
		}
		
		/**
		 * Build a Mesh from Vectors
		 * @param vertices                Vector.&lt;Number&gt;. The vertices Vector.&lt;Number&gt;, must hold a multiple of 3 numbers.
		 * @param indices                Vector.&lt;uint&gt;. The indices Vector.&lt;uint&gt;, holding the face order
		 * @param uvs                    [optional] Vector.&lt;Number&gt;. The uvs Vector, must hold a series of numbers of (vertices.length/3 * 2) entries. If none is set, default uv's are applied
		 * if no uv's are defined, default uv mapping is set.
		 * @param name                    [optional] String. new name for the generated mesh. Default = "";
		 * @param material                [optional] MaterialBase. new name for the duplicated mesh. Default = null;
		 * @param shareVertices        [optional] Boolean. Defines if the vertices are shared or not. When true surface gets a smoother appearance when exposed to light. Default = true;
		 * @param useDefaultMap    [optional] Boolean. Defines if the mesh receives the default engine map if no material is passes. Default = true;
		 *
		 * @ returns Mesh
		 */
		public static function build(vertices:Vector.<Number>, indices:Vector.<uint>, uvs:Vector.<Number> = null, name:String = "", material:MaterialBase = null, shareVertices:Boolean = true, useDefaultMap:Boolean = true, useCompactSubGeometry:Boolean = true):Mesh
		{
			var i:uint;
			
			if (useCompactSubGeometry) {
				var subGeoms:Vector.<SubGeometryBase> = GeomUtil.fromVectors(vertices, indices, uvs, null, null, null, null);
				var geometry:Geometry = new Geometry();
				var subGeom:TriangleSubGeometry;
				
				for (i = 0; i < subGeoms.length; i++) {
					subGeom = subGeoms[i] as TriangleSubGeometry;
					if(!subGeom) continue;
					subGeom.autoDeriveNormals = true;
					subGeom.autoDeriveTangents = true;
					geometry.addSubGeometry(subGeoms[i]);
				}
				
				material = (!material)? DefaultMaterialManager.getDefaultMaterial() : material;
				var m:Mesh = new Mesh(geometry, material);
				
				if (name != "")
					m.name = name;
				return m;
			} else {
				subGeom = new TriangleSubGeometry(false);
				subGeom.autoDeriveNormals = true;
				subGeom.autoDeriveTangents = true;
				geometry = new Geometry();
				geometry.addSubGeometry(subGeom);
				
				material = (!material && useDefaultMap)? DefaultMaterialManager.getDefaultMaterial() : material;
				m = new Mesh(geometry, material);
				
				if (name != "")
					m.name = name;
				
				var npositions:Vector.<Number> = new Vector.<Number>();
				var nuvs:Vector.<Number> = new Vector.<Number>();
				var nindices:Vector.<uint> = new Vector.<uint>();
				
				var defaultUVS:Vector.<Number> = Vector.<Number>([0, 1, .5, 0, 1, 1, .5, 0]);
				var uvid:uint = 0;
				
				if (shareVertices) {
					var dShared:Dictionary = new Dictionary();
					var uv:UV = new UV();
					var ref:String;
				}
				
				var uvind:uint;
				var vind:uint;
				var ind:uint;
				//var j:uint;
				var vertex:Vertex = new Vertex();
				
				for (i = 0; i < indices.length; ++i) {
					ind = indices[i]*3;
					vertex.x = vertices[ind];
					vertex.y = vertices[ind + 1];
					vertex.z = vertices[ind + 2];
					
					if (npositions.length == LIMIT) {
						subGeom.updateIndices(nindices);
						subGeom.updatePositions(npositions);
						subGeom.updateUVs(nuvs);
						
						if (shareVertices) {
							dShared = null;
							dShared = new Dictionary();
						}
						
						subGeom = new TriangleSubGeometry(false);
						subGeom.autoDeriveNormals = true;
						subGeom.autoDeriveTangents = true;
						geometry.addSubGeometry(subGeom);
						
						uvid = 0;
						
						npositions = new Vector.<Number>();
						nindices = new Vector.<uint>();
						nuvs = new Vector.<Number>();
					}
					
					vind = npositions.length/3;
					uvind = indices[i]*2;
					
					if (shareVertices) {
						uv.u = uvs[uvind];
						uv.v = uvs[uvind + 1];
						ref = vertex.toString() + uv.toString();
						if (dShared[ref]) {
							nindices[nindices.length] = dShared[ref];
							continue;
						}
						dShared[ref] = vind;
					}
					
					nindices[nindices.length] = vind;
					npositions.push(vertex.x, vertex.y, vertex.z);
					
					if (!uvs || uvind > uvs.length - 2) {
						nuvs.push(defaultUVS[uvid], defaultUVS[uvid + 1]);
						uvid = (uvid + 2 > 3)? 0 : uvid += 2;
						
					} else
						nuvs.push(uvs[uvind], uvs[uvind + 1]);
				}
				
				if (shareVertices) {
					dShared = null;
				}
				subGeom.updateIndices(nindices);
				subGeom.updatePositions(npositions);
				subGeom.updateUVs(nuvs);
				
				return m;
			}
		}
		
		/**
		 * Splits the subgeometries of a given mesh in a series of new meshes
		 * @param mesh                    Mesh. The mesh to split in a series of independant meshes from its subgeometries.
		 * @param disposeSource        Boolean. If the mesh source must be destroyed after the split. Default is false;
		 *
		 * @ returns Vector..&lt;Mesh&gt;
		 */
		public static function splitMesh(mesh:Mesh, disposeSource:Boolean = false):Vector.<Mesh>
		{
			var meshes:Vector.<Mesh> = new Vector.<Mesh>();
			var geometries:Vector.<SubGeometryBase> = mesh.geometry.subGeometries;
			var numSubGeoms:uint = geometries.length;
			
			if (numSubGeoms == 1) {
				meshes.push(mesh);
				return meshes;
			}
			
			if (geometries[0] is TriangleSubGeometry)
				return splitMeshCsg(mesh, disposeSource);
			
			var positions:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			var normals:Vector.<Number>;
			var tangents:Vector.<Number>;
			var subGeom:TriangleSubGeometry;
			
			var nGeom:Geometry;
			var nSubGeom:TriangleSubGeometry;
			var nm:Mesh;
			
			var nMeshMat:MaterialBase;
			var j:uint = 0;
			
			for (var i:uint = 0; i < numSubGeoms; ++i) {
				subGeom = geometries[i] as TriangleSubGeometry;
				if(!subGeom) continue;
				
				positions = subGeom.positions;
				indices = subGeom.indices;
				uvs = subGeom.uvs;
				
				try {
					normals = subGeom.vertexNormals;
					subGeom.autoDeriveNormals = false;
				} catch (e:Error) {
					subGeom.autoDeriveNormals = true;
					normals = new Vector.<Number>();
					j = 0;
					while (j < positions.length) {
						normals[j++] = 0.0;
					}
				}
				
				try {
					tangents = subGeom.vertexTangents;
					subGeom.autoDeriveTangents = false;
				} catch (e:Error) {
					subGeom.autoDeriveTangents = true;
					tangents = new Vector.<Number>();
					j = 0;
					while (j < positions.length)
						tangents[j++] = 0.0;
				}
				
				positions.fixed = false;
				indices.fixed = false;
				uvs.fixed = false;
				normals.fixed = false;
				tangents.fixed = false;
				
				nGeom = new Geometry();
				nm = new Mesh(nGeom, mesh.subMeshes[i].material? mesh.subMeshes[i].material : nMeshMat);
				
				nSubGeom = new TriangleSubGeometry(false);
				nSubGeom.updateIndices(indices);
				nSubGeom.updatePositions(positions);
				nSubGeom.updateUVs(uvs);
				nSubGeom.updateVertexNormals(normals);
				nSubGeom.updateVertexTangents(tangents);
				nGeom.addSubGeometry(nSubGeom);
				
				meshes.push(nm);
			}
			
			if (disposeSource)
				mesh = null;
			
			return meshes;
		}
		
		private static function splitMeshCsg(mesh:Mesh, disposeSource:Boolean = false):Vector.<Mesh>
		{
			var meshes:Vector.<Mesh> = new Vector.<Mesh>();
			var geometries:Vector.<SubGeometryBase> = mesh.geometry.subGeometries;
			var numSubGeoms:uint = geometries.length;
			
			if (numSubGeoms == 1) {
				meshes.push(mesh);
				return meshes;
			}
			
			//var vertices:Vector.<Number>;
			//var indices:Vector.<uint>;
			var subGeom:TriangleSubGeometry;
			
			var nGeom:Geometry;
			var nSubGeom:TriangleSubGeometry;
			var nm:Mesh;
			
			var nMeshMat:MaterialBase;
			
			for (var i:uint = 0; i < numSubGeoms; ++i) {
				subGeom = TriangleSubGeometry(geometries[i]);
				if(!subGeom) continue;
				nGeom = new Geometry();
				nm = new Mesh(nGeom, mesh.subMeshes[i].material? mesh.subMeshes[i].material : nMeshMat);
				nSubGeom = new TriangleSubGeometry(true);
				nSubGeom.updateIndices(subGeom.indices);
				nSubGeom.updatePositions(subGeom.positions);
				nGeom.addSubGeometry(nSubGeom);
				meshes.push(nm);
			}
			
			if (disposeSource) {
				mesh = null;
			}
			return meshes;
		}
	
	}
}
