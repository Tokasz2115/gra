# Horda

Gra 2D w stylu Vampire Survivors, zrobiona w **Godot 4** (GDScript).
Przetrwaj kolejne fale wrogów, zbieraj niebieskie gemy z EXP i wybieraj
jedno z trzech losowych ulepszeń po każdym awansie.

## Uruchomienie

1. Zainstaluj Godot 4.2 lub nowszy (wersja standardowa, bez .NET).
2. W oknie startowym kliknij **Import** i wskaż plik `project.godot` z tego repozytorium.
3. Naciśnij **F5** (Play).

## Sterowanie

- **WASD** lub strzałki: ruch (postać strzela sama w najbliższego wroga)
- **1 / 2 / 3** lub klik: wybór ulepszenia po awansie
- **Esc**: pauza

## Aktualizowanie projektu

Zmiany od Claude trafiają na GitHuba. Żeby mieć je w Godocie:

1. W folderze projektu uruchom `git pull` (albo kliknij **Pull** w GitHub Desktop).
2. Przełącz się na okno Godota. Skrypty i sceny odświeżą się same.

Aby Godot przeładowywał skrypty bez pytania, włącz w *Editor → Editor Settings →
Text Editor → Behavior* opcję **Auto Reload Scripts on External Change**.

## Struktura

| Plik | Co robi |
| --- | --- |
| `scenes/main.tscn` | Jedyna scena, ma tylko skrypt `main.gd` |
| `scripts/main.gd` | Fale, spawn wrogów, interfejs, ekran awansu, koniec gry |
| `scripts/player.gd` | Ruch, auto-atak, statystyki, EXP |
| `scripts/enemy.gd` | Typy zombie (`man`, `woman`, `child`, `fat`) i ich zachowanie |
| `scripts/projectile.gd` | Pocisk z przebiciem |
| `scripts/gem.gd` | Gem z EXP przyciągany magnesem |
| `scripts/upgrades.gd` | Lista ulepszeń do wyboru |
| `assets/sprites/` | Grafika postaci (żołnierz i zombie), po 2 klatki marszu |
| `assets/tiles/` | Kafelki trawy (`tiles.png`) i dekoracje: kwiatki, grzyb, kamień, krzak, drzewo (`decor.png`) |
| `tools/make_sprites.py` | Skrypt, który rysuje całą grafikę (pixel art) |

## Jak rozbudowywać

- **Nowe ulepszenie:** dopisz słownik w `scripts/upgrades.gd`.
- **Nowy wróg:** dopisz wpis w `TYPES` w `scripts/enemy.gd` i dodaj go do `_spawn_enemy` w `scripts/main.gd`.
- **Trudność:** zmień `WAVE_LENGTH` i wzór na liczbę wrogów w `_process` w `scripts/main.gd`.

## Grafika

Cała grafika jest generowana skryptem `tools/make_sprites.py` (potrzebuje `pip install pillow`).
Żeby zmienić kolory albo wygląd postaci, edytuj słowniki `SOLDIER` i `ZOMBIE_*` w tym pliku,
uruchom `python tools/make_sprites.py` i wróć do Godota. Mapa jest nieskończona i rysowana
w `scripts/main.gd` (funkcja `_draw`). Drzewa i krzaki są tylko ozdobą, nie blokują ruchu.
Przybliżenie kamery zmienisz stałą `CAMERA_ZOOM` w `scripts/player.gd`.
