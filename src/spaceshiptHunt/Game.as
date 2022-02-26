package spaceshiptHunt
{
	include "CompilerConfig.as";
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.system.ApplicationDomain;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import input.Key;
	import io.arkeus.ouya.ControllerInput;
	import nape.geom.Vec2;
	import spaceshiptHunt.controls.DashJoystick;
	import spaceshiptHunt.controls.Flightstick;
	import spaceshiptHunt.controls.PlayerController;
	import spaceshiptHunt.controls.TouchJoystick;
	import spaceshiptHunt.entities.Player;
	import spaceshiptHunt.level.Environment;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.*;
	import starling.utils.SystemUtil;
	
	CONFIG::isDebugMode
	{
		import spaceshiptHuntDevelopment.level.LevelEditor;
	}
	
	//import avm2.intrinsics.memory.sf32;
	//import avm2.intrinsics.memory.si32;
	//import avm2.intrinsics.memory.lf32;
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Game extends Sprite
	{
		public static var HUD:Sprite;
		public static var spaceshipsLayer:Sprite;
		public static var underSpaceshipsLayer:Sprite;
		public static var aboveSpaceshipsLayer:Sprite;
		private var buttonsDisplay:Sprite;
		private var gameEnvironment:Environment;
		private var playerController:PlayerController;
		private var joystick:DashJoystick;
		private var crossTarget:Image;
		private var shootButton:Flightstick;
		private var background:Image;
		private var touches:Vector.<Touch> = new Vector.<Touch>();
		private var backgroundMusic:SoundChannel;
		private var volume:Number = 0.08;
		
		public function Game()
		{
			init();
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//initialization functions		
		public function init():void
		{
			//var ba:ByteArray = new ByteArray();
			//ba.endian = Endian.LITTLE_ENDIAN;
			
			//for (var j:Number = 1; j <= 16; j++) 
			//{
			//ba.position = 0;
			//ba.writeFloat(j);
			//ba.position = 0;
			//trace("    ");
			//trace(ba.readFloat());
			//trace(ba[0], ba[1], ba[2],ba[3]);
			//var kill:int = 9 ;
			//	trace( (ba[3] << kill) >> (kill+5));
//trace(ba[0] | ba[1] | ba[3]<<5 | ba[2]);	
			//		}
//ba.writeFloat(0);
//ba.writeFloat(1);			
			aboveSpaceshipsLayer = new Sprite();
			spaceshipsLayer = new Sprite();
			underSpaceshipsLayer = new Sprite();
			addChild(underSpaceshipsLayer);
			addChild(spaceshipsLayer);
			addChild(aboveSpaceshipsLayer);
			aboveSpaceshipsLayer.touchable = false;
			setupHUD();
			CONFIG::isReleaseMode
			{
				gameEnvironment = new Environment();
				//	spaceshipsLayer.touchable = false;
			}
			CONFIG::isDebugMode
			{
				gameEnvironment = new LevelEditor();
			}
			var atlaseNum:int = 1;
			for (var i:int = 0; i < atlaseNum; i++)
			{
				Environment.current.assetsLoader.enqueue("grp/textureAtlases" + i + ".xml");
				Environment.current.assetsLoader.enqueue("grp/textureAtlases" + i + ".atf");
			}
			Environment.current.assetsLoader.enqueue("grp/concrete_baked.atf");
			Environment.current.assetsLoader.enqueue("grp/concrete_baked_n.atf");
			gameEnvironment.loadLevel("Level1Test", onFinishLoading);
		}
		
		private function onFinishLoading():void
		{
			Starling.current.stage.addEventListener(Event.RESIZE, stageResize);
			background = new Image(Environment.current.assetsLoader.getTexture("stars"));
			background.tileGrid = new Rectangle();
			underSpaceshipsLayer.addChildAt(background, 0);
			var backgroundRatio:Number = Math.ceil(Math.sqrt(stage.stageHeight * stage.stageHeight + stage.stageWidth * stage.stageWidth) / 512) * 2;
			background.scale = backgroundRatio - 0.5; //* 2;
			spaceshipsLayer.addChild(Environment.current.light);
			crossTarget = new Image(Environment.current.assetsLoader.getTexture("crossTarget"));
			underSpaceshipsLayer.addChild(crossTarget);
			Key.init(stage);
			if (SystemUtil.isDesktop)
			{
				ControllerInput.initialize(Starling.current.nativeStage);
			}
			shootButton = new Flightstick(true);
			buttonsDisplay.addChild(shootButton);
			playerController = new PlayerController(Player.current, joystick, shootButton, crossTarget);
			Starling.current.nativeStage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullscreen);
			if (SystemUtil.isDesktop && CONFIG::isReleaseMode)
			{
				toggleFullscreen();
			}
			else
			{
				resizeHUD();
			}
			shootButton.addEventListener(TouchEvent.TOUCH, onShootButtonTouch);
			addEventListener(Event.ENTER_FRAME, enterFrame);
			Key.addKeyUpCallback(Keyboard.F11, toggleFullscreen);
			Key.addKeyUpCallback(Keyboard.ESCAPE, toggleFullscreen);
			gameEnvironment.assetsLoader.enqueueWithName("audio/Nihilore.mp3", "music");
			underSpaceshipsLayer.addEventListener(TouchEvent.TOUCH, onTouch);
			CONFIG::isDebugMode
			{
				//	gameEnvironment.paused = true;
				spaceshipsLayer.addEventListener(TouchEvent.TOUCH, onTouch);
				if (gameEnvironment.paused)
				{
					gameEnvironment.syncGraphics();
				}
			}
			gameEnvironment.assetsLoader.loadQueue(function onProgress(ratio:Number):void
			{
				if (ratio == 1.0)
				{
					backgroundMusic = Environment.current.assetsLoader.getSound("music").play(0, 7);
					backgroundMusic.soundTransform = new SoundTransform(volume);
				}
			})
			//	PhysicsParticle.fill.cache();
		}
		
		protected function setupHUD():void
		{
			HUD = new Sprite();
			buttonsDisplay = new Sprite();
			joystick = new DashJoystick();
			HUD.touchable = false;
			addChild(HUD);
			addChild(buttonsDisplay);
			buttonsDisplay.addChild(joystick);
		}
		
		//-----------------------------------------------------------------------------------------------------------------------------------------
		//runtime functions
		
		private function enterFrame(event:EnterFrameEvent, passedTime:Number):void
		{
			//Starling.current.juggler.advanceTime(event.passedTime);
			//some strange bug or maybe I optimize faster than the speed of light
			if (event.passedTime > 0)
			{
				gameEnvironment.update(passedTime);
				if (!gameEnvironment.paused)
				{
					playerController.update();
					adjustParallaxBackground();
				}
			}
		}
		
		private function adjustParallaxBackground():void
		{
			var parallaxRatio:Number = 0.5;
			var playerPos:Vec2 = Player.current.body.position;
			background.x = playerPos.x - (playerPos.x * parallaxRatio) % 512 - background.width / 2;
			background.y = playerPos.y - (playerPos.y * parallaxRatio) % 512 - background.height / 2;
		}
		
//-----------------------------------------------------------------------------------------------------------------------------------------
		//event functions	
		
		protected function onFullscreen(e:FullScreenEvent):void
		{
			if (e.fullScreen)
			{
				Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, playerController.onMouseMove);
			}
			else
			{
				Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_MOVE, playerController.onMouseMove);
			}
		}
		
		protected function toggleFullscreen():void
		{
			var flashStage:Stage = Starling.current.nativeStage;
			if (flashStage.displayState == StageDisplayState.NORMAL)
			{
				flashStage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				flashStage.mouseLock = true;
			}
			else
			{
				flashStage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		public function onFocusReturn():void
		{
			playerController.onFocusReturn();
			Key.reset();
		}
		
		private function onTouch(e:TouchEvent):void
		{
			e.getTouches(underSpaceshipsLayer, null, touches);
			while (touches.length > 0)
			{
				var touch:Touch = touches.pop();
				playerController.handleGameAreaTouch(touch);
				gameEnvironment.handleGameAreaTouch(e);
			}
		}
		
		protected function onShootButtonTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(shootButton);
			if (touch)
			{
				if (touch.phase == TouchPhase.ENDED)
				{
					Player.current.stopShooting();
				}
				else if (touch.phase == TouchPhase.BEGAN)
				{
					Player.current.startShooting();
				}
			}
		}
		
		protected function resizeHUD():void
		{
			joystick.x = joystick.radios * 2 + 20;
			joystick.y = stage.stageHeight - 15;
			shootButton.x = stage.stageWidth - 20;
			shootButton.y = stage.stageHeight - 15;
		}
		
		private function stageResize(e:ResizeEvent = null):void
		{
			stage.stageWidth = e.width;
			stage.stageHeight = e.height;
			Starling.current.viewPort.width = e.width;
			Starling.current.viewPort.height = e.height;
			var jotstickRadios:Number = Capabilities.screenDPI;
			if (SystemUtil.isDesktop)
			{
				jotstickRadios *= 1;
			}
			else
			{
				jotstickRadios *= 0.4;
			}
			joystick.radios = jotstickRadios;
			shootButton.radios = jotstickRadios;
			resizeHUD();
		}
	
	}
}