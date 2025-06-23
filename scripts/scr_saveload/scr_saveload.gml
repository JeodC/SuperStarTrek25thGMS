/// @description: Saves the game state to a binary file using a buffer.
/// @param {string} filename: The name of the save file.
function save_game(filename) {
    filename = filename ?? "save.dat";
	
	// Save a copy of our player state
	var snapshot = get_player_state();

    var buf = buffer_create(1024, buffer_grow, 1);

    try {
        // Write version
        buffer_write(buf, buffer_u32, 1); // Version 1

        // Write game struct
        buffer_write(buf, buffer_f32, global.game.difficulty);
        buffer_write(buf, buffer_f32, global.game.maxenergy);
        buffer_write(buf, buffer_f32, global.game.maxtorpedoes);
        buffer_write(buf, buffer_f32, global.game.enemypower);
        buffer_write(buf, buffer_s32, global.game.maxstars);
        buffer_write(buf, buffer_s32, global.game.totalbases);
        buffer_write(buf, buffer_s32, global.game.totalenemies);
        buffer_write(buf, buffer_s32, global.game.initenemies);
        buffer_write(buf, buffer_s32, global.game.maxdays);
        buffer_write(buf, buffer_s32, global.game.date);
        buffer_write(buf, buffer_s32, global.game.t0);
        buffer_write(buf, buffer_f32, global.game.score);
        buffer_write(buf, buffer_string, string(global.game.state)); // Enum as string

        // Write ent (Ship struct)
        write_ship(buf, global.ent);

        // Write galaxy (8x8 array of Sector structs)
        for (var sx = 0; sx < 8; sx++) {
            for (var sy = 0; sy < 8; sy++) {
                var sector = global.galaxy[sx][sy];
                buffer_write(buf, buffer_s32, sector.enemynum);
                buffer_write(buf, buffer_s32, sector.basenum);
                buffer_write(buf, buffer_s32, sector.starnum);
                // Write star_positions array
                buffer_write(buf, buffer_u32, array_length(sector.star_positions));
                for (var i = 0; i < array_length(sector.star_positions); i++) {
                    buffer_write(buf, buffer_f32, sector.star_positions[i][0]);
                    buffer_write(buf, buffer_f32, sector.star_positions[i][1]);
                }
                // Write available_cells array
                buffer_write(buf, buffer_u32, array_length(sector.available_cells));
                for (var i = 0; i < array_length(sector.available_cells); i++) {
                    buffer_write(buf, buffer_s32, sector.available_cells[i][0]);
                    buffer_write(buf, buffer_s32, sector.available_cells[i][1]);
                }
                buffer_write(buf, buffer_bool, sector.seen);
            }
        }
		
		// Sanitize allenemies array
		var cleaned_enemies = [];
		for (var i = 0; i < array_length(global.allenemies); i++) {
		    var e = global.allenemies[i];
		    if (is_struct(e) && variable_instance_exists(e, "sx") && variable_instance_exists(e, "sy")) {
		        array_push(cleaned_enemies, e);
		    }
		}
		global.allenemies = cleaned_enemies;

        // Write allenemies (array of EnemyShip structs)
        buffer_write(buf, buffer_u32, array_length(global.allenemies));
        for (var i = 0; i < array_length(global.allenemies); i++) {
            var enemy = global.allenemies[i];
            buffer_write(buf, buffer_s32, enemy.sx);
            buffer_write(buf, buffer_s32, enemy.sy);
            buffer_write(buf, buffer_s32, enemy.lx);
            buffer_write(buf, buffer_s32, enemy.ly);
            buffer_write(buf, buffer_f32, enemy.energy);
            buffer_write(buf, buffer_f32, enemy.maxenergy);
            buffer_write(buf, buffer_f32, enemy.dir);
        }

        // Write allbases (array of Starbase structs)
        buffer_write(buf, buffer_u32, array_length(global.allbases));
        for (var i = 0; i < array_length(global.allbases); i++) {
            var base = global.allbases[i];
            buffer_write(buf, buffer_s32, base.sx);
            buffer_write(buf, buffer_s32, base.sy);
            buffer_write(buf, buffer_s32, base.lx);
            buffer_write(buf, buffer_s32, base.ly);
            //buffer_write(buf, buffer_f32, base.energy);
            //buffer_write(buf, buffer_s32, base.num);
        }

        // Write runtime (player_state struct)
        buffer_write(buf, buffer_bool, snapshot != undefined);
        if (snapshot != undefined) {
            write_player_state(buf, snapshot);
        }

        // Save buffer to file
        buffer_save(buf, filename);
        show_debug_message("Game saved to " + filename);
    } catch (e) {
        show_debug_message("Error saving game: " + string(e));
    }

    buffer_delete(buf);
}

/// @description: Writes a Ship struct to the buffer
/// @param {any} buf: The buffer to write to
/// @param {struct} ship: The Ship struct
function write_ship(buf, ship) {
    buffer_write(buf, buffer_f32, ship.energy);
    buffer_write(buf, buffer_f32, ship.torpedoes);
    buffer_write(buf, buffer_f32, ship.shields);
    buffer_write(buf, buffer_f32, ship.phasers);
    buffer_write(buf, buffer_string, string(ship.condition)); // Enum as string
    buffer_write(buf, buffer_bool, ship.isdocked);
    buffer_write(buf, buffer_f32, ship.generaldamage);
    // Write system struct
    buffer_write(buf, buffer_f32, ship.system.warp);
    buffer_write(buf, buffer_f32, ship.system.srs);
    buffer_write(buf, buffer_f32, ship.system.lrs);
    buffer_write(buf, buffer_f32, ship.system.phasers);
    buffer_write(buf, buffer_f32, ship.system.torpedoes);
    buffer_write(buf, buffer_f32, ship.system.navigation);
    buffer_write(buf, buffer_f32, ship.system.shields);
    buffer_write(buf, buffer_s32, ship.sx);
    buffer_write(buf, buffer_s32, ship.sy);
    buffer_write(buf, buffer_s32, ship.prev_sx);
    buffer_write(buf, buffer_s32, ship.prev_sy);
    buffer_write(buf, buffer_s32, ship.lx);
    buffer_write(buf, buffer_s32, ship.ly);
    buffer_write(buf, buffer_f32, ship.dir);
    buffer_write(buf, buffer_bool, ship.animating_impulse);
    buffer_write(buf, buffer_f32, round(ship.current_x * 1000) / 1000);
    buffer_write(buf, buffer_f32, round(ship.current_y * 1000) / 1000);
    buffer_write(buf, buffer_s32, ship.path_idx);
}

/// @description: Writes the get_player_state struct to the buffer
/// @param {any} buf: The buffer to write to
/// @param {struct} state: The player state struct
function write_player_state(buf, state) {
    buffer_write(buf, buffer_string, string(state.display)); // Enum as string
    buffer_write(buf, buffer_bool, state.end_turn);
    // Assume anim_lrs_state and anim_siren_state are empty or simple structs
    buffer_write(buf, buffer_bool, variable_struct_exists(state, "anim_lrs_state"));
    if (variable_struct_exists(state, "anim_lrs_state")) {
        buffer_write(buf, buffer_string, json_stringify(state.anim_lrs_state));
    }
    buffer_write(buf, buffer_bool, variable_struct_exists(state, "anim_siren_state"));
    if (variable_struct_exists(state, "anim_siren_state")) {
        buffer_write(buf, buffer_string, json_stringify(state.anim_siren_state));
    }
    buffer_write(buf, buffer_bool, state.contactedbase);
    buffer_write(buf, buffer_s32, state.askedforlrs);
    buffer_write(buf, buffer_bool, state.firstenemyspotted);
    buffer_write(buf, buffer_bool, state.impulsehelp);
    buffer_write(buf, buffer_bool, state.speech_damage);
    buffer_write(buf, buffer_bool, state.speech_phaserfire);
    buffer_write(buf, buffer_bool, state.speech_phaserhit);
    buffer_write(buf, buffer_bool, state.speech_phaserwarn);
    buffer_write(buf, buffer_bool, state.speech_suggestedlrs);
    buffer_write(buf, buffer_bool, state.speech_torparm);
    buffer_write(buf, buffer_f32, state.torp_angle);
    buffer_write(buf, buffer_s32, state.torp_cx);
    buffer_write(buf, buffer_s32, state.torp_cy);
}

/// @description Loads the game state from a binary save file.
/// @param {string} filename: The name of the save file.
function load_game(filename) {
    filename = filename ?? "save.dat";

    if (!file_exists(filename)) {
        show_debug_message("Save file not found: " + filename);
        return false;
    }

    var buf = buffer_load(filename);
    try {
        // Read version
        var version = buffer_read(buf, buffer_u32);
        if (version != 1) {
            show_debug_message("Unsupported save version: " + string(version));
            buffer_delete(buf);
            return false;
        }

        // Read game struct
        global.game = Game();
        global.game.difficulty = buffer_read(buf, buffer_f32);
        global.game.maxenergy = buffer_read(buf, buffer_f32);
        global.game.maxtorpedoes = buffer_read(buf, buffer_f32);
        global.game.enemypower = buffer_read(buf, buffer_f32);
        global.game.maxstars = buffer_read(buf, buffer_s32);
        global.game.totalbases = buffer_read(buf, buffer_s32);
        global.game.totalenemies = buffer_read(buf, buffer_s32);
        global.game.initenemies = buffer_read(buf, buffer_s32);
        global.game.maxdays = buffer_read(buf, buffer_s32);
        global.game.date = buffer_read(buf, buffer_s32);
        global.game.t0 = buffer_read(buf, buffer_s32);
        global.game.score = buffer_read(buf, buffer_f32);
        global.game.state = real(buffer_read(buf, buffer_string)); // Restore enum

        // Read ent (Ship struct)
        global.ent = read_ship(buf);

        // Read galaxy (8x8 array of Sector structs)
        global.galaxy = array_create(8);
        for (var sx = 0; sx < 8; sx++) {
            global.galaxy[sx] = array_create(8);
            for (var sy = 0; sy < 8; sy++) {
                var sector = Sector();
                sector.enemynum = buffer_read(buf, buffer_s32);
                sector.basenum = buffer_read(buf, buffer_s32);
                sector.starnum = buffer_read(buf, buffer_s32);
                // Read star_positions array
                var star_len = buffer_read(buf, buffer_u32);
                sector.star_positions = array_create(star_len);
                for (var i = 0; i < star_len; i++) {
                    sector.star_positions[i] = [buffer_read(buf, buffer_f32), buffer_read(buf, buffer_f32)];
                }
                // Read available_cells array
                var cells_len = buffer_read(buf, buffer_u32);
                sector.available_cells = array_create(cells_len);
                for (var i = 0; i < cells_len; i++) {
                    sector.available_cells[i] = [buffer_read(buf, buffer_s32), buffer_read(buf, buffer_s32)];
                }
                sector.seen = buffer_read(buf, buffer_bool);
                global.galaxy[sx][sy] = sector;
            }
        }

        // Read allenemies (array of EnemyShip structs)
        var enemies_len = buffer_read(buf, buffer_u32);
        global.allenemies = array_create(enemies_len);
        for (var i = 0; i < enemies_len; i++) {
            var enemy = EnemyShip();
            enemy.sx = buffer_read(buf, buffer_s32);
            enemy.sy = buffer_read(buf, buffer_s32);
            enemy.lx = buffer_read(buf, buffer_s32);
            enemy.ly = buffer_read(buf, buffer_s32);
            enemy.energy = buffer_read(buf, buffer_f32);
            enemy.maxenergy = buffer_read(buf, buffer_f32);
            enemy.dir = buffer_read(buf, buffer_f32);
            global.allenemies[i] = enemy;
        }

        // Read allbases (array of Starbase structs)
        var bases_len = buffer_read(buf, buffer_u32);
        global.allbases = array_create(bases_len);
        for (var i = 0; i < bases_len; i++) {
            var base = Starbase();
            base.sx = buffer_read(buf, buffer_s32);
            base.sy = buffer_read(buf, buffer_s32);
            base.lx = buffer_read(buf, buffer_s32);
            base.ly = buffer_read(buf, buffer_s32);
            //base.energy = buffer_read(buf, buffer_f32);
            //base.num = buffer_read(buf, buffer_s32);
            global.allbases[i] = base;
        }

        // Read runtime (player_state struct)
		var has_runtime = buffer_read(buf, buffer_bool);
		var loaded_player_state = has_runtime ? read_player_state(buf) : undefined;

        show_debug_message("Game loaded from " + filename);
        buffer_delete(buf);
        return { ok: true, state: loaded_player_state };
    } catch (e) {
        show_debug_message("Error loading save file: " + string(e));
        buffer_delete(buf);
        return false;
    }
}

/// @description: Reads a Ship struct from the buffer
/// @param {any} buf: The buffer to read from
function read_ship(buf) {
    var ship = Ship();
    ship.energy = buffer_read(buf, buffer_f32);
    ship.torpedoes = buffer_read(buf, buffer_f32);
    ship.shields = buffer_read(buf, buffer_f32);
    ship.phasers = buffer_read(buf, buffer_f32);
    ship.condition = real(buffer_read(buf, buffer_string)); // Restore enum
    ship.isdocked = buffer_read(buf, buffer_bool);
    ship.generaldamage = buffer_read(buf, buffer_f32);
    ship.system = {
        warp: buffer_read(buf, buffer_f32),
        srs: buffer_read(buf, buffer_f32),
        lrs: buffer_read(buf, buffer_f32),
        phasers: buffer_read(buf, buffer_f32),
        torpedoes: buffer_read(buf, buffer_f32),
        navigation: buffer_read(buf, buffer_f32),
        shields: buffer_read(buf, buffer_f32)
    };
    ship.sx = buffer_read(buf, buffer_s32);
    ship.sy = buffer_read(buf, buffer_s32);
    ship.prev_sx = buffer_read(buf, buffer_s32);
    ship.prev_sy = buffer_read(buf, buffer_s32);
    ship.lx = buffer_read(buf, buffer_s32);
    ship.ly = buffer_read(buf, buffer_s32);
    ship.dir = buffer_read(buf, buffer_f32);
    ship.animating_impulse = buffer_read(buf, buffer_bool);
    ship.current_x = buffer_read(buf, buffer_f32);
    ship.current_y = buffer_read(buf, buffer_f32);
    ship.path_idx = buffer_read(buf, buffer_s32);
    return ship;
}

/// @description: Reads the get_player_state struct from the buffer
/// @param {any} buf: The buffer to read from
function read_player_state(buf) {
    var state = {};
    state.display = real(buffer_read(buf, buffer_string)); // Restore enum
    state.end_turn = buffer_read(buf, buffer_bool);
    // Read anim_lrs_state
    var has_lrs_state = buffer_read(buf, buffer_bool);
    state.anim_lrs_state = has_lrs_state ? json_parse(buffer_read(buf, buffer_string)) : {};
    // Read anim_siren_state
    var has_siren_state = buffer_read(buf, buffer_bool);
    state.anim_siren_state = has_siren_state ? json_parse(buffer_read(buf, buffer_string)) : {};
    state.contactedbase = buffer_read(buf, buffer_bool);
    state.askedforlrs = buffer_read(buf, buffer_s32);
    state.firstenemyspotted = buffer_read(buf, buffer_bool);
    state.impulsehelp = buffer_read(buf, buffer_bool);
    state.speech_damage = buffer_read(buf, buffer_bool);
    state.speech_phaserfire = buffer_read(buf, buffer_bool);
    state.speech_phaserhit = buffer_read(buf, buffer_bool);
    state.speech_phaserwarn = buffer_read(buf, buffer_bool);
    state.speech_suggestedlrs = buffer_read(buf, buffer_bool);
    state.speech_torparm = buffer_read(buf, buffer_bool);
    state.torp_angle = buffer_read(buf, buffer_f32);
    state.torp_cx = buffer_read(buf, buffer_s32);
    state.torp_cy = buffer_read(buf, buffer_s32);
    return state;
}

/// @description: Restores local player state from saved struct.
/// @param {struct} state: Variable storing the loaded state (global.runtime)
function apply_player_state(state) {
	display = state.display;
	end_turn = state.end_turn;
	anim_lrs_state = state.anim_lrs_state;
	anim_siren_state = state.anim_siren_state;

	contactedbase = state.contactedbase;
	askedforlrs = state.askedforlrs;
	firstenemyspotted = state.firstenemyspotted;
	impulsehelp = state.impulsehelp;

	speech_damage = state.speech_damage;
	speech_phaserfire = state.speech_phaserfire;
	speech_phaserhit = state.speech_phaserhit;
	speech_phaserwarn = state.speech_phaserwarn;
	speech_suggestedlrs = state.speech_suggestedlrs;
	speech_torparm = state.speech_torparm;

	torp_angle = state.torp_angle;
	torp_cx = state.torp_cx;
	torp_cy = state.torp_cy;
}