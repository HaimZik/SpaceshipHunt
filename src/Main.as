package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	import flash.system.Capabilities;
	import input.Key;
	import spaceshiptHunt.Game;
	import starling.core.Starling;
	import starling.utils.SystemUtil;
	
	/**
	 * ...
	 * @author Haim
	 */
	public class Main extends Sprite
	{
		private var gameEngine:Starling;
		
		public function Main()
		{
			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			Starling.multitouchEnabled = true;
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
			gameEngine = new Starling(Game, stage, null, null, "auto", SystemUtil.isDesktop?"auto":"baselineExtended");
			if (SystemUtil.isDesktop)
			{
				gameEngine.showStats = true;
				if (!Capabilities.isDebugger)
				{
					gameEngine.antiAliasing = 4;
				}
			}
			//gameEngine.start();
			stage.addEventListener(Event.ACTIVATE, function(e:Event):void
			{
				trace("ACTIVATE");
				gameEngine.start();
				if (gameEngine.root)
				{
					(gameEngine.root as Game).onFocusReturn();
				}
			});
			stage.addEventListener(Event.DEACTIVATE, function(e:Event):void
			{
				trace("DEACTIVATE");
				gameEngine.stop(true);
				gameEngine.render();
			});
		}
	
	}
}