/*
function moveDelay(chara) {
	setTimeout(function(){ moveRandom(chara); }, 600);
}

function moveRandom(chara) {
	chara.walkTo(Math.random() * 400, Math.random() * 200 + 100, moveDelay);
}
*/

function onLoadRoom() {
	Map.load('dojo_regulus');
	
	Character.create('farah', 500, 400, function(chara) {
		Character.setUser(chara);
	});

	/*
	Character.create('reid', 460, 400, function(chara) {
		//Character.setUser(chara);
	});

	Character.create('keele', 420, 400, function(chara) {
		//Character.setUser(chara);
	});

	Character.create('max', 380, 400, function(chara) {
		//Character.setUser(chara);
	});

	Character.create('ras', 540, 400, function(chara) {
		//Character.setUser(chara);
	});

	Character.create('chat', 580, 400, function(chara) {
		//Character.setUser(chara);
	});

	setTimeout(function() {
		Character.create('meredy', 620, 400, function(chara) {
			//moveRandom(chara);
		});
	}, 6000);	
	*/
}