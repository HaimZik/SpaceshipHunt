package
{
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.ui.Keyboard;
	import input.Key;
	import io.arkeus.ouya.ControllerInput;
	import nape.geom.Vec2;
	import spaceshiptHunt.controls.PlayerController;
	import spaceshiptHunt.controls.TouchJoystick;
	import spaceshiptHunt.entities.Player;
	import spaceshiptHunt.level.Environment;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Mesh;
	import starling.display.Sprite;
	import starling.events.*;
	import starling.geom.Polygon;
	import starling.rendering.VertexData;
	import starling.utils.Color;
	import starling.utils.Pool;
	import starling.utils.SystemUtil;
	
	CONFIG::debug
	{
		import spaceshiptHuntDevelopment.level.LevelEditor;
	}
	
	/**
	 * ...
	 * @author Haim Shnitzer
	 */
	public class Game extends Sprite
	{
		
		private var gameEnvironment:Environment;
		private var player:Player;
		private var playerController:PlayerController;
		private var UIDisplay:Sprite;
		private var joystick:TouchJoystick;
		private var crossTarget:Image;
		private var shootButton:Image;
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
			var fakeReleaseMode:Boolean = false;
			var gameArea:Sprite = new Sprite();
			addChild(gameArea);
			setupUI();
			if (fakeReleaseMode || CONFIG::release)
			{
				gameEnvironment = new Environment(gameArea);
			}
			CONFIG::debug
			{
				if (!fakeReleaseMode)
				{
					gameEnvironment = new LevelEditor(gameArea);
				}
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
			player = Player.current;
			background = new Image(Environment.current.assetsLoader.getTexture("stars"));
			background.tileGrid = new Rectangle();
			gameEnvironment.mainDisplay.addChildAt(background, 0);
			var backgroundRatio:Number = Math.ceil(Math.sqrt(stage.stageHeight * stage.stageHeight + stage.stageWidth * stage.stageWidth) / 512) * 2;
			background.scale = backgroundRatio * 2;
			gameEnvironment.mainDisplay.addChild(Environment.current.light);
			crossTarget = new Image(Environment.current.assetsLoader.getTexture("crossTarget"));
			gameEnvironment.mainDisplay.addChild(crossTarget);
			Key.init(stage);
			ControllerInput.initialize(Starling.current.nativeStage);
			playerController = new PlayerController(Player.current, joystick, crossTarget);
			Starling.current.nativeStage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullscreen);
			if (SystemUtil.isDesktop && CONFIG::release)
			{
				toggleFullscreen();
			}
			shootButton = new Image(Environment.current.assetsLoader.getTexture("shootButton"));
			shootButton.alignPivot();
			UIDisplay.addChild(shootButton);
			resizeHUD();
			shootButton.addEventListener(TouchEvent.TOUCH, onShootButtonTouch);
			gameEnvironment.mainDisplay.addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(Event.ENTER_FRAME, enterFrame);
			Key.addKeyUpCallback(Keyboard.F11, toggleFullscreen);
			Key.addKeyUpCallback(Keyboard.ESCAPE, toggleFullscreen);
			gameEnvironment.assetsLoader.enqueueWithName("audio/Nihilore.mp3", "music");
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
		
		protected function setupUI():void
		{
			UIDisplay = new Sprite();
			joystick = new TouchJoystick();
			addChild(UIDisplay);
			UIDisplay.addChild(joystick);
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
		
		public function onFocusReturn():void
		{
			Key.reset();
			playerController.onFocusReturn();
		}
		
		private function onTouch(e:TouchEvent):void
		{
			e.getTouches(gameEnvironment.mainDisplay, null, touches);
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
					player.stopShooting();
				}
				else if (touch.phase == TouchPhase.BEGAN)
				{
					player.startShooting();
				}
			}
		}
		
		protected function resizeHUD():void
		{
			joystick.x = joystick.radios * 2 + 20;
			joystick.y = stage.stageHeight - 15;
			var shootIconRadios:Number = shootButton.texture.width;
			shootButton.x = stage.stageWidth- shootIconRadios / 2 - 30;
			shootButton.y = stage.stageHeight - shootIconRadios / 2 - 20;
		}
		
		private function stageResize(e:ResizeEvent = null):void
		{
			stage.stageWidth = e.width;
			stage.stageHeight = e.height;
			Starling.current.viewPort.width = e.width;
			Starling.current.viewPort.height = e.height;
			joystick.radios = int(Math.min(800, e.width, e.height) / 5);
			resizeHUD();
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
			background.x = player.body.position.x - (player.body.position.x * parallaxRatio) % 512 - background.width / 2;
			background.y = player.body.position.y - (player.body.position.y * parallaxRatio) % 512 - background.height / 2;
		}
	
	}
}