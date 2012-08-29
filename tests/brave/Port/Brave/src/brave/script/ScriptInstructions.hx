package brave.script;
import brave.BraveAssets;
import brave.GameState;
import brave.sprites.map.Character;
import brave.sprites.TextSprite;
import brave.StringEx;
import haxe.Log;
import haxe.Timer;
import nme.errors.Error;
import nme.media.Sound;
import nme.media.SoundChannel;

/**
 * ...
 * @author 
 */

class ScriptInstructions 
{
	var scriptThread:ScriptThread;

	public function new(scriptThread:ScriptThread) 
	{
		this.scriptThread = scriptThread;
	}

	@Opcode(0x01, "SL")
	public function FUNCTION_DEF(functionName:String, nextFunctionOffset:Int):Void {
		Log.trace(Std.format("FUNCTION_DEF: $functionName, $nextFunctionOffset"));
	}
	
	
	// 00-1F
	/**
	 * Jumps
	 * 
	 * @param	left
	 * @param	right
	 * @param	operation
	 * @param	jumpOffset
	 */
	@Opcode(0x02, "PP9L")
	//@Unimplemented(1)
	public function JUMP_IF(left:Int, right:Int, operation:Int, jumpOffset:Int):Void {
		var result:Bool = false;
		
		switch (operation) {
			case 0: result = (left != right);
			case 1: result = (left == right);
			case 2: result = (left >= right);
			case 3: result = (left <= right);
			case 4: result = (left > right);
			case 5: result = (left < right);
			default: throw(new Error("Invalid operation"));
		}

		

		// Skip block
		if (result) {
			scriptThread.jump(jumpOffset);
		}
		/*
		else {
			scriptThread.pushStack(jumpOffset);
		}
		*/
	}

	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x04, "L")
	public function JUMP_ALWAYS(jumpOffset:Int):Void {
		scriptThread.jump(jumpOffset);
	}

	/**
	 * 
	 * @param	done
	 * @param	value
	 */
	@Opcode(0x05, "<4") // Return?
	public function BLOCK_ENDIF(done:Void -> Void, value:Int) {
		//scriptThread.jump(scriptThread.popStack());
		//scriptThread.jump(8);

		ANIMATION_WAIT(done);
	}

	/**
	 * 
	 * @param	a
	 * @param	b
	 * @param	c
	 * @param	d
	 */
	@Opcode(0x03, "ss1L")
	public function OP_03(a, b, c, d) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x08, "")
	@Unimplemented(1)
	public function DEBUG_MESSAGE() {
		
	}

	/**
	 * 
	 */
	@Opcode(0x09, "")
	@Unimplemented(1)
	public function OP_09() {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x0A, "P")
	@Unimplemented(1)
	public function OP_0A(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x0B, "P")
	@Unimplemented(1)
	public function OP_0B(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x0C, "P")
	@Unimplemented(1)
	public function OP_0C(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x0D, "PP")
	@Unimplemented(1)
	public function OP_0D(a, b) {
		
	}
	
	/**
	 * 
	 * @param	variable
	 * @param	operator
	 * @param	rightValue
	 */
	@Opcode(0x0F, "v7P")
	@Unimplemented(1)
	public function ARITMETIC_OP(variable:Variable, operator:Int, rightValue:Int) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x10, "11s")
	@Unimplemented(1)
	public function OP_10() {
		
	}
	
	/**
	 * 
	 * @param	variable
	 */
	@Opcode(0x11, "v")
	@Unimplemented(1)
	public function VAR_INCREMENT(variable:Variable):Void {
		variable.setValue(variable.getValue() + 1);
	}
	
	/**
	 * 
	 * @param	variable
	 */
	@Opcode(0x12, "v")
	@Unimplemented(1)
	public function VAR_DECREMENT(variable:Variable):Void {
		variable.setValue(variable.getValue() - 1);
	}
	
	/**
	 * 
	 * @param	variable
	 * @param	maxValue
	 */
	@Opcode(0x13, "vP")
	@Unimplemented(1)
	public function RANDOM(variable:Variable, maxValue:Int) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x14, "PP")
	@Unimplemented(1)
	public function OP_14(a, b) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x15, "12")
	@Unimplemented(1)
	public function OP_15(a, b) {
		
	}
	
	/**
	 * 
	 * @param	index
	 */
	@Opcode(0x17, "P")
	@Unimplemented(1)
	public function MUSIC_PLAY(index:Int) {
		MUSIC_STOP();
		var fileName:String = StringEx.sprintf('bgm%02dgm', [index]);
		//if (fileName == "bgm14gm")
		{
			var music:Sound = BraveAssets.getMusic(fileName);
			Log.trace("MUSIC_PLAY:" + fileName);
			scriptThread.gameState.musicChannel = music.play();
		}
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x18, "P")
	@Unimplemented(1)
	public function OP_18(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x19, "PP")
	@Unimplemented(1)
	public function OP_19(a, b) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x1A, "P")
	@Unimplemented(1)
	public function OP_1A(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x1B, "PP")
	@Unimplemented(1)
	public function OP_1B(a, b) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x1C, "")
	@Unimplemented(1)
	public function MUSIC_STOP():Void {
		if (scriptThread.gameState.musicChannel != null) {
			scriptThread.gameState.musicChannel.stop();
		}		
	}
	
	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x1D, "s")
	@Unimplemented(1)
	public function COMMENT(text:String) {
		Log.trace(Std.format("COMMENT: '${text}'"));
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x1E, "sP")
	@Unimplemented(1)
	public function OP_1E(a, b) {
		
	}
	

	// 20-33
	@Opcode(0x21, "s") // Delay?
	public function SCRIPT(scriptName:String) {
		Log.trace(Std.format("SCRIPT('${scriptName}')"));
		scriptThread.setScript(Script.getScriptWithName(scriptName));
	}
	
	@Opcode(0x22, "")
	@Unimplemented
	public function OP_22() {
		
	}
	
	@Opcode(0x23, "")
	@Unimplemented
	public function OP_23() {
		
	}
	
	/**
	 * 
	 * @param	mapName
	 */
	@Opcode(0x24, "s")
	@Unimplemented
	public function MAP_SET(mapName:String):Void {
		scriptThread.gameState.setMap(mapName);
	}
	
	@Opcode(0x25, "sP")
	@Unimplemented
	public function OP_25(a, b) {
		
	}
	
	@Opcode(0x26, "PPPss")
	@Unimplemented
	public function OP_26(a, b, c, d, e) {
		
	}
	
	@Opcode(0x27, "PPPPPss")
	@Unimplemented
	public function OP_27(a, b, c, d, e, f, g) {
		
	}
	
	/**
	 * 
	 * @param	imageName
	 */
	@Opcode(0x28, "s")
	public function BACKGROUND_SET_IMAGE(imageName:String):Void {
		scriptThread.gameState.setBackgroundImage(imageName);
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 * @param	c
	 */
	@Opcode(0x29, "PPs")
	@Unimplemented
	public function OP_29(a:Int, b:Int, c:String) {
		
	}
	
	/**
	 * 
	 * @param	color
	 */
	@Opcode(0x2A, "4")
	public function BACKGROUND_SET_COLOR(color:Int) {
		scriptThread.gameState.setBackgroundColor(color);
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x2B, "4")
	@Unimplemented
	public function OP_2B(a:Int) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x2C, "4")
	@Unimplemented
	public function OP_2C(a:Int) {
		
	}
	
	/**
	 * 
	 * @param	effectType
	 */
	@Opcode(0x2D, "P")
	@Unimplemented
	public function SET_BACKGROUND_EFFECT(effectType:Int) {
		scriptThread.gameState.setBackgroundEffect(effectType);
	}
	
	/**
	 * 
	 */
	@Opcode(0x2E, "-")
	@Unimplemented
	public function OP_2E() {
		
	}
	
	/**
	 * 
	 * @param	voice
	 * @param	title
	 * @param	text
	 */
	@Opcode(0x2F, "<sss")
	public function TEXT_PUT(done:Void -> Void, voice:String, title:String, text:String) {
		//Log.trace(Std.format("TEXT_PUT(${voice}, ${title}, ${text})"));
		
		this.TEXT_PUT_WITH_FACE(done, -2, voice, title, text);
	}
	
	/**
	 * 
	 * @param	done
	 * @param	type
	 */
	@Opcode(0x30, "<P")
	public function TRANSITION(done:Void -> Void, type:Int) {
		scriptThread.gameState.transition(done, type);
	}
	
	/**
	 * 
	 * @param	done
	 * @param	time
	 */
	@Opcode(0x31, "<P")
	public function FADE_TO_MAP(done:Void -> Void, time:Int) {
		scriptThread.gameState.fadeToMap(done, time);
	}
	

	// 34-42
	@Opcode(0x35, "s")
	@Unimplemented
	public function TITLE_SET(title:String) {
		
	}
	
	@Opcode(0x36, "s")
	@Unimplemented
	public function OP_36(text:String) {
		
	}
	
	@Opcode(0x37, "")
	@Unimplemented
	public function OP_37() {
		
	}
	
	@Opcode(0x38, "Psss")
	@Unimplemented
	public function OP_38(a, b, c, d) {
		
	}
	
	@Opcode(0x39, "<Psss")
	public function TEXT_PUT_WITH_FACE(done:Void -> Void, faceId:Int, voice:String, title:String, text:String) {

		var voiceChannel:SoundChannel = null;
		if (voice != "") {
			voiceChannel = BraveAssets.getVoice(voice).play();
		}
		var textSprite:TextSprite = scriptThread.gameState.rootClip.ui.textSprite;
		
		textSprite.setTextAndEnable(faceId, title, text, function() {
			GameState.waitClickOrKeyPress(function() {
				textSprite.endText();
				if (voiceChannel != null) voiceChannel.stop();
				done();
			});
		});
	}
	
	@Opcode(0x3A, "PPPsss")
	@Unimplemented
	public function OP_3A(v0, v1, v2, v3, v4, v5) {
		
	}
	
	@Opcode(0x3B, "")
	@Unimplemented
	public function OP_3B() {
		
	}
	
	@Opcode(0x3C, "")
	@Unimplemented
	public function OP_3C() {
		
	}

	/**
	 * 
	 */
	@Opcode(0x92, "")
	@Unimplemented
	public function END():Int {
		scriptThread.clearStack();
		return -2;
	}

	@Opcode(0x07, "") // FLOW. Return?
	@Unimplemented
	public function ENABLE_PLAY() {
		scriptThread.gameState.rootClip.ui.textSprite.disable(function() {
			
		});
		scriptThread.gameState.getCharacter(0).enableMovement = true;
		return -2;
	}
	
	/**
	 * 
	 */
	@Opcode(0x3D, "<")
	@Unimplemented
	public function ANIMATION_WAIT(done:Void -> Void) {
		scriptThread.gameState.rootClip.ui.textSprite.disable(function() {
			var count = 0;
			
			for (character in scriptThread.gameState.getAllCharacters()) {
				count++;
			}
			for (character in scriptThread.gameState.getAllCharacters()) {
				character.actionDone(function() {
					count--;
					if (count == 0) {
						Log.trace("ANIMATION_WAIT.Done!");
						done();
					}
				});
			}
		});
	}
	
	/**
	 * 
	 * @param	unk
	 * @param	title
	 */
	@Opcode(0x3E, "Ps")
	@Unimplemented
	public function OPTION_START(unk:Int, title:String) {
		
	}
	
	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x3F, "s")
	@Unimplemented
	public function OPTION_ITEM(text:String) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x40, "")
	@Unimplemented
	public function OPTION_SHOW() {
		scriptThread.gameState.variables[0].setValue(1);
	}
	
	/**
	 * 
	 */
	@Opcode(0x41, "PP")
	@Unimplemented
	public function OP_41() {
		
	}
	

	// 43--4F

	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x44, "s") // X40 = 0
	@Unimplemented
	public function TEXT_PUT_44(text:String) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x45, "") // X40 = 1
	@Unimplemented
	public function OP_45() {
		
	}
	
	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x46, "s") // X40 = 2
	@Unimplemented
	public function OP_46(text:String) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x47, "")
	@Unimplemented
	public function OP_47() {
		
	}
	
	/**
	 * 
	 * @param	title
	 */
	@Opcode(0x48, "s")
	@Unimplemented
	public function TITLE_SHOW(title:String) {
		
	}
	
	/**
	 * 
	 * @param	v0
	 * @param	v1
	 * @param	v2
	 * @param	v3
	 * @param	v4
	 * @param	v5
	 */
	@Opcode(0x49, "PPPPPP")
	public function OP_49(v0, v1, v2, v3, v4, v5) {
		
	}
	
	@Opcode(0x4A, "PPPP") // Id, X, Y, Attribute (255 blocked, 0 no blocked)
	public function MAP_CELL_SET_ATTRIBUTE_FOR(charaId:Int, x:Int, y:Int, attribute:Int) {
		
	}
	
	@Opcode(0x4B, "PPPPPP")
	public function OP_4B(a, b, c, d, e, f) {
		
	}
	
	@Opcode(0x4C, "PPPP")
	public function OP_4C(a, b, c, d) {
		
	}
	
	@Opcode(0x4D, "PPPP")
	public function OP_4D(a, b, c, d) {
		
	}
	
	@Opcode(0x4E, "PPPP")
	public function TRIGGER_SET(charaId:Int, x:Int, y:Int, eventId:Int) {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.setEvent(scriptThread, x, y, eventId);
	}
	

	/**
	 * Adds a character to the party.
	 * 
	 * @param	partyId
	 * @param	charaId
	 */
	// 50-91
	@Opcode(0x51, "PP")
	public function PARTY_SET_CHARA(partyComponentId:Int, charaId:Int) {
		
	}
	
	@Opcode(0x52, "P")
	public function UNK_52(a) {
		
	}
	
	@Opcode(0x54, "vP")
	public function UNK_54(variable:Variable, value:Int) {
		
	}
	
	@Opcode(0x55, "vP")
	public function CHARA_SET(charaId:Variable, index:Int) {
		
	}
	
	@Opcode(0x56, "v")
	public function UNK_56(variable:Variable) {
		
	}
	
	@Opcode(0x53, "PPPPP") // Id, 0, X, Y, Direction
	public function PLAYER_SPAWN(charaId:Int, unk:Int, x:Int, y:Int, direction:Int) {
		scriptThread.gameState.charaSpawn(charaId, 0, unk, x, y, direction);
	}
	
	@Opcode(0x57, "PPPPP") // Id, 0, X, Y, Direction
	public function CHARA_SPAWN(charaId:Int, unk:Int, x:Int, y:Int, direction:Int) {
		scriptThread.gameState.charaSpawn(charaId, 0, unk, x, y, direction);
	}
	
	@Opcode(0x67, "PPPPPP") // Id, ???, 0, X, Y, Direction
	public function ENEMY_SPAWN(charaId:Int, type:Int, unk:Int, x:Int, y:Int, direction:Int) {
		scriptThread.gameState.charaSpawn(charaId, type, unk, x, y, direction);
	}
	
	@Opcode(0x58, "")
	public function UNK_58() {
		
	}
	
	@Opcode(0x59, "PPP") // X, Y, Direction
	public function GROUP_MOVE(x:Int, y:Int, direction:Int) {
		
	}
	
	@Opcode(0x5A, "vP")
	public function UNK_5A(variable:Variable, a:Int) {
		
	}
	
	@Opcode(0x5B, "P")
	public function UNK_5B(a) {
		
	}
	
	@Opcode(0x5C, "PP")
	public function UNK_5C(a, b) {
		
	}
	
	@Opcode(0x5D, "PP")
	public function UNK_5D(a, b) {
		
	}
	
	@Opcode(0x5E, "PP")
	public function UNK_5E(a, b) {
		
	}
	
	@Opcode(0x5F, "PP")
	public function UNK_5F(a, b) {
		
	}
	
	@Opcode(0x60, "P")
	public function UNK_60(a) {
		
	}
	
	@Opcode(0x61, "P") // Increment up to 999999999?
	public function UNK_61(a) {
		
	}
	
	@Opcode(0x62, "P")
	public function UNK_62(a) {
		
	}
	
	@Opcode(0x63, "P")
	public function UNK_63(a) {
		
	}
	
	@Opcode(0x64, "P")
	public function UNK_64(a) {
		
	}
	
	@Opcode(0x65, "") // memset(byte_518558, 0x1010101u, 40u);
	public function UNK_65() {
		
	}
	
	@Opcode(0x66, "PPPPP")
	public function UNK_66(a, b, c, d, e) {
		
	}
	
	@Opcode(0x68, "PPPPPPPP")
	public function UNK_68(v0, v1, v2, v3, v4, v5, v6, v7) {
		
	}
	
	@Opcode(0x69, "PP")
	public function UNK_69(a, b) {
		
	}
	
	@Opcode(0x6A, "P")
	public function UNK_6A(a) {
		
	}
	
	@Opcode(0x6B, "PP")
	public function UNK_6B(a, b) {
		
	}
	
	@Opcode(0x6C, "") // = 2
	public function UNK_6C() {
		
	}
	
	@Opcode(0x6D, "") // = 4
	public function UNK_6D() {
		
	}
	
	@Opcode(0x6E, "") // = 0
	public function UNK_6E() {
		
	}
	
	@Opcode(0x6F, "P")
	public function UNK_6F(a) {
		
	}
	
	@Opcode(0x70, "PP")
	public function UNK_70(a, b) {
		
	}
	
	@Opcode(0x71, "PPPPPPPPP")
	public function ENEMY_TRIGGER_ON_KILL(charaId:Int, eventId:Int, c:Int, d:Int, e:Int, f:Int, g:Int, h:Int, i:Int) {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.setKillEventId(scriptThread, eventId);
	}
	
	@Opcode(0x72, "PP")
	public function UNK_72(a, b) {
		
	}
	
	@Opcode(0x73, "PP")
	public function UNK_73(a, b) {
		
	}
	
	@Opcode(0x74, "PPP")
	@Unimplemented
	public function UNK_74(a, b, c) {
		
	}
	
	@Opcode(0x75, "P")
	public function CHARA_START(charaId:Int) {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.actionStart();
	}
	
	@Opcode(0x80, "PP")
	@Unimplemented
	public function CHARA_SET_SPECIAL_ANIMATION(charaId:Int, specialAnimationId:Int) {
		
	}
	
	@Opcode(0x90, "P")
	public function CHARA_DONE(charaId:Int):Void {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.actionDone(function() {
			
		});
	}
	
	@Opcode(0x76, "PPP")
	public function CHARA_MOVE_TO(charaId:Int, x:Int, y:Int) {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.actionMoveTo(x * 40, y * 40);
	}
	
	@Opcode(0x77, "PP")
	public function CHARA_FACE_TO(charaId:Int, direction:Int) {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.actionFaceTo(direction);
	}

	/**
	 * 
	 * @param	charaId
	 * @param	direction
	 * @param	emoji       PG_MAIN
	 */
	@Opcode(0x8B, "PPP")
	@Unimplemented
	public function CHARA_EMOJI(charaId:Int, direction:Int, emoji:Int) {
		
	}
	
	@Opcode(0x86, "PP")
	public function CHARA_EVENT_SET(charaId:Int, eventId:Int) {
		var chara:Character = scriptThread.gameState.getCharacter(charaId);
		chara.actionEventSet(scriptThread.gameThreadState, eventId);
	}
	
	@Opcode(0x8F, "P")
	@Unimplemented
	public function CHARA_STOP(charaId:Int):Void {
		
	}
	

	@Opcode(0x78, "PP")
	@Unimplemented
	public function UNK_78(a, b) {
		
	}
	
	@Opcode(0x79, "P")
	@Unimplemented
	public function UNK_79(a) {
		
	}
	
	@Opcode(0x7A, "PPP")
	@Unimplemented
	public function UNK_7A(a, b, c) {
		
	}
	
	@Opcode(0x7B, "PPPP")
	@Unimplemented
	public function UNK_7B(a, b, c, d) {
		
	}
	
	@Opcode(0x7C, "PP")
	@Unimplemented
	public function UNK_7C(a, b) {
		
	}
	
	@Opcode(0x7D, "PP")
	public function UNK_7D(a, b) {
		
	}
	
	/**
	 * 
	 * @param	charaId
	 * @param	animationId
	 * @param	unknown
	 * 
	 * @example
	 *    CHARA_ATTACK_EFFECT(1, 904, 0)
	 *    Shell performs a fire attack with the animation at "DEXP"
	 */
	@Opcode(0x7E, "PPP")
	@Unimplemented
	public function CHARA_ATTACK_EFFECT(charaId:Int, animationId:Int, unknown:Int) {
		
	}
	
	@Opcode(0x7F, "PPPP")
	public function UNK_7F(a, b, c, d) {
		
	}
	
	@Opcode(0x81, "P")
	public function UNK_81(a) {
		
	}
	
	@Opcode(0x82, "P")
	public function UNK_82(a) {
		
	}
	
	@Opcode(0x83, "PP")
	public function UNK_83(a, b) {
		
	}
	
	@Opcode(0x84, "PP")
	public function UNK_84(a, b) {
		
	}
	
	@Opcode(0x85, "P")
	public function UNK_85(a) {
		
	}
	
	@Opcode(0x87, "PP")
	public function UNK_87(a, b) {
		
	}
	
	@Opcode(0x88, "PPP")
	public function UNK_88(a, b, c) {
		
	}
	
	@Opcode(0x89, "P")
	public function UNK_89(a) {
		
	}
	
	@Opcode(0x8A, "P")
	public function UNK_8A() {
		
	}
	
	@Opcode(0x8C, "P")
	public function UNK_8C(a) {
		
	}
	
	@Opcode(0x8D, "PP")
	public function UNK_8D(a, b) {
		
	}
	
	@Opcode(0x8E, "PP")
	public function UNK_8E(a, b) {
		
	}
}