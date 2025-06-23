/// @description: Entrypoint for enemy attack sequence
/// @param {any} post: Player impulse path (array) or warp destination ([tx, ty]) -- Gets passed into queue_next_enemy_attack
function enemy_attack(post) {
    
    var player = instance_find(obj_controller_player, 0);
	global.busy = true;
	
	// Store the old input mode -- so cursors like impulse are not visible during attacks
	global.inputmode.tmp_old = global.inputmode.mode;
    
    // Get a snapshot of current enemies by copying local_enemies to attack_targets
	// Will prevent desyncs if enemies are destroyed
    var len = array_length(player.local_enemies);
    player.attack_targets = array_create(len, undefined);
    array_copy(player.attack_targets, 0, player.local_enemies, 0, len);
    player.attack_index = 0;
    player.attack_buffer = [];
    player.attack_indexes = [];
    
	// Header for debug logs
    show_debug_message("[STARTING ENEMY ATTACK SEQUENCE]");
    show_debug_message("Found " + string(len) + " enemies to queue for attack.");
    
    // Start first attack
    queue_next_enemy_attack(0, post);
}

/// @description: Recursive function that queues an enemy attack in an attack sequence
/// @param {real} i: Index in attack_targets to process
/// @param {any} post: Player impulse path (array) or warp destination ([tx, ty])
function queue_next_enemy_attack(i, post) {
    var player = instance_find(obj_controller_player, 0);
    var targets = player.attack_targets;
    
	// Check if all attacks have been processed
	if (i >= array_length(targets)) {
	    array_push(global.queue, function() {
	        var data = obj_controller_player._data;
	        show_debug_message("[ENEMY ATTACK SEQUENCE RESOLVED]");
	        global.inputmode.mode = global.inputmode.tmp_old;
	        if (global.ent.condition != Condition.Destroyed) {
				// If it's a big array it's impulse path
	            if (is_array(data.post) && array_length(data.post) > 0 && is_array(data.post[0])) {
	                global.ent.impulse_move(data.post);
				// Else it's warp coordinates
	            } else if (is_array(data.post) && array_length(data.post) == 2) {
	                var tx = data.post[0];
	                var ty = data.post[1];
	                show_debug_message("Warping to sector: [" + string(tx) + "," + string(ty) + "]");
	                change_sector(tx, ty);
	            }
	        }
	        return { delay: 10 };
	    });
		
		// Cleanup
	    array_push(global.queue, function() {
	        obj_controller_player.attack_targets = [];
	        obj_controller_player.attack_buffer = [];
	        obj_controller_player.attack_indexes = [];
	        obj_controller_player._data = undefined;
	        global.queue = [];
	        global.index = 0;
	        global.busy = false;
	        return undefined;
	    });
	    return;
	}
    
	// Capture which enemy we'll be using for this attack
    var e = targets[i];
    
    // Validate enemy
    if (!is_struct(e) || is_undefined(global.allenemies[e.index]) || !is_struct(global.allenemies[e.index]) || 
        global.allenemies[e.index].energy <= 0 || global.allenemies[e.index].sx != global.ent.sx || 
        global.allenemies[e.index].sy != global.ent.sy) {
        show_debug_message("Skipping invalid enemy index " + string(e.index) + " at [" + string(e.lx) + "," + string(e.ly) + "]");
        queue_next_enemy_attack(i + 1, post);
        return;
    }
    
    // Use global.allenemies for coordinates to ensure sync
    var global_enemy = global.allenemies[e.index];
    var px = global.ent.lx;
    var py = global.ent.ly;
    var lx = global_enemy.lx;
    var ly = global_enemy.ly;
    var dx = abs(px - lx);
    var dy = abs(py - ly);
    var distance = max(sqrt(dx * dx + dy * dy), 1);
    var modifier = 2.0 + random(1.0);
    var damage = ceil((global_enemy.energy / 2) * modifier / distance);
    
    var queue_index = array_length(global.queue);
	
	// Purge stale data and refresh
	obj_controller_player._data = undefined;
    obj_controller_player._data = {
        lx: lx,
        ly: ly,
        energy: global_enemy.energy,
        idx: e.index,
        px: px,
        py: py,
        difficulty: global.game.difficulty,
        damage: damage,
        base_index: queue_index,
        current_enemy: i,
        attack_count: array_length(targets),
		i: i,
		post: post,
    };
    
	// Refill attack arrays and reserve space for following queue slots
    player.attack_buffer[queue_index] = obj_controller_player._data;
    player.attack_indexes[queue_index] = queue_index;
    player.attack_indexes[queue_index + 1] = queue_index;
    player.attack_indexes[queue_index + 2] = queue_index;
    player.attack_indexes[queue_index + 3] = queue_index;
    if (i < array_length(targets) - 1) {
        player.attack_indexes[queue_index + 4] = queue_index;
    }
    
    show_debug_message("Enemy " + string(e.index) + " at [" + string(lx) + "," + string(ly) + "] attacking player at [" + 
        string(px) + "," + string(py) + "] | Distance: " + string(distance) + 
        " | Energy: " + string(global_enemy.energy) + " | Modifier: " + string(modifier) + 
        " | Damage: " + string(damage));
    
    // Queue attack -- 1-based to be user friendly
	array_push(global.queue, function() {
	    var idx = obj_controller_player.attack_indexes[global.index];
	    var data = obj_controller_player.attack_buffer[idx];
	    // Add 1 to lx and ly for user display
	    return immediate_dialog("Sulu", "battle.enemyfiring", noone, {
	        coord: string(data.lx + 1) + "," + string(data.ly + 1)
	    });
	});
    
	// Queue effects -- enemy faces player, creates disruptor beam
    array_push(global.queue, function() {
        var idx = obj_controller_player.attack_indexes[global.index];
        var data = obj_controller_player.attack_buffer[idx];
        var enemy = global.allenemies[data.idx];
        
        if (enemy != undefined && is_struct(enemy)) {
            if (enemy.lx == data.px && enemy.ly == data.py) {
                enemy.dir = enemy.dir;
            } else {
                var dx = data.px - enemy.lx;
                var dy = data.py - enemy.ly;
                var dir;
                if (abs(dx) >= abs(dy)) {
                    dir = dx > 0 ? 1 : 3;
                } else {
                    dir = dy > 0 ? 2 : 0;
                }
                enemy.dir = dir;
            }
        }
        
        audio_play_sound(snd_enemy_phaser, 0, false);
        var p = instance_create_layer(0, 0, "Overlay", obj_phaser);
        p.x1 = data.lx;
        p.y1 = data.ly;
        p.x2 = data.px;
        p.y2 = data.py;
        p.type = 2;
        p.duration = 40;
        return { delay: 40 };
    });
    
	// Queue dialog for crew reaction and calculate damages if any
    array_push(global.queue, function() {
        var idx = obj_controller_player.attack_indexes[global.index];
        var data = obj_controller_player.attack_buffer[idx];
        var keys = variable_struct_get_names(global.ent.system);
        
        if (data.damage < 1) {
            return immediate_dialog("Sulu", "battle.evade");
        }
        
		// Player loses shields
        global.ent.shields -= round(data.damage);
        show_debug_message("Player was hit for " + string(round(data.damage)) + " units of damage!");
        damage_random_systems(round(data.damage / (10 - data.difficulty)));
        
		// Update general damage
        global.ent.generaldamage = 0;
        for (var j = 0; j < array_length(keys); j++) {
            var val = global.ent.system[$ keys[j]];
            if (val < 90 && global.ent.generaldamage < 1) global.ent.generaldamage = 1;
            if (val < 66 && global.ent.generaldamage < 2) global.ent.generaldamage = 2;
            if (val < 33 && global.ent.generaldamage < 3) global.ent.generaldamage = 3;
        }
        
		// Enemy used energy to attack, deduct it
        var emodifier = max(1.1, 3.0 + random(1.0));
        if (is_struct(global.allenemies[data.idx])) {
            global.allenemies[data.idx].energy = max(round(global.allenemies[data.idx].energy / emodifier), 0);
        }
        
		// If player was destroyed, halt queue and immediately begin gameover sequence
        if (global.ent.shields < 0) {
            global.ent.condition = Condition.Destroyed;
            global.busy = true;
            array_resize(global.queue, global.index);
            array_push(global.queue, function() {
                return [immediate_dialog("Spock", "redalert.shieldsdown")[0]];
            });
            array_push(global.queue, function() {
                dialog_condition();
                return undefined;
            });
            return undefined;
        }
        
		// Various reaction dialogs
        var spock_dialog = [];
        if (obj_controller_player.speech_phaserhit) {
            spock_dialog = [immediate_dialog("Spock", "battle.enthit2", noone, { energy: round(data.damage) })[0]];
        } else {
            spock_dialog = [immediate_dialog("Spock", "battle.enthit1", vo_spock_phaser_hit)[0]];
        }
        obj_controller_player.speech_phaserhit = !obj_controller_player.speech_phaserhit;
        
        var shield_dialog = [];
        if (global.ent.shields > 200 && global.ent.generaldamage < 1) {
            shield_dialog = [immediate_dialog("Scott", "battle.shields1")[0]];
        } else if (global.ent.shields < 10) {
            shield_dialog = [immediate_dialog("Spock", "redalert.shieldsdown")[0]];
        } else {
            shield_dialog = [immediate_dialog("Spock", "battle.shields2", noone, { shields: global.ent.shields })[0]];
        }
        
        var gendmg_dialog = [];
        if (global.ent.generaldamage > 2) {
            gendmg_dialog = [immediate_dialog("Scott", "gendmg.major")[0]];
        } else if (global.ent.generaldamage > 0 && !obj_controller_player.speech_damage) {
            gendmg_dialog = [
                immediate_dialog("Uhura", "gendmg.minor")[0],
                immediate_dialog("McCoy", "gendmg.minor2", vo_mccoy_sickbay)[0]
            ];
        }
        obj_controller_player.speech_damage = global.ent.generaldamage > 0;
        
        return array_concat(spock_dialog, shield_dialog, gendmg_dialog);
    });
    
	// Queue the next enemy attack
    array_push(global.queue, function() {
        var idx = obj_controller_player.attack_indexes[global.index];
		var data = obj_controller_player._data;
        queue_next_enemy_attack(data.i + 1, data.post);
    });
    
	// Queue a delay if more attacks follow
    if (i < array_length(targets) - 1) {
        array_push(global.queue, function() {
            return { delay: 40 };
        });
    }
}


/// @description: Begins the player's phaser attack sequence
function player_phaser_attack() {
    global.busy = true;

    // Copy enemies at the time of the attack start
	var len = array_length(obj_controller_player.local_enemies);
	obj_controller_player.attack_targets = array_create(len, undefined);

	// Copy from source into destination
	array_copy(obj_controller_player.attack_targets, 0, obj_controller_player.local_enemies, 0, len);
    obj_controller_player.attack_index = 0;

    obj_controller_player.attack_buffer = [];

    // Calculate phaser allotment per enemy
    var total_targets = array_length(obj_controller_player.attack_targets);
    var total_phasers = global.ent.phasers;
    var per_enemy_phasers = round(total_phasers / total_targets);

    global.ent.phasers -= per_enemy_phasers * total_targets;
    global.ent.phasers = max(0, global.ent.phasers);

    obj_controller_player.attack_phasers = per_enemy_phasers;
    obj_controller_player.attack_difficulty = global.game.difficulty;

    show_debug_message("[STARTING PLAYER ATTACK SEQUENCE]");
    show_debug_message("Player allotted " + string(total_phasers) + " energy to phasers.");
    show_debug_message("Calculated " + string(per_enemy_phasers) + " phasers per enemy.");

    // Start first attack
    queue_next_attack(0);
}

/// @description: Recursive function to queue a player phaser attack for an enemy
/// @param {real} i: Index in attack_targets to process
function queue_next_attack(i) {
    var targets = obj_controller_player.attack_targets;

	// Check if we're finished with the sequence
    if (i >= array_length(targets)) {
		obj_controller_player._data = undefined;
        array_push(global.queue, function() {
            show_debug_message("[PLAYER ATTACK SEQUENCE RESOLVED]");
            if (array_length(obj_controller_player.local_enemies) > 0) {
                enemy_attack();
            }
        });
        return;
    }

	// Capture the enemy to target
    var e = targets[i];

    // Check if still valid
    if (!is_struct(e) || is_undefined(global.allenemies[e.index]) || global.allenemies[e.index].energy <= 0) {
        // Skip and try next
        queue_next_attack(i + 1);
        return;
    }

    // Calculate attack details
    var px = global.ent.lx;
    var py = global.ent.ly;
    var dx = abs(px - e.lx);
    var dy = abs(py - e.ly);
    var distance = max(sqrt(dx * dx + dy * dy), 1);
    var modifier = min(2.5 + random(1.0), 3.5);
    var damage = ceil(obj_controller_player.attack_phasers * modifier / distance);
    var current_energy = global.allenemies[e.index].energy;

	// Capture data for queue closure
    obj_controller_player._data = {
        px: px, py: py,
        lx: e.lx, ly: e.ly,
        idx: e.index,
        difficulty: obj_controller_player.attack_difficulty,
        damage: damage,
        energy: current_energy,
		i: i
    };

    obj_controller_player.attack_buffer[i] = obj_controller_player._data;

    // Visual effect
    array_push(global.queue, function() {
        audio_play_sound(snd_player_phaser, 0, false);
        var p = instance_create_layer(0, 0, "Overlay", obj_phaser);
		var px = obj_controller_player._data.px, py = obj_controller_player._data.py;
		var lx = obj_controller_player._data.lx, ly = obj_controller_player._data.ly;
        p.x1 = px; p.y1 = py;
        p.x2 = lx; p.y2 = ly;
        p.type = 1;
        p.duration = 40;
        return { delay: 40 };
    });

    // Damage and dialog
    array_push(global.queue, function() {
		var current_energy = obj_controller_player._data.energy;
		var damage = obj_controller_player._data.damage;
		var px = obj_controller_player._data.px, py = obj_controller_player._data.py;
		var lx = obj_controller_player._data.lx, ly = obj_controller_player._data.ly;
		var idx = obj_controller_player._data.idx;
        var new_energy = max(current_energy - damage, 0);
        global.allenemies[idx].energy = new_energy;

        show_debug_message("Firing on enemy index " + string(idx) + " at [" + string(lx) + "," + string(ly) + "].");
        show_debug_message("Calculated " + string(damage) + " damage. Enemy energy now " + string(new_energy) + " down from " + string(current_energy) + ".");

        if (damage < current_energy / 7) {
            return immediate_dialog("Chekov", "phasers.noeffect");
        }

        var sulu = immediate_dialog("Sulu", "weapons.enemyhit", noone, {
            hp: damage,
            coord: string(lx + 1) + "," + string(ly + 1)
        });

        if (new_energy > 90) {
            return [sulu[0], immediate_dialog("Spock", "weapons.energyleft", noone, { energy: round(new_energy) })[0]];
        } else if (new_energy <= 0) {
            var result = destroy_enemy(idx);
            if (is_array(result)) return [sulu[0], result[0]];
            return [sulu[0]];
        }

        return [sulu[0]];
    });

    // Next attack
    array_push(global.queue, function() {
		var i = obj_controller_player._data.i;
		obj_controller_player._data = undefined;
        queue_next_attack(i + 1);
    });
}

/// @description: Removes an enemy from the galaxy, creates explosion effect, and queues dialog
/// @param {real} idx: Enemy index in global.allenemies
function destroy_enemy(idx) {
    if (idx < 0 || idx >= array_length(global.allenemies) || is_undefined(global.allenemies[idx]) || !is_struct(global.allenemies[idx])) {
        show_debug_message("Error: Invalid enemy index " + string(idx));
        return;
    }
    
    var e = global.allenemies[idx];

    // Create explosion effect
    audio_play_sound(snd_explosionsmall, 0, false);
    var ex = instance_create_layer(0, 0, "Overlay", obj_explosion, {
        lx: e.lx,
        ly: e.ly
    });
    particle_explosion(e.lx, e.ly);
    
    // Update game state
    array_delete(global.allenemies, idx, 1);
    global.game.totalenemies = max(global.game.totalenemies - 1, 0);

    // Update local sector's enemy count
    var sx = e.sx;
    var sy = e.sy;
    var sector = global.galaxy[sx][sy];
    sector.enemynum = max(sector.enemynum - 1, 0);
    array_push(sector.available_cells, [e.lx, e.ly]);
    
    show_debug_message("Enemy at [" + string(e.lx) + "," + string(e.ly) + "] destroyed!");
    
    // Update local_objects if in player's sector
    if (sx == global.ent.sx && sy == global.ent.sy) {
        var player = instance_find(obj_controller_player, 0);
        if (player) {
            for (var i = array_length(player.local_objects) - 1; i >= 0; i--) {
                var obj = player.local_objects[i];
                if (is_struct(obj) && obj.type == "enemy" && obj.index == idx) {
                    array_delete(player.local_objects, i, 1);
                }
				else {
					obj.index -= 1;
				}
            }
            for (var i = array_length(player.local_enemies) - 1; i >= 0; i--) {
                var obj = player.local_enemies[i];
                if (is_struct(obj) && obj.index == idx) {
                    array_delete(player.local_enemies, i, 1);
                }
				else {
					obj.index -= 1;
				}
            }
        }
    }
    
    // No other ships
    if (sector.enemynum < 1) {
        global.busy = true;
        array_push(global.queue, function() {
            return { delay: 60 };
        });
        queue_dialog("Spock", "weapons.lastone", vo_spock_noships);
    }
    
    // Check if player won
    if (global.game.totalenemies <= 0) {
        global.busy = true;
        array_resize(global.queue, global.index);
        array_push(global.queue, function() {
            return immediate_dialog("Uhura", "condition.win1");
        });
        array_push(global.queue, function() {
            return immediate_dialog("Kirk", "condition.win2", vo_kirk_onscreen);
        });
        array_push(global.queue, function() {
            global.ent.condition = Condition.Win;
            global.busy = true;
            winlose();
            return undefined;
        });
    } else {
        get_sector_data();
    }
}