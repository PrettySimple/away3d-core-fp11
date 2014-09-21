package away3d.core.partition
{
	import away3d.core.geom.Plane3D;
	import away3d.entities.IEntity;

	/**
	 * SkyBoxNode is a space partitioning leaf node that contains a SkyBox object.
	 */
	public class SkyBoxNode extends EntityNode
	{
		private var _skyBox:IEntity;

		/**
		 * Creates a new SkyBoxNode object.
		 * @param skyBox The SkyBox to be contained in the node.
		 */
		public function SkyBoxNode(skyBox:IEntity)
		{
			super(skyBox);
			_skyBox = skyBox;
		}

		override public function isInFrustum(planes:Vector.<Plane3D>, numPlanes:int):Boolean
		{
			if (!_skyBox.isVisible)
				return false;

			//a skybox is always in view unless its visibility is set to false
			return true;
		}
	}
}