/// @description: Resets the Enterprise to its initial state
function init_enterprise() {
	audio_play_sound(snd_starbase_refill, 0, false);
	if (global.ent.generaldamage > 1) {
		queue_dialog("Kirk", "docked.fixed1");
		queue_dialog("Scott", "docked.fixed2");
		queue_dialog("Kirk", "docked.fixed3");
		queue_dialog("Scott", "docked.fixed4");
	}
	// Reset ship properties
	global.ent.energy = global.game.maxenergy;
	//global.ent.torpedoes = global.game.maxtorpedoes; -- Makes game too easy
	global.ent.shields = 0;
	global.ent.isdocked = false;
	
	// Reinitialize systems
	global.ent.generaldamage = 0;
	global.ent.system = {
		warp: 100,
		srs: 100,
		lrs: 100,
		phasers: 100,
		torpedoes: 100,
		navigation: 100,
		shields: 100
	};
}

/// @description: Randomly damages ship systems
/// @param {real} max_dam: Maximum damage to deal
function damage_random_systems(max_dam) {
	var damage_keys = variable_struct_get_names(global.ent.system);

	// Filter only systems that are above 0
	var valid_keys = [];
	for (var i = 0; i < array_length(damage_keys); i++) {
		var key = damage_keys[i];
		if (global.ent.system[$ key] > 0) {
			array_push(valid_keys, key);
		}
	}
	
	// Shuffle keys to avoid always hitting the same ones first
	valid_keys = array_shuffle(valid_keys);

	var thresh = 0.8 - (global.game.difficulty / 10.0);
	show_debug_message("[DAMAGE PHASE] Threshold: " + string_format(thresh, 0, 2) + " | Difficulty: " + string(global.game.difficulty));

	for (var i = 0; i < array_length(valid_keys); i++) {
		var key = valid_keys[i];

		if (random(1.0) > thresh) {
			var modifier = random_range(0.8, 1.2);
			var damage = round(max_dam * modifier);

			var before = global.ent.system[$ key];
			global.ent.system[$ key] -= damage;
			var after = global.ent.system[$ key];

			var overkill = 0;
			if (after < 0) {
				overkill = -after;
				global.ent.system[$ key] = 0;
				after = 0;
			}

			show_debug_message("- System '" + key + "' took " + string(damage - overkill) + " damage (modifier: " + string(modifier) + ")");
		}
	}

	// Update general damage status
	global.ent.generaldamage = 0;
	for (var i = 0; i < array_length(damage_keys); i++) {
		var val = global.ent.system[$ damage_keys[i]];
		if (val < 90 && global.ent.generaldamage < 1) global.ent.generaldamage = 1;
		if (val < 66 && global.ent.generaldamage < 2) global.ent.generaldamage = 2;
		if (val < 33 && global.ent.generaldamage < 3) global.ent.generaldamage = 3;
	}
	show_debug_message("General damage level: " + string(global.ent.generaldamage));
}

/// @description: Randomly repairs a damaged ship system
function repair_random_systems() {
    var keys = variable_struct_get_names(global.ent.system);

    // Collect damaged systems
    var damaged_systems = [];
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        if (global.ent.system[$ key] < 100) {
            array_push(damaged_systems, key);
        }
    }

    show_debug_message("[REPAIR PHASE]");

    // Attempt repair on a random damaged system
    if (array_length(damaged_systems) > 0 && random(1.0) < 0.90) {
        var key = damaged_systems[irandom(array_length(damaged_systems) - 1)];
        var repair = irandom_range(10, 25);

        var before = global.ent.system[$ key];
        global.ent.system[$ key] += repair;
        if (global.ent.system[$ key] > 100) {
            global.ent.system[$ key] = 100;
        }
        var after = global.ent.system[$ key];

        show_debug_message("- Repaired system '" + key + "' by " + string(after - before) +
            " points | Before: " + string(before) + " - After: " + string(after) +
            (after == 100 ? " (Fully Repaired)" : ""));

        // Queue dialog based on final state
        if (after > before) {
			dialog_repairs(after == 100 ? 1 : 2, key);
		}
    } else {
        show_debug_message("- No systems repaired.");
    }

    // Update general damage status
    global.ent.generaldamage = 0;
    for (var i = 0; i < array_length(keys); i++) {
        var val = global.ent.system[$ keys[i]];
        if (val < 90 && global.ent.generaldamage < 1) global.ent.generaldamage = 1;
        if (val < 66 && global.ent.generaldamage < 2) global.ent.generaldamage = 2;
        if (val < 33 && global.ent.generaldamage < 3) global.ent.generaldamage = 3;
    }

    show_debug_message("- General damage level: " + string(global.ent.generaldamage));
}

/// @description: Advances game date by a given number of whole days
/// @param {real} days: Days to advance (must be an integer)
function advancetime(days) {
	// Ensure days is an integer
	if (!is_real(days) || days != floor(days)) {
		show_debug_message("advancetime() called with non-integer value: " + string(days));
		days = floor(days);
	}

	global.game.date += days;
	var daysleft = global.game.t0 + (global.game.maxdays - global.game.date);

	// If time has expired, handle loss
	if (daysleft < 1) {
		array_push(global.queue, function() {
			dialog_condition();
			return undefined;
		});
	}
}

/// @description: Update Enterprise status
function update_ship_condition() {
	var sector = global.galaxy[global.ent.sx][global.ent.sy];
	var daysleft = global.game.t0 + (global.game.maxdays - global.game.date);
	var lowPower = (global.ent.energy + global.ent.shields + global.ent.phasers) < global.game.maxenergy / 10;

	// Track old condition to see if it changed
	var old_condition = global.ent.condition;
	var new_condition;

	if (global.ent.shields < 0) {
		new_condition = Condition.Destroyed;
		show_debug_message("Player was destroyed!");
	}
	else if (global.ent.shields < 2 && global.ent.energy < 2) {
		new_condition = Condition.Stranded;
		show_debug_message("Player was stranded (Out of energy)!");
	}
	else if (global.ent.system.warp < 10 && sector.basenum < 1) {
		new_condition = Condition.Stranded;
		show_debug_message("Player was stranded (damaged warp core)!");
	}
	else if (global.ent.system.warp < 10 && global.ent.system.navigation < 10) {
		new_condition = Condition.Stranded;
		show_debug_message("Player was stranded (damaged navigation)!");
	}
	else if (daysleft < 1) {
		new_condition = Condition.NoTime;
		show_debug_message("Player ran out of time!");
	}
	else if (lowPower || global.ent.generaldamage > 1) {
		new_condition = (global.ent.generaldamage > 2) 
			? Condition.Red 
			: Condition.Yellow;
	}
	else {
		new_condition = Condition.Green;
	}

	global.ent.condition = new_condition;

	// If condition changed and it's critical, queue dialog
	var should_dialog = (new_condition == Condition.Stranded || new_condition == Condition.Destroyed || new_condition == Condition.NoTime);
	if (should_dialog && old_condition != new_condition && !global.busy) {
		global.busy = true;
		array_resize(global.queue, global.index);
		array_push(global.queue, function() {
			dialog_condition();
			return undefined;
		});
	}
}


/// @description: Returns stars, bases, and enemies in the specified sector, updating player arrays if player's sector
/// @param {real} sx: Sector x coordinate in galaxy (player's sector if undefined)
/// @param {real} sy: Sector y coordinate in galaxy (player's sector if undefined)
function get_sector_data(sx = global.ent.sx, sy = global.ent.sy) {
    var s = { 
        enemynum: 0,
        basenum: 0,
        starnum: 0,
        enemies: [],
        bases: [],
        stars: []
    };

    // Get sector data
    var sector = global.galaxy[sx][sy];
    s.enemynum = sector.enemynum;
    s.basenum = sector.basenum;
    s.starnum = sector.starnum;

    // Populate stars from sector.star_positions
    for (var i = 0; i < array_length(sector.star_positions); i++) {
        var pos = sector.star_positions[i];
        if (array_length(pos) >= 2) {
            array_push(s.stars, { 
                lx: pos[0], 
                ly: pos[1], 
                index: i 
            });
        }
    }

    // Populate bases from global.allbases
	for (var i = 0; i < array_length(global.allbases); i++) {
		var base = global.allbases[i];
		if (is_undefined(base) || !is_struct(base)) continue;
		if (base.sx == sx && base.sy == sy) {
			array_push(s.bases, { 
				lx: base.lx, 
				ly: base.ly, 
				energy: variable_struct_exists(base, "energy") ? base.energy : -1, 
				index: i 
			});
        }
    }

    // Populate enemies from global.allenemies
	for (var i = 0; i < array_length(global.allenemies); i++) {
		var e = global.allenemies[i];
		if (is_undefined(e) || !is_struct(e)) continue;
		if (e.sx == sx && e.sy == sy && e.energy > 0) {
			array_push(s.enemies, { 
				lx: e.lx, 
				ly: e.ly, 
				energy: e.energy, 
				maxenergy: e.maxenergy,
				index: i 
			});
		}
	}

    // Update counts
    s.enemynum = array_length(s.enemies);
    s.basenum = array_length(s.bases);
    s.starnum = array_length(s.stars);

    // Update player arrays if in player's sector
    if (sx == global.ent.sx && sy == global.ent.sy) {
        var player = instance_find(obj_controller_player, 0);
        if (player) {
            player.local_objects = [];
            player.local_enemies = [];
            player.local_stars = [];
            player.local_bases = [];

            // Add stars
			for (var i = 0; i < array_length(s.stars); i++) {
			    var star = s.stars[i];
			    var already_exists = false;
			    for (var j = 0; j < array_length(player.local_objects); j++) {
			        var obj = player.local_objects[j];
			        if (obj.type == "star" && obj.index == star.index) {
			            already_exists = true;
			            break;
			        }
			    }
			    if (!already_exists) {
			        var star_obj = {
			            type: "star",
			            lx: star.lx,
			            ly: star.ly,
			            index: star.index
			        };
			        array_push(player.local_objects, star_obj);
			        array_push(player.local_stars, star_obj);
			    }
			}

			// Add bases
			for (var i = 0; i < array_length(s.bases); i++) {
			    var base = s.bases[i];
			    var already_exists = false;
			    for (var j = 0; j < array_length(player.local_objects); j++) {
			        var obj = player.local_objects[j];
			        if (obj.type == "base" && obj.index == base.index) {
			            already_exists = true;
			            break;
			        }
			    }
			    if (!already_exists) {
			        var base_obj = {
			            type: "base",
			            lx: base.lx,
			            ly: base.ly,
			            energy: base.energy,
			            index: base.index
			        };
			        array_push(player.local_objects, base_obj);
			        array_push(player.local_bases, base_obj);
			    }
			}

			// Add enemies
			for (var i = 0; i < array_length(s.enemies); i++) {
			    var enemy = s.enemies[i];
			    var global_enemy = global.allenemies[enemy.index];
			    if (is_struct(global_enemy) && global_enemy.sx == sx && global_enemy.sy == sy) {
			        var already_exists = false;
			        for (var j = 0; j < array_length(player.local_objects); j++) {
			            var obj = player.local_objects[j];
			            if (obj.type == "enemy" && obj.index == enemy.index) {
			                already_exists = true;
			                break;
			            }
			        }
			        if (!already_exists) {
			            var enemy_obj = {
			                type: "enemy",
			                lx: global_enemy.lx,
			                ly: global_enemy.ly,
			                energy: global_enemy.energy,
			                maxenergy: global_enemy.maxenergy,
			                index: enemy.index
			            };
			            array_push(player.local_objects, enemy_obj);
			            array_push(player.local_enemies, enemy_obj);
			        }
			    }
			}
			
			// Update srs regions only if there are enemies
			if (array_length(player.local_enemies) > 0) {
			    update_srs_regions();
			} else {
			    obj_controller_input.srs_regions = [];
			    obj_controller_input.all_regions = array_concat(obj_controller_input.hover_regions, obj_controller_input.srs_regions);
			}
			
			// Set an alarm to save the game
			obj_controller_player.alarm[0] = 30;
        }
    }

    return s;
}

/// @description: Updates the dynamic enemy regions on the sector grid and pushes to hover_regions
function update_srs_regions() {
	var player = instance_find(obj_controller_player, 0);
	
    // Sector grid
    var map_offset_x = 121;
    var map_offset_y = 31;
    var size_cell_x = 10;
    var size_cell_y = 9;
	
	// Clear existing
	obj_controller_input.all_regions = [];
	obj_controller_input.srs_regions = [];
	
    // Add enemies
    for (var i = 0; i < array_length(player.local_enemies); i++) {
        var enemy = player.local_enemies[i];
        var lx = enemy.lx;
        var ly = enemy.ly;

        // Calculate pixel coordinates of this cell on the SRS
        var x1 = map_offset_x + lx * size_cell_x;
        var y1 = map_offset_y + ly * size_cell_y;
        var x2 = x1 + size_cell_x;
        var y2 = y1 + size_cell_y;

        array_push(obj_controller_input.srs_regions, {
            x1: x1,
            x2: x2,
            y1: y1,
            y2: y2,
            state: HoverState.Enemy + i,
            enemy_index: i
        });
    }
	
	// Combine
	obj_controller_input.all_regions = array_concat(obj_controller_input.hover_regions, obj_controller_input.srs_regions);
}

/// @description: Moves the player to a new sector in the galaxy, called during warp
/// @param {real} x: Sector x coordinate
/// @param {real} y: Sector y coordinate
function change_sector(x, y) {
    // Validate sector coordinates
    if (x < 0 || x > 7 || y < 0 || y > 7) {
        show_debug_message("Tried to move to invalid sector coordinates: [" + string(x) + "," + string(y) + "]");
        return false;
    }
    
    // Save previous sector
	global.ent.prev_sx = global.ent.sx;
	global.ent.prev_sy = global.ent.sy;
    
    // Update current sector
    global.ent.sx = x;
    global.ent.sy = y;
    var sector = global.galaxy[x][y];

	// Clear stale player local data
	var player = instance_find(obj_controller_player, 0);
	if (player) {
	    player.local_enemies = [];
	    player.local_objects = [];
	    player.local_stars = [];
	    player.local_bases = [];
	}
    
    // Assign new player position in the sector
    if (array_length(sector.available_cells) > 0) {
        sector.available_cells = array_shuffle(sector.available_cells);
        sector.seen = true;
        global.ent.lx = sector.available_cells[0][0];
        global.ent.ly = sector.available_cells[0][1];
        // Ensure player’s cell is in available_cells (for pathfinding)
        var player_cell = [global.ent.lx, global.ent.ly];
        var cell_found = false;
        for (var i = 0; i < array_length(sector.available_cells); i++) {
            if (array_equals(sector.available_cells[i], player_cell)) {
                cell_found = true;
                break;
            }
        }
    } else {
        // Fallback if no available cells
        global.ent.lx = irandom(7);
        global.ent.ly = irandom(7);
        // Add fallback cell to available_cells
        var player_cell = [global.ent.lx, global.ent.ly];
        array_push(sector.available_cells, player_cell);
        sector.seen = true;
        show_debug_message("Warning: No available cells in sector [" + string(x) + "," + string(y) + "], added fallback [" + string(global.ent.lx) + "," + string(global.ent.ly) + "]");
    }
	
	// Repopulate local sector data
	get_sector_data(global.ent.sx, global.ent.sy);

	// Clear the resolve queue
	global.queue = [];
	global.index = 0;
	
	// Call the warp movie
	if (!instance_exists(obj_controller_movies)) {
		instance_create_layer(0, 0, "Overlay", obj_controller_movies);
	}
	
	// Queue up new turn events
	array_push(global.queue, function() {
		obj_controller_player.contactedbase = false; // Reset base contact
		obj_controller_player.speech_phaserwarn = false; // Spock can remind the player that phasers are weakened
		obj_controller_player.speech_damaged = false; // Uhura can remind the player of ship damage
		if (random(1) < 0.7) obj_controller_player.speech_phaserfire = false; // Kirk has a 70% chance to have fire phasers speech
		if (random(1) < 0.7) obj_controller_player.speech_torparm = false; // Kirk has a 70% chance to have fire torpedoes speech
	});
	
	debug_sector();
    return true;
}

/// @description: Returns true if (cx, cy) is a valid destination in the current sector
/// @param {real} cx: Cell x
/// @param {real} cy: Cell y
function check_valid_move(cx, cy) {
    // Out-of-bounds check
    if (cx < 0 || cx >= 8 || cy < 0 || cy >= 8) return false;
    var sector = global.galaxy[global.ent.sx][global.ent.sy];

    // Cancel if selecting current position
    if (global.ent.lx == cx && global.ent.ly == cy) {
        return false;
    }

    // Check stars
    for (var i = 0; i < array_length(sector.star_positions); i++) {
        var pos = sector.star_positions[i];
        if (pos[0] == cx && pos[1] == cy) {
            return false;
        }
    }

	// Check enemies
	for (var i = 0; i < array_length(global.allenemies); i++) {
	    var e = global.allenemies[i];
	    if (is_struct(e) && e.sx == global.ent.sx && e.sy == global.ent.sy) {
	        if (e.lx == cx && e.ly == cy) {
	            return false;
	        }
	    }
	}

    // Check starbases
	for (var i = 0; i < array_length(global.allbases); i++) {
	    var b = global.allbases[i];
	    if (b.sx == global.ent.sx && b.sy == global.ent.sy) {
	        if (b.lx == cx && b.ly == cy) {
	            return false;
	        }
	    }
	}

    // All checks passed
    return true;
}

/// @description: Checks if the player is next to a starbase in current sector, called after an impulse move
/// @param {real} lx: Local x coordinate
/// @param {real} ly: Local y coordinate
function check_baseloc(lx, ly) {
    var current_sx = global.ent.sx;
    var current_sy = global.ent.sy;
    
    for (var i = 0; i < array_length(global.allbases); i++) {
        var base = global.allbases[i];
        if (!is_undefined(base) && is_struct(base) && base.sx == current_sx && base.sy == current_sy) {
            var bx = base.lx;
            var by = base.ly;
            if (abs(lx - bx) + abs(ly - by) == 1) {
                return true;
            }
            break;
        }
    }
    
    return false;
}

/// @description: Handles endgame resolution
function winlose() {
	global.inputmode.mode = InputMode.None;

	// Determine outcome based on ship condition
	switch (global.ent.condition) {
		case Condition.Destroyed:
			global.game.state = State.Lose;
			global.audio_handle = audio_play_sound(mus_destroyed, 0, false);
			break;

		case Condition.Stranded:
		case Condition.NoTime:
			global.game.state = State.Lose;
			global.audio_handle = audio_play_sound(mus_bridge_ambient, 0, false);
			break;

		case Condition.Win:
			show_debug_message("Player won!");
			global.game.state = State.Win;

			// Score calculation
			var enemybonus      = global.game.initenemies * 100;
			var timebonus       = global.game.t0 + (global.game.maxdays - global.game.date);
			var basespenalty    = global.game.totalbases * 100;
			var efficiencybonus = global.ent.energy + global.ent.shields + (global.ent.torpedoes * 20);
			var difficultybonus = (global.game.difficulty - 1) * 10;

			global.score = (
				(enemybonus + timebonus - basespenalty + efficiencybonus) * 100
				+ difficultybonus
			) div 100;

			break;
	}

	// Go to endgame screen in all cases
	room_goto(rm_endgame);
}

/// @description: Handles the queue of dialogs and actions
function handle_queue() {
    // Reset input hover state
    obj_controller_input.hover_state = HoverState.None;

    // Only proceed if no voice is playing and attack delay is zero
    if (obj_controller_dialog.voice_handle == -1 && obj_controller_input.attack_delay <= 0) {
        
        // Check if there are unresolved items in the dialog/action queue
        if (global.index < array_length(global.queue)) {

            // Only process the next item if no dialog is shown
            if (!instance_exists(obj_controller_dialog) || !obj_controller_dialog.show_text) {
                // Set busy state
                global.busy = true;

                // Call the next queued method
                var result = global.queue[global.index]();
                global.index++;

                // If function returns a struct and requests a delay, apply it
                if (is_struct(result) && result.delay) {
                    obj_controller_input.attack_delay = result.delay;
					return;
                }

                // If it returned a dialog array, pass it to the dialog handler
                if (result != undefined && is_array(result)) {
                    with (obj_controller_dialog) {
                        process_dialog(result);
                    }
                }
                
                // Exit to enforce delay
                return;
            }
        }
        
        // Queue condition check (once per step)
        else if (!end_turn && global.game.state != State.Win && global.game.state != State.Lose) {
            global.queue[array_length(global.queue)] = function() {
                return update_ship_condition();
            };
            end_turn = true;
        }

        // If queue is fully resolved and no dialog or voice is active
        else {
            if (!obj_controller_dialog.show_text && obj_controller_dialog.voice_handle == -1) {
				// Reset busy only if shields are not negative OR if dialog finished for destroyed condition
				if (global.game.state != State.Win && global.game.state != State.Lose) {
				    if (global.ent.shields >= 0 || 
				       (global.ent.condition == Condition.Destroyed && !obj_controller_dialog.show_text && obj_controller_dialog.voice_handle == -1)) {
				        global.busy = false;
				    }
				}
			}
		}
	}
}
