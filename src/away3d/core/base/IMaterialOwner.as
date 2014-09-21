package away3d.core.base
{
	import away3d.animators.IAnimator;
	import away3d.core.geom.UVTransform;
	import away3d.core.pool.IRenderable;
	import away3d.core.render.IRenderer;
	import away3d.core.library.IAsset;
	import away3d.materials.MaterialBase;

	/**
	 * IMaterialOwner provides an interface for objects that can use materials.
	 * @interface away3d.core.base.IMaterialOwner
	 */
	public interface IMaterialOwner extends IAsset
	{
		/**
		 * The animation used by the material to assemble the vertex code.
		 */
		function get animator():IAnimator; // in most cases, this will in fact be null

		function get uvTransform():UVTransform; // in most cases, this will in fact be null

		function set uvTransform(value:UVTransform):void; // in most cases, this will in fact be null

		/**
		 * The material with which to render the object.
		 */
		function get material():MaterialBase;

		function set material(value:MaterialBase):void;

		function addRenderable(renderable:IRenderable):IRenderable;

		function removeRenderable(renderable:IRenderable):IRenderable;

		function collectRenderable(renderable:IRenderer):void;
	}
}
