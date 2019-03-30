package spaceshiptHunt.entities
{
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	import spaceshiptHunt.entities.BodyInfo;
	import DDLS.ai.DDLSEntityAI;
	import spaceshiptHunt.level.Environment;
	import nape.geom.Vec2;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.extensions.lighting.LightStyle;
	import starling.textures.Texture;
	
	public class Entity extends BodyInfo
	{
		public var pathfindingAgent:DDLSEntityAI;
		static protected var pathfindingAgentSafeDistance:Number = 30;
		protected var pathUpdateInterval:int = 48;
		
		public function Entity(position:Vec2)
		{
			super(position);
			pathfindingAgent = new DDLSEntityAI();
			pathfindingAgent.x = position.x;
			pathfindingAgent.y = position.y;
			graphics = new Sprite();
		}
		
		override public function init(bodyDescription:Object):void
		{
			super.init(bodyDescription);
			BodyInfo.list.push(this);
			var child:Image;
			for (var i:int = 0; i < bodyDescription.children.length; i++)
			{
				child = new Image(Environment.current.assetsLoader.getTexture(bodyDescription.children[i].textureName));
				var normalMap:Texture = Environment.current.assetsLoader.getTexture(bodyDescription.children[i].textureName + "_n");
				var lightStyle:LightStyle = new LightStyle(normalMap);
				lightStyle.light = Environment.current.light;
				child.style = lightStyle;
				child.x = bodyDescription.children[i].x;
				child.y = bodyDescription.children[i].y;
				child.pivotX = child.width / 2;
				child.pivotY = child.height / 2;
				(graphics as DisplayObjectContainer).addChild(child);
			}
			pathfindingAgent.radius = pathfindingAgentSafeDistance + Math.sqrt(body.bounds.width * body.bounds.width + body.bounds.height * body.bounds.height) / 2;
			pathfindingAgent.buildApproximation();
			pathfindingAgent.radius -= pathfindingAgentSafeDistance;
			Environment.current.navMesh.insertObject(pathfindingAgent.approximateObject);
		}
		
		override public function syncGraphics():void
		{
			super.syncGraphics();
			pathfindingAgent.x = body.position.x;
			pathfindingAgent.y = body.position.y;
			var dirNorm:Vec2 = Vec2.fromPolar(1, body.rotation - Math.PI / 2);
			pathfindingAgent.dirNormX = dirNorm.x;
			pathfindingAgent.dirNormY = dirNorm.y;
			dirNorm.dispose();
			pathfindingAgent.approximateObject.x = body.position.x + body.velocity.x / 2;
			pathfindingAgent.approximateObject.y = body.position.y + body.velocity.y / 2;
		}
		
		override public function dispose():void 
		{
			(graphics as DisplayObjectContainer).removeChildren(0, -1, true);
			super.dispose();
		}
		
		CONFIG::debug
		{
			import DDLSDebug.view.DDLSView;		
			public function drawDebug(canvas:DDLSView):void
			{
				canvas.drawEntity(pathfindingAgent, false);
			}
		}
	}

}