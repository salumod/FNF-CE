package;

import funkin.VideoState;
import openfl.display.BitmapData;
import cpp.Function;
import funkin.GameUI;
import flixel.group.FlxGroup;
import flixel.util.FlxSave;
import NGio;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import ui.AtlasMenuList;
import ui.MenuList;
import ui.OptionsState;
import ui.PreferencesState;
import ui.Prompt;
import ui.VolumeState;
import ui.GameplayState;

using StringTools;

#if discord_rpc
import Discord.DiscordClient;
#end
#if newgrounds
import io.newgrounds.NG;

#end

class MainMenuState extends MusicBeatState
{
	var menuItems:MainMenuList;

	var magenta:FlxSprite;
	var camFollow:FlxObject;
    var mouse:GameMouse;

	override function create()
	{
		if (!(FlxG.mouse.visible))
			{
				mouse = new GameMouse();
				mouse.qucklyADD();
				add(mouse);
			}
			
		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), FlxG.save.data.volume * FlxG.save.data.musicVolume);
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.17;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(Paths.image('menuDesat'));
		magenta.scrollFactor.x = bg.scrollFactor.x;
		magenta.scrollFactor.y = bg.scrollFactor.y;
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.x = bg.x;
		magenta.y = bg.y;
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		if (PreferencesState.preferences.get('flashing-menu'))
			add(magenta);
		// magenta.scrollFactor.set();

		menuItems = new MainMenuList();
		add(menuItems);
		
		menuItems.onChange.add(onMenuItemChange);
		menuItems.onAcceptPress.add(function(_)
		{
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);
		});

		menuItems.enabled = false; // disable for intro
		menuItems.createItem('story mode', function() startExitState(new StoryMenuState()));
		menuItems.createItem('freeplay', function() startExitState(new FreeplayState()));
		// addMenuItem('options', function () startExitState(new OptionMenu()));
		#if CAN_OPEN_LINKS
		var hasPopupBlocker = #if web true #else false #end;

		if (VideoState.seenVideo)
			menuItems.createItem('kickstarter', selectKickstarter);
		else
			menuItems.createItem('donate', selectDonate);
		#end
		menuItems.createItem('options', function() startExitState(new OptionsState()));
		// #if newgrounds
		// 	if (NGio.isLoggedIn)
		// 		menuItems.createItem("logout", selectLogout);
		// 	else
		// 		menuItems.createItem("login", selectLogin);
		// #end

		// center vertically
		var spacing = 160;
		var top = (FlxG.height - (spacing * (menuItems.length - 1))) / 2;
		for (i in 0...menuItems.length)
		{
			var menuItem = menuItems.members[i];
			menuItem.x = 0;
			menuItem.y = top + spacing * i;

			FlxTween.tween(menuItem, {x: 600}, 0.2, {ease: FlxEase.quadIn});
		}

		FlxG.cameras.reset(new SwagCamera());
		FlxG.camera.follow(camFollow, null, 0.06);
		// FlxG.camera.setScrollBounds(bg.x, bg.x + bg.width, bg.y, bg.y + bg.height * 1.2);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, "v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// if (GameplayMenu.getGameoption('watermark'))
		// 	{
				var version:FlxText = new FlxText(5, versionShit.y - 20, 0, "(Build NE v0.2.5)", 12);
		        version.scrollFactor.set();
		        version.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		        add(version);
			// }
		// NG.core.calls.event.logEvent('swag').send();

		super.create();
	}

	override function finishTransIn()
	{
		super.finishTransIn();

		menuItems.enabled = true;

		// #if newgrounds
		// if (NGio.savedSessionFailed)
		// 	showSavedSessionFailed();
		// #end
	}

	function onMenuItemChange(selected:MenuItem)
	{
		camFollow.setPosition(selected.getGraphicMidpoint().x, selected.getGraphicMidpoint().y);
	}

	#if newgrounds
	// function selectLogin()
	// {
	// 	openNgPrompt(NgPrompt.showLogin());
	// }

	// function selectLogout()
	// {
	// 	openNgPrompt(NgPrompt.showLogout());
	// }

	// function showSavedSessionFailed()
	// {
	// 	openNgPrompt(NgPrompt.showSavedSessionFailed());
	// }

	function selectDonate()
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
		#else
		FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
		#end
	}

	function selectKickstarter()
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', ["https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/", "&"]);
		#else
		FlxG.openURL('https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game/');
		#end
	}
	/**
	 * Calls openPrompt and redraws the login/logout button
	 * @param prompt 
	 * @param onClose 
	 */
	// public function openNgPrompt(prompt:Prompt, ?onClose:Void->Void)
	// {
	// 	var onPromptClose = checkLoginStatus;
	// 	if (onClose != null)
	// 	{
	// 		onPromptClose = function()
	// 		{
	// 			checkLoginStatus();
	// 			onClose();
	// 		}
	// 	}

	// 	openPrompt(prompt, onPromptClose);
	// }

	// function checkLoginStatus()
	// {
	// 	var prevLoggedIn = menuItems.has("logout");
	// 	if (prevLoggedIn && !NGio.isLoggedIn)
	// 		menuItems.resetItem("login", "logout", selectLogout);
	// 	else if (!prevLoggedIn && NGio.isLoggedIn)
	// 		menuItems.resetItem("logout", "login", selectLogin);
	// }
	#end

	public function openPrompt(prompt:Prompt, onClose:Void->Void)
	{
		menuItems.enabled = false;
		prompt.closeCallback = function()
		{
			menuItems.enabled = true;
			if (onClose != null)
				onClose();
		}

		openSubState(prompt);
	}

	function startExitState(state:FlxState)
	{
		menuItems.enabled = false; // disable for exit
		var duration = 0.4;
		menuItems.forEach(function(item)
		{
			if (menuItems.selectedIndex != item.ID)
			{
				FlxTween.tween(item, {x: item.x + 1200}, 0.2, {ease: FlxEase.quadInOut});
			}
			else
			{
				item.visible = false;
			}
		});

		new FlxTimer().start(duration, function(_) FlxG.switchState(state));
	}

	override function update(elapsed:Float)
	{
		FlxG.sound.music.volume = FlxG.save.data.volume * FlxG.save.data.musicVolume;
		// FlxG.camera.followLerp = CoolUtil.camLerpShit(0.06);

		if (_exiting)
			menuItems.enabled = false;

		if (controls.BACK && menuItems.enabled && !menuItems.busy)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), FlxG.save.data.volume * FlxG.save.data.SFXVolume);
			// FlxG.switchState(new CloseGameState());
		    FlxG.switchState(new TitleState());
		}

		super.update(elapsed);
	}
}

private class MainMenuList extends MenuTypedList<MainMenuItem>
{
	public var atlas:FlxAtlasFrames;

	public function new()
	{
		atlas = Paths.getSparrowAtlas('main_menu');
		super(Vertical);
	}

	public function createItem(x = 0.0, y = 0.0, name:String, callback, fireInstantly = false)
	{
		var item = new MainMenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		item.ID = length;

		return addItem(name, item);
	}

	override function destroy()
	{
		super.destroy();
		atlas = null;
	}
}

private class MainMenuItem extends AtlasMenuItem
{
	public function new(x = 0.0, y = 0.0, name, atlas, callback)
	{
		super(x, y, name, atlas, callback);
		scrollFactor.set();
	}

	override function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		// position by center
		centerOrigin();
		offset.copyFrom(origin);
	}
}
