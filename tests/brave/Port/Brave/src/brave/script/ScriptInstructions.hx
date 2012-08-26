package brave.script;
import brave.BraveAssets;
import brave.sprites.TextSprite;
import haxe.Log;
import haxe.Timer;
import nme.errors.Error;
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
	@Unimplemented(1)
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
		
		if (result) {
			scriptThread.jump(jumpOffset);
		}
	}

	@Opcode(0x03, "ss1L")
	public function OP_03(a, b, c, d) {
		
	}
	
	@Opcode(0x04, "L")
	public function OP_04(a) {
		
	}
	
	@Opcode(0x05, "4") // Return?
	public function RETURN(a) {
		
	}
	
	@Opcode(0x07, "") // FLOW. Return?
	public function OP_07() {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x08, "")
	@Unimplemented
	public function DEBUG_MESSAGE() {
		
	}

	/**
	 * 
	 */
	@Opcode(0x09, "")
	@Unimplemented
	public function OP_09() {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x0A, "P")
	@Unimplemented
	public function OP_0A(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x0B, "P")
	@Unimplemented
	public function OP_0B(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x0C, "P")
	@Unimplemented
	public function OP_0C(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x0D, "PP")
	@Unimplemented
	public function OP_0D(a, b) {
		
	}
	
	/**
	 * 
	 * @param	variable
	 * @param	operator
	 * @param	rightValue
	 */
	@Opcode(0x0F, "v7P")
	@Unimplemented
	public function ARITMETIC_OP(variable:Variable, operator:Int, rightValue:Int) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x10, "11s")
	@Unimplemented
	public function OP_10() {
		
	}
	
	/**
	 * 
	 * @param	variable
	 */
	@Opcode(0x11, "v")
	@Unimplemented
	public function VAR_INCREMENT(variable:Variable):Void {
		variable.setValue(variable.getValue() + 1);
	}
	
	/**
	 * 
	 * @param	variable
	 */
	@Opcode(0x12, "v")
	@Unimplemented
	public function VAR_DECREMENT(variable:Variable):Void {
		variable.setValue(variable.getValue() - 1);
	}
	
	/**
	 * 
	 * @param	variable
	 * @param	maxValue
	 */
	@Opcode(0x13, "vP")
	@Unimplemented
	public function RANDOM(variable:Variable, maxValue:Int) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x14, "PP")
	@Unimplemented
	public function OP_14(a, b) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x15, "12")
	@Unimplemented
	public function OP_15(a, b) {
		
	}
	
	/**
	 * 
	 * @param	index
	 */
	@Opcode(0x17, "P")
	@Unimplemented
	public function MUSIC_PLAY(index:Int) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x18, "P")
	@Unimplemented
	public function OP_18(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x19, "PP")
	@Unimplemented
	public function OP_19(a, b) {
		
	}
	
	/**
	 * 
	 * @param	a
	 */
	@Opcode(0x1A, "P")
	@Unimplemented
	public function OP_1A(a) {
		
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x1B, "PP")
	@Unimplemented
	public function OP_1B(a, b) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x1C, "")
	@Unimplemented
	public function MUSIC_STOP():Void {
		
	}
	
	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x1D, "COMMENT", "s")
	@Unimplemented
	public function COMMENT(text:String) {
		Log.trace(Std.format("COMMENT: '${text}'"));
	}
	
	/**
	 * 
	 * @param	a
	 * @param	b
	 */
	@Opcode(0x1E, "sP")
	@Unimplemented
	public function OP_1E(a, b) {
		
	}
	

	// 20-33
	@Opcode(0x21, "s") // Delay?
	public function SCRIPT(scriptName:String) {
		Log.trace(Std.format("SCRIPT('${scriptName}')"));
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
	
	@Opcode(0x2B, "4")
	@Unimplemented
	public function OP_2B(a:Int) {
		
	}
	
	@Opcode(0x2C, "4")
	@Unimplemented
	public function OP_2C(a:Int) {
		
	}
	
	@Opcode(0x2D, "P") // Lot of stuff
	@Unimplemented
	public function OP_2D(a) {
		
	}
	
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
	@Opcode(0x2F, "TEXT_PUT", "<sss")
	public function TEXT_PUT(done:Void -> Void, voice:String, title:String, text:String) {
		//Log.trace(Std.format("TEXT_PUT(${voice}, ${title}, ${text})"));
		
		var voiceChannel:SoundChannel = null;
		if (voice != "") {
			voiceChannel = BraveAssets.getVoice(voice).play();
		}
		var textSprite:TextSprite = scriptThread.gameState.rootClip.ui.textSprite;
		
		textSprite.setTextAndEnable(title, text, function() {
			var onClick = null;

			onClick = function(e) {
				textSprite.stage.removeEventListener("click", onClick);
				Timer.delay(function() {
					textSprite.endText();
					if (voiceChannel != null) voiceChannel.stop();
					done();
				}, 1);
			};
			
			textSprite.stage.addEventListener("click", onClick);
			//Timer.delay(function() { done(); }, 100);
			
		});
	}
	
	@Opcode(0x30, "<P")
	public function TRANSITION(done:Void -> Void, type:Int) {
		scriptThread.gameState.transition(done, type);
	}
	
	@Opcode(0x31, "P")
	public function FADE_TO_MAP(time:Int) {
		
	}
	

	// 34-42
	@Opcode(0x35, "s")
	public function TITLE_SET(title:String) {
		
	}
	
	@Opcode(0x36, "s")
	public function OP_36(text:String) {
		
	}
	
	@Opcode(0x37, "")
	public function OP_37() {
		
	}
	
	@Opcode(0x38, "Psss")
	public function OP_38(a, b, c, d) {
		
	}
	
	@Opcode(0x39, "Psss")
	public function TEXT_PUT_WITH_FACE(faceId:Int, voice:String, title:String, text:String) {
		
	}
	
	@Opcode(0x3A, "PPPsss")
	public function OP_3A(v0, v1, v2, v3, v4, v5) {
		
	}
	
	@Opcode(0x3B, "")
	public function OP_3B() {
		
	}
	
	@Opcode(0x3C, "")
	public function OP_3C() {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x3D, "")
	public function ANIMATION_WAIT() {
		
	}
	
	/**
	 * 
	 * @param	unk
	 * @param	title
	 */
	@Opcode(0x3E, "Ps")
	public function OPTION_START(unk:Int, title:String) {
		
	}
	
	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x3F, "s")
	public function OPTION_ITEM(text:String) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x40, "")
	public function OPTION_SHOW() {
		
	}
	
	@Opcode(0x41, "OP_41", "PP")
	public function OP_41() {
		
	}
	

	// 43--4F

	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x44, "TEXT_PUT_44", "s") // X40 = 0
	public function TEXT_PUT_44(text:String) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x45, "OP_45", "") // X40 = 1
	public function OP_45() {
		
	}
	
	/**
	 * 
	 * @param	text
	 */
	@Opcode(0x46, "OP_46", "s") // X40 = 2
	public function OP_46(text:String) {
		
	}
	
	/**
	 * 
	 */
	@Opcode(0x47, "OP_47", "")
	public function OP_47() {
		
	}
	
	/**
	 * 
	 * @param	title
	 */
	@Opcode(0x48, "TITLE_SHOW", "s")
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
	@Opcode(0x49, "OP_49", "PPPPPP")
	public function OP_49(v0, v1, v2, v3, v4, v5) {
		
	}
	
	@Opcode(0x4A, "PPPP") // Id, X, Y, Attribute (255 blocked, 0 no blocked)
	public function MAP_CELL_SET_ATTRIBUTE_FOR(charaId:Int, x:Int, y:Int, attribute:Int) {
		
	}
	
	@Opcode(0x4B, "OP_4B", "PPPPPP")
	public function OP_4B(a, b, c, d, e, f) {
		
	}
	
	@Opcode(0x4C, "OP_4C", "PPPP")
	public function OP_4C(a, b, c, d) {
		
	}
	
	@Opcode(0x4D, "OP_4D", "PPPP")
	public function OP_4D(a, b, c, d) {
		
	}
	
	@Opcode(0x4E, "TRIGGER_SET", "PPPP")
	public function TRIGGER_SET(charaId:Int, x:Int, y:Int, eventId:Int) {
		
	}
	

	// 50-91
	@Opcode(0x51, "PP")
	public function CHARA_UNK_51(charaID:Int, b) {
		
	}
	
	@Opcode(0x52, "P")
	public function UNK_52(a) {
		
	}
	
	@Opcode(0x53, "PPPPP") // Id, 0, X, Y, Direction
	public function PLAYER_SPAWN(charaId:Int, unk:Int, x:Int, y:Int, direction:Int) {
		
	}
	
	@Opcode(0x54, "vP")
	public function UNK_54(variable:Variable, value:Int) {
		
	}
	
	@Opcode(0x55, "vP")
	public function CHARA_SET(charaId:Variable, index:Int) {
		
	}
	
	@Opcode(0x56, "UNK_56", "v")
	public function UNK_56(variable:Variable) {
		
	}
	
	@Opcode(0x57, "CHARA_SPAWN", "PPPPP") // Id, 0, X, Y, Direction
	public function CHARA_SPAWN(charaId:Int, type:Int, x:Int, y:Int, direction:Int) {
		
	}
	
	@Opcode(0x58, "UNK_58", "")
	public function UNK_58() {
		
	}
	
	@Opcode(0x59, "GROUP_MOVE", "PPP") // X, Y, Direction
	public function GROUP_MOVE(x:Int, y:Int, direction:Int) {
		
	}
	
	@Opcode(0x5A, "UNK_5A", "vP")
	public function UNK_5A(variable:Variable, a:Int) {
		
	}
	
	@Opcode(0x5B, "UNK_5B", "P")
	public function UNK_5B(a) {
		
	}
	
	@Opcode(0x5C, "UNK_5C", "PP")
	public function UNK_5C(a, b) {
		
	}
	
	@Opcode(0x5D, "UNK_5D", "PP")
	public function UNK_5D(a, b) {
		
	}
	
	@Opcode(0x5E, "UNK_5E", "PP")
	public function UNK_5E(a, b) {
		
	}
	
	@Opcode(0x5F, "UNK_5F", "PP")
	public function UNK_5F(a, b) {
		
	}
	
	@Opcode(0x60, "UNK_60", "P")
	public function UNK_60(a) {
		
	}
	
	@Opcode(0x61, "UNK_61", "P") // Increment up to 999999999?
	public function UNK_61(a) {
		
	}
	
	@Opcode(0x62, "UNK_62", "P")
	public function UNK_62(a) {
		
	}
	
	@Opcode(0x63, "UNK_63", "P")
	public function UNK_63(a) {
		
	}
	
	@Opcode(0x64, "UNK_64", "P")
	public function UNK_64(a) {
		
	}
	
	@Opcode(0x65, "UNK_65", "") // memset(byte_518558, 0x1010101u, 40u);
	public function UNK_65() {
		
	}
	
	@Opcode(0x66, "UNK_66", "PPPPP")
	public function UNK_66(a, b, c, d, e) {
		
	}
	
	@Opcode(0x67, "ENEMY_SPAWN", "PPPPPP") // Id, ???, 0, X, Y, Direction
	public function ENEMY_SPAWN(charId:Int, unk:Int, unk2:Int, x:Int, y:Int, direction:Int) {
		
	}
	
	@Opcode(0x68, "UNK_68", "PPPPPPPP")
	public function UNK_68(v0, v1, v2, v3, v4, v5, v6, v7) {
		
	}
	
	@Opcode(0x69, "UNK_69", "PP")
	public function UNK_69(a, b) {
		
	}
	
	@Opcode(0x6A, "UNK_6A", "P")
	public function UNK_6A(a) {
		
	}
	
	@Opcode(0x6B, "UNK_6B", "PP")
	public function UNK_6B(a, b) {
		
	}
	
	@Opcode(0x6C, "UNK_6C", "") // = 2
	public function UNK_6C() {
		
	}
	
	@Opcode(0x6D, "UNK_6D", "") // = 4
	public function UNK_6D() {
		
	}
	
	@Opcode(0x6E, "UNK_6E", "") // = 0
	public function UNK_6E() {
		
	}
	
	@Opcode(0x6F, "UNK_6F", "P")
	public function UNK_6F(a) {
		
	}
	
	@Opcode(0x70, "UNK_70", "PP")
	public function UNK_70(a, b) {
		
	}
	
	@Opcode(0x71, "UNK_71", "PPPPPPPPP")
	public function UNK_71(a, b, c, d, e, f, g, h, i) {
		
	}
	
	@Opcode(0x72, "UNK_72", "PP")
	public function UNK_72(a, b) {
		
	}
	
	@Opcode(0x73, "UNK_73", "PP")
	public function UNK_73(a, b) {
		
	}
	
	@Opcode(0x74, "UNK_74", "PPP")
	public function UNK_74(a, b, c) {
		
	}
	
	@Opcode(0x75, "CHARA_START", "P")
	public function CHARA_START(charaId:Int) {
		
	}
	
	@Opcode(0x76, "CHARA_MOVE_TO", "PPP")
	public function CHARA_MOVE_TO(charaId:Int, x:Int, y:Int) {
		
	}
	
	@Opcode(0x77, "CHARA_FACE_TO", "PP")
	public function CHARA_FACE_TO(charaId:Int, direction:Int) {
		
	}
	
	@Opcode(0x78, "UNK_78", "PP")
	public function UNK_78(a, b) {
		
	}
	
	@Opcode(0x79, "UNK_79", "P")
	public function UNK_79(a) {
		
	}
	
	@Opcode(0x7A, "UNK_7A", "PPP")
	public function UNK_7A(a, b, c) {
		
	}
	
	@Opcode(0x7B, "UNK_7B", "PPPP")
	public function UNK_7B(a, b, c, d) {
		
	}
	
	@Opcode(0x7C, "UNK_7C", "PP")
	public function UNK_7C(a, b) {
		
	}
	
	@Opcode(0x7D, "UNK_7D", "PP")
	public function UNK_7D(a, b) {
		
	}
	
	@Opcode(0x7E, "UNK_7E", "PPP")
	public function UNK_7E(a, b, c) {
		
	}
	
	@Opcode(0x7F, "UNK_7F", "PPPP")
	public function UNK_7F(a, b, c, d) {
		
	}
	
	@Opcode(0x80, "UNK_80", "PP")
	public function UNK_80(a, b) {
		
	}
	
	@Opcode(0x81, "UNK_81", "P")
	public function UNK_81(a) {
		
	}
	
	@Opcode(0x82, "UNK_82", "P")
	public function UNK_82(a) {
		
	}
	
	@Opcode(0x83, "UNK_83", "PP")
	public function UNK_83(a, b) {
		
	}
	
	@Opcode(0x84, "UNK_84", "PP")
	public function UNK_84(a, b) {
		
	}
	
	@Opcode(0x85, "UNK_85", "P")
	public function UNK_85(a) {
		
	}
	
	@Opcode(0x86, "CHARA_EVENT_SET", "PP")
	public function CHARA_EVENT_SET(charId:Int, eventId:Int) {
		
	}
	
	@Opcode(0x87, "UNK_87", "PP")
	public function UNK_87(a, b) {
		
	}
	
	@Opcode(0x88, "UNK_88", "PPP")
	public function UNK_88(a, b, c) {
		
	}
	
	@Opcode(0x89, "UNK_89", "P")
	public function UNK_89(a) {
		
	}
	
	@Opcode(0x8A, "P")
	public function UNK_8A() {
		
	}
	
	/**
	 * 
	 * @param	charaId
	 * @param	direction
	 * @param	emoji       PG_MAIN
	 */
	@Opcode(0x8B, "PPP")
	public function CHARA_EMOJI(charaId:Int, direction:Int, emoji:Int) {
		
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
	
	@Opcode(0x8F, "P")
	public function CHARA_STOP(charaId:Int):Void {
		
	}
	
	@Opcode(0x90, "P")
	public function CHARA_DONE(charaId:Int):Void {
		
	}
	

	// 92
	@Opcode(0x92, "")
	public function END() {
		
	}
	
}