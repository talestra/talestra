module mmorpg.cards;

import imports;

//import sqlite3;

class Card {
	static Card[uint] cards;
	uint id;
	char[] name;
	ubyte[4] values;
	ubyte[4] elements;

	// Actualiza la base de datos con las cartas actuales
	/*
	static void updateDatabase(Sqlite3 db) {
		auto result = db.query("SELECT [id],[name],[v1],[v2],[v3],[v4],[e1],[e2],[e3],[e4] FROM [cards]");
		int results = 0;
		for (; result.more; result.next(), results++) {
			Card card = new Card();
			card.id = result.getInt32(0);
			card.name = result.getText(1);
			for (int n = 0; n < 4; n++) {
				card.values[n]   = result.getInt32(2 + n);
				card.elements[n] = result.getInt32(6 + n);
			}
			cards[card.id] = card;
		}
		writefln("DB.Cards(%d)", results);
		delete result;
	}
	*/

	// Serializa una carta
	char[] toString() {
		return std.string.format(
			"Card[%s](%d[%d], %d[%d], %d[%d], %d[%d])",
			name,
			values[0], elements[0],
			values[1], elements[1],
			values[2], elements[2],
			values[3], elements[3]
		);
	}
}
