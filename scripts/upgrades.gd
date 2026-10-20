extends RefCounted
## Lista ulepszeń do wyboru po awansie.
## Pole "max" = 0 oznacza brak limitu poziomów.
## Pole "apply" to funkcja, która dostaje gracza i zmienia jego statystyki.
## Aby dodać nowe ulepszenie, dopisz kolejny słownik do listy poniżej.

static func all() -> Array:
	return [
		{
			"id": "dmg", "name": "Ostrzejsze pociski", "max": 0,
			"desc": "+25% obrażeń od pocisków i ostrzy",
			"apply": func(p): p.damage *= 1.25,
		},
		{
			"id": "rate", "name": "Szybkostrzelność", "max": 0,
			"desc": "Strzelasz o 15% częściej",
			"apply": func(p): p.cooldown *= 0.85,
		},
		{
			"id": "count", "name": "Dodatkowy pocisk", "max": 6,
			"desc": "+1 pocisk w każdej salwie",
			"apply": func(p): p.proj_count += 1,
		},
		{
			"id": "pierce", "name": "Przebicie", "max": 5,
			"desc": "Pociski przebijają o 1 wroga więcej",
			"apply": func(p): p.pierce += 1,
		},
		{
			"id": "pspeed", "name": "Szybkie pociski", "max": 4,
			"desc": "+20% prędkości pocisków",
			"apply": func(p): p.proj_speed *= 1.2,
		},
		{
			"id": "speed", "name": "Lekkie buty", "max": 6,
			"desc": "+10% prędkości ruchu",
			"apply": func(p): p.move_speed *= 1.1,
		},
		{
			"id": "magnet", "name": "Magnes", "max": 5,
			"desc": "+40% zasięgu zbierania gemów",
			"apply": func(p): p.magnet *= 1.4,
		},
		{
			"id": "hp", "name": "Wytrzymałość", "max": 0,
			"desc": "+25 maks. HP i leczenie o 25",
			"apply": func(p): p.boost_hp(25.0),
		},
		{
			"id": "regen", "name": "Regeneracja", "max": 5,
			"desc": "+0,6 HP na sekundę",
			"apply": func(p): p.regen += 0.6,
		},
		{
			"id": "blades", "name": "Ostrza orbitalne", "max": 5,
			"desc": "+1 ostrze krążące wokół Ciebie",
			"apply": func(p): p.blades += 1,
		},
	]
