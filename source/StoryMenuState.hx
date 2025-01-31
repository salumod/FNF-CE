package;

import openfl.Assets;
import haxe.Json;
import openfl.display.Preloader.DefaultPreloader;
import openfl.display.Stage;
#if discord_rpc
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import lime.net.curl.CURLCode;

using StringTools;

typedef WeekJson = {
	var weekData:Array<Dynamic>;
	var weekStageNames:Array<String>;
	var weekNames:Array<String>;
}

typedef ColorJson = {
	var weekColors:Array<FlxColor>;
	var songColors:Array<Int>;
}

class StoryMenuState extends MusicBeatState
{
	var scoreText:FlxText;
	var yellowBG:FlxSprite;
	var curDifficulty:Int = 1;

	public static var weekUnlocked:Array<Bool> = [true, true, true, true, true, true, true, true, true];

	var weekColors:Array<FlxColor> = [
		0xFFF9CF51,
		0x969271fd,
		0x91223344,
		0x86941653,
		0x9cfc96d7,
		0xa2a0d1ff,
		0x93ff78c0,
		0x93f6b604,
		0x91ff8949
	];

	var txtWeekTitle:FlxText;

	var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpWeekStage:FlxTypedGroup<MenuStages>;
	// var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var weekStage:MenuStages;
	
	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var txtDifficulty:FlxText;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	private var json_file:WeekJson;
	private var color_json_file:ColorJson;

	override function create()
	{
        json_file = haxe.Json.parse(Assets.getText('assets/data/weekList.json'));
		color_json_file = haxe.Json.parse(Assets.getText('assets/data/colorList.json'));

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'), FlxG.save.data.volume * FlxG.save.data.musicVolume);
		}

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		
		grpWeekStage = new FlxTypedGroup<MenuStages>();
		add(grpWeekStage);

		yellowBG = new FlxSprite(0, 0).makeGraphic(500, FlxG.height);
		yellowBG.color = 0xFFF9CF51;
		yellowBG.alpha = 0.3;
		add(yellowBG);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);
		
		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		var blackBarDOWNThingie:FlxSprite = new FlxSprite(0, FlxG.height * 0.86).makeGraphic(FlxG.width, 110, FlxColor.BLACK);
		add(blackBarDOWNThingie);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...json_file.weekData.length)
		{
			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, i);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.x = 10;
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.antialiasing = true;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (!weekUnlocked[i])
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x).loadGraphic(Paths.image('lock'));
				lock.ID = i;
				lock.antialiasing = true;
				grpLocks.add(lock);
			}
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(410, 630);
		leftArrow.frames = Paths.getSparrowAtlas('arrow');
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		txtDifficulty = new FlxText(leftArrow.x + 150, 0);
		txtDifficulty.text = "NORMAL";
		txtDifficulty.setFormat(Paths.font("Difficult.ttf"), 84);
		changeDifficulty();

		difficultySelectors.add(txtDifficulty);

		rightArrow = new FlxSprite(txtDifficulty.x + txtDifficulty.width + 25, leftArrow.y);
		rightArrow.frames = Paths.getSparrowAtlas('arrow');
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		txtTracklist = new FlxText(-300, 400, 0, "Tracks", 40);
		txtTracklist.alignment = CENTER;
		txtTracklist.setFormat(Paths.font("Funkin/Funkin.ttf"), 32);
		txtTracklist.color = 0xFFe55777;

		add(txtTracklist);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		super.create();
	}

	override function update(elapsed:Float)
	{
		FlxG.sound.music.volume = FlxG.save.data.volume * FlxG.save.data.musicVolume;

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.5);
		FlxTween.cancelTweensOf(yellowBG);
		yellowBG.color = FlxColor.interpolate(yellowBG.color, weekColors[curWeek % weekColors.length], CoolUtil.camLerpShit(0.045));

		scoreText.text = "WEEK SCORE:" + Math.round(lerpScore);

		txtWeekTitle.text = json_file.weekNames[curWeek].toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		FlxG.watch.addQuick('bg color', yellowBG.color);

		difficultySelectors.visible = weekUnlocked[curWeek];

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek)
			{
				if (controls.UI_UP_P)
				{
					changeWeek(-1);
				}

				if (controls.UI_DOWN_P)
				{
					changeWeek(1);
				}

				if (controls.UI_RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.UI_LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.UI_RIGHT_P)
					changeDifficulty(1);
				if (controls.UI_LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'), FlxG.save.data.volume * FlxG.save.data.SFXVolume);
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (weekUnlocked[curWeek])
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'), FlxG.save.data.volume * FlxG.save.data.SFXVolume);

				grpWeekText.members[curWeek].startFlashing();
				stopspamming = true;
			}

			PlayState.storyPlaylist = json_file.weekData[curWeek];
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = "";

			switch (curDifficulty)
			{
				case 0:
					diffic = '-easy';
				case 2:
					diffic = '-hard';
			}

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
			});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		txtDifficulty.offset.x = 0;

		switch (curDifficulty)
		{
			case 0:
				txtDifficulty.text = "EASY";
				txtDifficulty.color = FlxColor.LIME;
				txtDifficulty.offset.x = 0;
			case 1:
				txtDifficulty.text = "NORMAL";
				txtDifficulty.color = FlxColor.YELLOW;
				txtDifficulty.offset.x = 30;
			case 2:
				txtDifficulty.text = "HARD";
				txtDifficulty.color = FlxColor.RED;
				txtDifficulty.offset.x = 0;
			case 3:
				txtDifficulty.text = "ERECT";
				txtDifficulty.color = FlxColor.PURPLE;
				txtDifficulty.offset.x = 0;
		}

		txtDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		txtDifficulty.y = leftArrow.y - 100;
		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);

		FlxTween.tween(txtDifficulty, {y: leftArrow.y, alpha: 1}, 0.07);
	}

	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= json_file.weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = json_file.weekData.length - 1;

		weekStage = new MenuStages(-1000, -500, json_file.weekStageNames[curWeek]);
		grpWeekStage.add(weekStage);
		
		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && weekUnlocked[curWeek])
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'), FlxG.save.data.volume * FlxG.save.data.SFXVolume);

		updateText();
	}

	function updateText()
	{
		txtTracklist.text = "Tracks\n";

		var stringThing:Array<String> = json_file.weekData[curWeek];

		for (i in stringThing)
		{
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= 0;
		txtTracklist.y -= 0;

		intendedScore = Highscore.getWeekScore(curWeek, curDifficulty);
	}
}
