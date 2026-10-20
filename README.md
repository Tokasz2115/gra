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
| `scripts/enemy.gd` | Typy wrogów (`basic`, `fast`, `tank`) i ich zachowanie |
| `scripts/projectile.gd` | Pocisk z przebiciem |
| `scripts/gem.gd` | Gem z EXP przyciągany magnesem |
| `scripts/upgrades.gd` | Lista ulepszeń do wyboru |

## Jak rozbudowywać

- **Nowe ulepszenie:** dopisz słownik w `scripts/upgrades.gd`.
- **Nowy wróg:** dopisz wpis w `TYPES` w `scripts/enemy.gd` i dodaj go do `_spawn_enemy` w `scripts/main.gd`.
- **Trudność:** zmień `WAVE_LENGTH` i wzór na liczbę wrogów w `_process` w `scripts/main.gd`.
