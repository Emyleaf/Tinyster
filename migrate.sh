#!/usr/bin/env bash
# ============================================================================
#  Tinyster - migrazione architettura cartelle
#  Eseguire dalla ROOT del progetto (dove sta project.godot), a Godot CHIUSO.
#  Prima di lanciarlo:  git checkout -b refactor/architettura
# ============================================================================
set -euo pipefail

[ -f project.godot ] || { echo "ERRORE: lanciami dalla root del progetto."; exit 1; }
command -v git >/dev/null || { echo "ERRORE: git non trovato."; exit 1; }

# --- helper: sposta un file portandosi dietro .uid / .import ----------------
mv_file() {
	local src="$1" dst="$2"
	[ -e "$src" ] || { echo "  skip (assente): $src"; return 0; }
	[ "$src" = "$dst" ] && return 0
	mkdir -p "$(dirname "$dst")"
	git mv -f "$src" "$dst"
	for side in uid import; do
		[ -e "${src}.${side}" ] && git mv -f "${src}.${side}" "${dst}.${side}"
	done
	return 0
}

# --- helper: sposta tutti i file di una cartella ----------------------------
mv_glob() {
	local pattern="$1" dstdir="$2"
	mkdir -p "$dstdir"
	shopt -s nullglob
	for f in $pattern; do
		[[ "$f" == *.uid || "$f" == *.import ]] && continue
		mv_file "$f" "$dstdir/$(basename "$f")"
	done
	shopt -u nullglob
}

echo "== 0. pulizia file spazzatura =================================="
find . -name "*.tmp" -not -path "./addons/*" -delete
find . -name "*~"    -not -path "./addons/*" -delete
grep -q '^\*\.tmp$' .gitignore || printf '\n# Editor Godot - file temporanei\n*.tmp\n*~\n' >> .gitignore
git rm -f --cached --ignore-unmatch $(git ls-files '*.tmp' '*~') >/dev/null 2>&1 || true

echo "== 1. autoload/ ================================================"
mv_file 00_Globals/events.gd               autoload/events.gd
mv_file 00_Globals/game_manager.gd         autoload/game_manager.gd
mv_file 00_Globals/dungeon_manager.gd      autoload/dungeon_manager.gd
mv_file 00_Globals/party_manager.gd        autoload/party_manager.gd
mv_file 00_Globals/global_player_manager.gd autoload/player_manager.gd
mv_file 00_Globals/global_level_manager.gd  autoload/level_manager.gd
mv_file 00_Globals/global_save_manager.gd   autoload/save_manager.gd

echo "== 2. core/ ===================================================="
mv_file generalnodes/hitbox/hit_box.gd     core/combat/hit_box.gd
mv_file generalnodes/hitbox/hit_box.tscn   core/combat/hit_box.tscn
mv_file generalnodes/hurtbox/hurt_box.gd   core/combat/hurt_box.gd
mv_file generalnodes/hurtbox/hurt_box.tscn core/combat/hurt_box.tscn
mv_file assets/healthbarProgress.png       core/combat/art/healthbar_progress.png
mv_file assets/healthbarUnder.png          core/combat/art/healthbar_under.png

mv_file player/scripts/states/state.gd     core/state_machine/state.gd

mv_file player/character_data.gd           core/resources/character_data.gd
mv_file player/skill_data.gd               core/resources/skill_data.gd
mv_file player/equipment_data.gd           core/resources/equipment_data.gd
mv_file enemies/scripts/enemy_stats.gd     core/resources/enemy_stats.gd

echo "== 3. actors/player/ ==========================================="
mv_file player/player.tscn                        actors/player/player.tscn
mv_file player/scripts/player.gd                  actors/player/player.gd
mv_file player/scripts/player_camera.gd           actors/player/player_camera.gd
mv_file player/scripts/player_interactions_host.gd actors/player/player_interactions_host.gd
mv_file player/party_member.gd                    actors/player/party_member.gd
mv_file player/player_health_bar.gd               actors/player/player_health_bar.gd

mv_file player/scripts/player_statemachine.gd     actors/player/states/player_state_machine.gd
mv_glob "player/scripts/states/state_*.gd"        actors/player/states

mv_file player/arrow.tscn                         actors/player/projectiles/arrow.tscn
mv_file player/scripts/arrow.gd                   actors/player/projectiles/arrow.gd
mv_file assets/Arrow.png                          actors/player/projectiles/art/arrow.png

mv_glob "player/Sprites/*.png"                    actors/player/art
mv_glob "player/icons/*.svg"                      actors/player/art
mv_glob "player/audio/*.wav"                      actors/player/audio

# orfano: duplicato senza script di ui/hud/party_hud/party_slot.tscn
git rm -f --ignore-unmatch player/party_slot.tscn >/dev/null

echo "== 4. actors/enemies/ =========================================="
mv_file enemies/scripts/enemy.gd               actors/enemies/enemy.gd
mv_file enemies/scripts/enemy_state_machine.gd actors/enemies/enemy_state_machine.gd
mv_file enemies/scripts/health_bar.gd          actors/enemies/enemy_health_bar.gd
mv_glob "enemies/scripts/states/*.gd"          actors/enemies/states
mv_file enemies/slime/slime.tscn               actors/enemies/slime/slime.tscn
mv_file enemies/slime/slime.gd                 actors/enemies/slime/slime.gd
mv_glob "enemies/slime/*.png"                  actors/enemies/slime/art
mv_glob "enemies/slime/*.wav"                  actors/enemies/slime/audio

echo "== 5. data/ (.tres centralizzati) =============================="
mv_file player/warrior.tres            data/characters/warrior.tres
mv_file player/archer.tres             data/characters/archer.tres
mv_glob "player/skills/*.tres"         data/skills
mv_file enemies/slime/slime_stats.tres data/enemies/slime_stats.tres

echo "== 6. dungeon/ ================================================="
mv_file generalnodes/dungeon.tscn        dungeon/run.tscn
mv_file generalnodes/dungeon.gd          dungeon/run.gd

mv_file dungeon/map_generator.gd         dungeon/generation/map_generator.gd
mv_file dungeon/walker_generator.gd      dungeon/generation/walker_generator.gd

mv_file dungeon/room.gd                  dungeon/map/room_data.gd
mv_file dungeon/scenes/map.tscn          dungeon/map/map.tscn
mv_file dungeon/scenes/map.gd            dungeon/map/map.gd
mv_file dungeon/scenes/map_room.tscn     dungeon/map/map_room.tscn
mv_file dungeon/scenes/map_room.gd       dungeon/map/map_room.gd
mv_file dungeon/scenes/map_line.tscn     dungeon/map/map_line.tscn
mv_glob "dungeon/art/*_room_icon.png"    dungeon/map/art
mv_file dungeon/art/line.png             dungeon/map/art/line.png
mv_file assets/map.png                   dungeon/map/art/map_background.png

mv_glob "dungeon/scenes/room_*.tscn"     dungeon/rooms
mv_glob "dungeon/scenes/room_*.gd"       dungeon/rooms
mv_file dungeon/scenes/door.tscn         dungeon/rooms/door.tscn
mv_file dungeon/scenes/door.gd           dungeon/rooms/door.gd
mv_file generalnodes/playerspawn/player_spawn.tscn dungeon/rooms/player_spawn.tscn
mv_file generalnodes/playerspawn/player_spawn.gd   dungeon/rooms/player_spawn.gd
mv_file assets/door.png                  dungeon/rooms/art/door.png
mv_file dungeon/scenes/door.png          dungeon/rooms/art/door_sprite.png
mv_file assets/stairs.png                dungeon/rooms/art/stairs.png
mv_file assets/vendor.png                dungeon/rooms/art/vendor.png
mv_file assets/forest.png                dungeon/rooms/art/forest.png

[ -d "Tile Maps" ] && git mv -f "Tile Maps" tile_maps_tmp
mv_file tile_maps_tmp/level_tile_map.gd  dungeon/rooms/tilesets/level_tile_map.gd
mv_glob "tile_maps_tmp/Sprites/*.png"    dungeon/rooms/tilesets/art
mv_glob "dungeon/art/tileset_free_miniwarriors/*" dungeon/rooms/tilesets/art

echo "== 7. ui/ ======================================================"
mv_glob "GUI/player_hud/*"  ui/hud/player_hud
mv_glob "GUI/party_hud/*"   ui/hud/party_hud
mv_glob "GUI/pause_menu/*"  ui/menus/pause_menu
mv_file main_menu.tscn      ui/menus/main_menu/main_menu.tscn
mv_file main_menu.gd        ui/menus/main_menu/main_menu.gd
mv_file generalnodes/transitionscreen.tscn   ui/transition/transition_screen.tscn
mv_file generalnodes/transition_screen.gd    ui/transition/transition_screen.gd
mv_file generalnodes/level_transition.tscn   ui/transition/level_transition.tscn
mv_file generalnodes/level_transition.gd     ui/transition/level_transition.gd

echo "== 8. props/ ==================================================="
mv_glob "props/sprites/*.png"    props/art

echo "== 9. avanzi ==================================================="
mv_file generalnodes/animation_library.tres actors/player/animation_library.tres
# asset senza alcun riferimento nel progetto: NON li cancello, li parcheggio
for f in assets/bush.png assets/Bushe1.png assets/background.png \
         assets/background_sample.png assets/char_sample.png \
         assets/sprite_sheet.png assets/lowleft.png assets/lowright.png; do
	mv_file "$f" "_unsorted/$(basename "$f")"
done

echo "== 10. fix dei preload() con path hardcoded ===================="
# I preload("res://...") sono STRINGHE: Godot non le aggiorna da solo.
fix() { grep -rl "$1" --include=*.gd . | grep -v './addons/' | xargs -r sed -i "s|$1|$2|g"; }
fix 'res://dungeon/scenes/map.tscn'          'res://dungeon/map/map.tscn'
fix 'res://dungeon/scenes/map_room.tscn'     'res://dungeon/map/map_room.tscn'
fix 'res://dungeon/scenes/map_line.tscn'     'res://dungeon/map/map_line.tscn'
fix 'res://dungeon/scenes/room_monster.tscn' 'res://dungeon/rooms/room_monster.tscn'
fix 'res://dungeon/scenes/room_shop.tscn'    'res://dungeon/rooms/room_shop.tscn'
fix 'res://dungeon/scenes/room_campfire.tscn' 'res://dungeon/rooms/room_campfire.tscn'
fix 'res://dungeon/scenes/door.tscn'         'res://dungeon/rooms/door.tscn'
fix 'res://dungeon/art/'                     'res://dungeon/map/art/'
fix 'res://player/player.tscn'               'res://actors/player/player.tscn'
fix 'res://player/warrior.tres'              'res://data/characters/warrior.tres'
fix 'res://player/archer.tres'               'res://data/characters/archer.tres'
fix 'res://enemies/slime/slime.tscn'         'res://actors/enemies/slime/slime.tscn'

echo "== 11. cartelle vuote ==========================================="
find . -type d -empty -not -path "./.git/*" -not -path "./addons/*" -delete 2>/dev/null || true

echo
echo "FATTO. Ora:"
echo "  1) apri Godot (reimporterà le texture: è normale, lascialo finire)"
echo "  2) Progetto > Impostazioni > Autoload: verifica i 10 path"
echo "  3) F5 e controlla il pannello Output"
echo "  4) se tutto ok:  git add -A && git commit -m 'refactor: nuova architettura cartelle'"
