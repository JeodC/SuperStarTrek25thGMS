/// @description: Checks if the player can warp
/// @param {real} sx: Destination sector x
/// @param {real} sy: Destination sector y
function action_warp(sx, sy) {
	var sector = global.galaxy[global.ent.sx][global.ent.sy];

	var distance = point_distance(sx, sy, global.ent.sx, global.ent.sy);

	// If trying to warp to current sector, treat as cancel
	if (sx == global.ent.sx && sy == global.ent.sy) {
		return false;
	}

	var energy_required = ((distance * distance) * 2.0);
	var max_speed = (global.ent.system.warp / 100) * 10;

	// Too far to warp
	if (distance > max_speed) {
		queue_dialog("Scott", "move.toofar");
		return false;
	}

	// Check for energy
	if (energy_required > global.ent.energy) {
		var total_available = global.ent.energy + global.ent.shields;

		if (total_available >= ceil(energy_required)) {
			var needed = ceil(energy_required) - global.ent.energy;
			global.ent.shields -= needed;
			global.ent.energy += needed;
			queue_dialog("Scott", "move.divert");
			// Deduct energy for warp
			global.ent.energy -= ceil(energy_required);
			global.ent.isdocked = false;
			show_debug_message("Warp to sector " + string(sx) + "," + string(sy) + " using " + string(ceil(energy_required)) + " units of energy.");
			return true;
		} else {
			queue_dialog("Scott", "move.noenergy");
			return false;
		}
	}

	// If sector has enemies, store warp destination and queue enemy attack
	if (sector.enemynum > 0) {
		obj_controller_player.display = Reports.Default;
		obj_controller_player._warpto = [sx, sy];
		array_push(global.queue, function() {
			enemy_attack(obj_controller_player._warpto);
		});
		return undefined;
	}

	// Warp allowed, deduct energy
	global.ent.energy -= ceil(energy_required);
	global.ent.isdocked = false;
	show_debug_message("Warp to sector " + string(sx) + "," + string(sy) + " using " + string(ceil(energy_required)) + " units of energy.");
	return true;
}

/// @description: Attempts to move the player to the selected cell in the current sector
function action_impulse() {
    var sector = global.galaxy[global.ent.sx][global.ent.sy];

    if (global.inputmode.type == "cancel") {
        return false;
    }

    if (global.inputmode.type == "confirm") {
        var cx = global.inputmode.cursor_x;
        var cy = global.inputmode.cursor_y;

		// Check valid move (scr_resolve)
        if (check_valid_move(cx, cy)) {
			var path = find_path(global.ent.lx, global.ent.ly, cx, cy, sector);
			
			if (path != undefined) {
				if (sector.enemynum < 1) {
					global.ent.impulse_move(path);
					global.ent.isdocked = false;
					return true;
				}
				else {
					// Enemies attack first but the function processes the move after
					obj_controller_player._path = path;
					array_push(global.queue, function() {
						enemy_attack(obj_controller_player._path);
					});
					return true;
				}
            } else {
                queue_dialog("None", "engines.impulse.invalid");
                return false;
            }
		} else {
			queue_dialog("None", "engines.impulse.invalid");
			 return false
        }
    }
    // No confirm/cancel input — do nothing
    return undefined;
}

/// @description: Fires a torpedo along the specified angle toward the target in an 8x8 sector grid
/// @param {real} tx: Target x in local units [0-7]
/// @param {real} ty: Target y in local units [0-7]
function action_torpedo(tx, ty) {
    // Player's position
    var px = global.ent.lx;
    var py = global.ent.ly;

    // Map parameters
    var map_offset_x = 121;
    var map_offset_y = 31;
    var size_cell_x = 10;
    var size_cell_y = 9;

    // Convert player's grid position to pixel coordinates (center of cell)
    var pixel_x = map_offset_x + px * size_cell_x + size_cell_x / 2;
    var pixel_y = map_offset_y + py * size_cell_y + size_cell_y / 2;

    // Use the player's torpedo angle
    var angle = obj_controller_player.torp_angle;

    // Create torpedo at player's pixel position
    var torpedo = instance_create_layer(pixel_x, pixel_y, "Overlay", obj_torpedo);
    
    // Set torpedo properties
    audio_play_sound(snd_torpedo, 0, 0, false);
    torpedo.direction = angle;
    torpedo.speed = 0.3;
    torpedo.grid_target_x = tx;
    torpedo.grid_target_y = ty;
    torpedo.grid_x = px;
    torpedo.grid_y = py;
    torpedo.max_range = 7;
    torpedo.distance_traveled = 0;
    torpedo.damage = 10;
}

/// @description: Applies changed state for shields or phasers
/// @param {enum} type: HoverState enum to change
/// @param {real} value: Value to change
function action_apply_change(type, value) {
    switch (type) {
        case HoverState.Shields:
            var old_shields = global.ent.shields;
            var new_shields = clamp(value, 0, global.ent.energy);
            var shield_change = new_shields - old_shields;
        
            if (shield_change > 0) {
                if (global.ent.energy < shield_change) {
					return queue_dialog("Scott", "shields.notchanged");
                }
                global.ent.energy -= shield_change;
                var shield_value = new_shields;
				queue_dialog("Scott", "shields.raised", undefined, { energy: shield_value });
            } else if (shield_change < 0) {
                global.ent.energy -= shield_change;
                if (global.ent.energy > global.game.maxenergy) {
                    global.ent.energy = global.game.maxenergy;
                }
                queue_dialog("Scott", "shields.lowered");
            } else {
                queue_dialog("Scott", "shields.notchanged");
            }
			
            global.ent.shields = new_shields;
            break;
        case HoverState.Phasers:
            var old_phasers = global.ent.phasers;
            var new_phasers = clamp(value, 0, global.ent.energy);
            var phaser_change = new_phasers - old_phasers;
        
            if (phaser_change > 0) {
                if (global.ent.energy < phaser_change) {
                    var energy_value = global.ent.energy;
                    return queue_dialog("Chekov", "phasers.toohigh");
                }
                global.ent.energy -= phaser_change;
                var phaser_value = new_phasers;
                queue_dialog("Chekov", "phasers.raised", vo_chekov_phasers_armed, undefined);
                // Queue the player attack
				var queue = global.queue;
				var q_len = array_length(queue);
				queue[q_len] = function() {
					player_phaser_attack();
				};
            }
        
            global.ent.phasers = new_phasers;
            break;
    }
}

/// @description: Changes the state of shields or phasers
/// @param {real} state: State type (HoverState.Shields, HoverState.Phasers)
function action_setstate(state) {
    switch (state) {
        case HoverState.Shields:
        case HoverState.Phasers:
            var system = (state == HoverState.Shields) ? "shields" : "phasers";
            var value_field = system;
            var speaker = (state == HoverState.Shields) ? "Scott" : "Chekov";
            var line = (state == HoverState.Shields) ? "shields.damaged" : "phasers.damaged";

			// System is damaged, return early
            if (variable_instance_get(global.ent.system, system) < 10) {
                queue_dialog(speaker, line);	
                return;
            }

            global.inputmode.mode = InputMode.Manage;
            global.inputmode.type = state;
            global.inputmode.tmp_old = variable_instance_get(global.ent, value_field);
            global.inputmode.tmp_new = global.inputmode.tmp_old;
            global.busy = true;
            break;
        default:
            break;
    }
}

/// @description: Collects the reports data to display on the console
/// @param {real} status: Reports type (Damage, Mission, Scan)
function action_on_screen(status) {
	var data = undefined;
	switch (status) {
		// Display values as percentages on screen, goes away when player confirms
		case Reports.Damage:
			// Return system percentages (0–100)
            data = {
                warp_engines: global.ent.system.warp,
                short_range_sensors: global.ent.system.srs,
                long_range_sensors: global.ent.system.lrs,
                phaser_controls: global.ent.system.phasers,
                photon_tubes: global.ent.system.torpedoes,
                navigation_computer: global.ent.system.navigation,
                shields_controls: global.ent.system.shields,
            };
            break;
		case Reports.Mission:
			// Return mission stats
            data = {
                total_energy: (global.ent.energy + global.ent.shields),
                energy_to_shields: global.ent.shields,
                available_energy: (global.ent.energy),
                torpedoes: global.ent.torpedoes,
                enemies_left: global.game.totalenemies,
                enemies_destroyed: (global.game.initenemies - global.game.totalenemies),
                days_remaining: (global.game.t0 + (global.game.maxdays - global.game.date)),
            };
            break;
		case Reports.Scan:
		    data = array_create(9, "***"); // Initialize 3x3 grid as 1D array
		    var current_sx = global.ent.sx;
		    var current_sy = global.ent.sy;
			var galaxy_width = array_length(global.galaxy);
			var galaxy_height = array_length(global.galaxy[0]);
    
		    // Iterate over 3x3 grid around current sector
		    for (var dx = -1; dx <= 1; dx++) {
		        for (var dy = -1; dy <= 1; dy++) {
		            var sx = current_sx + dx;
		            var sy = current_sy + dy;
					var index = (dy + 1) * 3 + (dx + 1); // Map to 0-8 index
					var sector = action_lrs(sx, sy);
					if (sector.enemynum >= 0) { // Invalid sectors would be -1 here
					var e = string(sector.enemynum);
					var b = string(sector.basenum);
					var s = string(sector.starnum);
					data[index] = e + b + s;
					global.galaxy[sx][sy].seen = true;
				}
			}
		}
		    break;
		default:
			break;
	}
	return data;	
}

/// @description: Returns the contents of the requested sector
/// @param {real} sx: Sector x coordinate
/// @param {real} sy: Sector y coordinate
function action_lrs(sx, sy) {
    var s = { enemynum: -1, basenum: -1, starnum: -1 };

    if (!is_array(global.galaxy)) return s;
    if (sx < 0 || sx >= array_length(global.galaxy)) return s;
    if (!is_array(global.galaxy[sx])) return s;
    if (sy < 0 || sy >= array_length(global.galaxy[sx])) return s;

    return global.galaxy[sx][sy];
}

/// @description: Handles when player docks with nearby starbase
function action_stardock() {
	global.ent.isdocked = true;
	queue_dialog("Kirk", "contact.docking");
	// Refill
	show_debug_message("Player refilled at Starbase!");
	global.queue[array_length(global.queue)] = function() {
		obj_controller_player.display = Reports.Default;
		global.inputmode.mode = InputMode.Bridge;
		init_enterprise();
	};
}