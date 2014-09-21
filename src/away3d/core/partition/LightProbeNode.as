package away3d.core.partition
{
	import away3d.core.traverse.ICollector;
	import away3d.entities.IEntity;

	/**
	 * LightNode is a space partitioning leaf node that contains a LightBase object.
	 */
	public class LightProbeNode extends EntityNode
	{
		private var _light:IEntity;

		/**
		 * Creates a new LightNode object.
		 * @param light The light to be contained in the node.
		 */
		public function LightProbeNode(light:IEntity)
		{
			super(light);
			_light = light;
		}

		/**
		 * @inheritDoc
		 */
		override public function acceptTraverser(traverser:ICollector):void
		{
			traverser.applyLightProbe(_light);
		}

		override public function isCastingShadow():Boolean
		{
			return false;
		}
	}
}
