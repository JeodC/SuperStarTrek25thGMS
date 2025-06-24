/// @description: Queue Chekov's intro line
function dialog_introspeech() {
	queue_dialog(Speaker.Chekov, "gamestart.intro", vo_chekov_approaching);
}

/// @description: Queue text that tells the player how to open the Help menu
function dialog_helptext() {
	queue_dialog(Speaker.None, "gamestart.help", noone, { key: get_keyname("help") });
}

/// @description: Check for enemies in the current sector and queue appropriate dialogs
function dialog_enemy_check() {
	var sector = global.galaxy[global.ent.sx][global.ent.sy];
	
    // No enemies present, bail early
    if (!sector.enemynum && !obj_controller_player.speech_suggestedlrs) {
        obj_controller_player.speech_suggestedlrs = true;
		queue_dialog(Speaker.Spock, "gamestart.suggestlrs");
    }

    // Enemies detected
	if (sector.enemynum > 0) {
    
	    // Add Uhura's line only if first enemy encounter
	    if (!obj_controller_player.firstenemyspotted) {
			obj_controller_player.firstenemyspotted = true;
			queue_dialog(Speaker.Uhura, "gamestart.enemyspotted", vo_uhura_enemy_spotted, undefined);
	    }
    
	    // Always add Kirk's red alert
		queue_dialog(Speaker.Kirk, "redalert.announce", vo_kirk_red_alert);

	    // Spock chimes in if shields are down or low
	    if (global.ent.shields == 0) {
			queue_dialog(Speaker.Spock, "redalert.shieldsdown", vo_spock_shields_down, undefined);
	    }
	    else if (global.ent.shields < 200) {
	        queue_dialog(Speaker.Spock, "redalert.shieldslow");
	    }

	    // Scotty chimes in if Enterprise needs repairs or if energy is low
	    if (global.ent.condition != Condition.Green) {
			var dockable = (sector.basenum > 0)
	        var line_id = dockable ? "nearbase.repair" : "findbase.repair";
	        queue_dialog(Speaker.Scott, line_id);
	    }
	    // Spock chimes in if low energy
	    else if (global.ent.energy + global.ent.shields < 750) {
			var dockable = (sector.basenum > 0)
	        var line_id = dockable ? "nearbase.lowenergy" : "findbase.lowenergy";
	        queue_dialog(Speaker.Spock, line_id);
	    }
	}
}

/// @description: React to navigation command sent by player
/// @param {real} mode: Warp (1), Impulse (2)
function dialog_navigation(mode) {
    var sector = global.galaxy[global.ent.sx][global.ent.sy];
	
    if (mode == 1) {
        queue_dialog(Speaker.Kirk, "engines.warp.engage", vo_kirk_warp, undefined);
        if (global.ent.system.warp < 10) {
            queue_dialog(Speaker.Spock, "engines.warp.damaged");
        } else if (sector.enemynum > 0) {
            queue_dialog(Speaker.Sulu, "engines.warn1");
			// Pull up the warp map anyway
			global.inputmode.cursor_x = global.ent.sx;
			global.inputmode.cursor_y = global.ent.sy;
			global.queue[array_length(global.queue)] = function() {
				obj_controller_player.display = Reports.Warp; // Stop drawing the current sector and draw the galaxy map
				global.inputmode.mode = InputMode.Warp;
			};
        } else {
            queue_dialog(Speaker.Sulu, "engines.aye", vo_sulu_aye, undefined);
			// Pull up the warp map
			global.inputmode.cursor_x = global.ent.sx;
			global.inputmode.cursor_y = global.ent.sy;
			global.queue[array_length(global.queue)] = function() {
				obj_controller_player.display = Reports.Warp; // Stop drawing the current sector and draw the galaxy map
				global.inputmode.mode = InputMode.Warp;
			};
        }
    }
	else if (mode == 2) {
        queue_dialog(Speaker.Kirk, "engines.impulse.engage", vo_kirk_impulse, undefined);
        if (global.ent.system.navigation < 10) {
            queue_dialog(Speaker.Sulu, "engines.impulse.damaged");
        } else if (sector.enemynum > 0) {
            queue_dialog(Speaker.Sulu, "engines.warn2");
			if (!obj_controller_player.impulsehelp) {
				queue_dialog(Speaker.None, "engines.impulse.help1", noone, { key: get_keyname("move") });
				queue_dialog(Speaker.None, "engines.impulse.help2", noone, { key: get_keyname("confirm") });
				obj_controller_player.impulsehelp = true;
			}
			// Enemies will attack if player moves but the player can move anyway
			global.queue[array_length(global.queue)] = function() {
				obj_controller_player.display = Reports.Impulse;
				global.inputmode.mode = InputMode.Impulse;
				global.inputmode.cursor_x = global.ent.lx;
				global.inputmode.cursor_y = global.ent.ly;
			};
        } else {
            queue_dialog(Speaker.Sulu, "engines.aye", vo_sulu_aye, undefined);
			if (!obj_controller_player.impulsehelp) {
				queue_dialog(Speaker.None, "engines.impulse.help1", -1, { key: get_keyname("move") });
				queue_dialog(Speaker.None, "engines.impulse.help2", -1, { key: get_keyname("confirm") });
				obj_controller_player.impulsehelp = true;
			}
			// Queue impulse mode after dialog
			global.queue[array_length(global.queue)] = function() {
				obj_controller_player.display = Reports.Impulse;
				global.inputmode.mode = InputMode.Impulse;
				global.inputmode.cursor_x = global.ent.lx;
				global.inputmode.cursor_y = global.ent.ly;
			};
        }
    }
}

/// @description: React to weapons command sent by player
/// @param {real} mode: Phasers (1), Torpedoes (2)
function dialog_weapons(mode) {
    var sector = global.galaxy[global.ent.sx][global.ent.sy];
    
    if (sector.enemynum < 1) {
        queue_dialog(Speaker.Chekov, "weapons.noships");
        return;
    }

    switch (mode) {
        case 1:
			if (!obj_controller_player.speech_phaserfire) queue_dialog(Speaker.Kirk, "phasers.fire", vo_kirk_fire_phasers, undefined);
			obj_controller_player.speech_phaserfire = true;
			// Check responses
            if (global.ent.system.phasers < 15) {
                queue_dialog(Speaker.Chekov, "phasers.damaged");
            } else if (global.ent.system.phasers < 85) {
                queue_dialog(Speaker.Spock, "phasers.weak");
				action_setstate(HoverState.Phasers);
            } else if (sector.enemynum < 1) {
                queue_dialog(Speaker.Spock, "weapons.noships");
            }
			else {
				action_setstate(HoverState.Phasers);
			}
            break;
        case 2:
            if (!obj_controller_player.speech_torparm) queue_dialog(Speaker.Kirk, "torpedo.fire", vo_kirk_arm_torpedo, undefined);
			obj_controller_player.speech_torparm = true;
			// Check response
            if (global.ent.torpedoes < 1) {
                queue_dialog(Speaker.Chekov, "torpedo.depleted");
            } else if (global.ent.torpedoes == 0) {
                queue_dialog(Speaker.Spock, "torpedo.damaged");
            } else {
                queue_dialog(Speaker.Chekov, "torpedo.ready", vo_chekov_torpedoes, undefined);
				global.queue[array_length(global.queue)] = function() {
					obj_controller_player.display = Reports.Torpedoes;
					global.inputmode.mode = InputMode.Torpedoes;
					global.inputmode.cursor_x = global.ent.lx;
					global.inputmode.cursor_y = global.ent.ly;
				};
            }
            break;
    }
}

/// @description: Queues dialog for report requests and returns dialog structs
/// @param {real} report: Type enum (Reports.Damage, Reports.Mission, Reports.Scan)
function dialog_report(report) {
    var result = [];   
    switch (report) {
        case Reports.Damage:
            array_push(result, { speaker: Speaker.Kirk, line: lang_get("report.damage"), voice: vo_kirk_scott_report });
            switch (global.ent.generaldamage) {
                case 0:
                    array_push(result, { speaker: Speaker.Scott, line: lang_get("report.gendamage0") });
                    break;
                case 1:
                case 2:
                    array_push(result, { speaker: Speaker.Scott, line: lang_get("report.gendamage2") });
                    break;
                case 3:
                    array_push(result, { speaker: Speaker.Scott, line: lang_get("report.gendamage3") });
                    break;
            }
            if (global.ent.system.srs >= 50) {
                array_push(result, { speaker: Speaker.Scott, line: lang_get("report.console") });
            } else {
                array_push(result, { speaker: Speaker.Scott, line: lang_get("report.screenbroken") });
            }
            break;
        case Reports.Mission:
            array_push(result, { speaker: Speaker.Kirk, line: lang_get("report.mission"), voice: vo_kirk_spock });
            if (global.ent.system.srs >= 50) {
                array_push(result, { speaker: Speaker.Spock, line: lang_get("report.onscreen"), voice: vo_spock_onscreen });
            } else {
                array_push(result, { speaker: Speaker.Spock, line: lang_get("report.screenbroken") });
            }
            break;
        case Reports.Scan:
            if (obj_controller_player.askedforlrs < 2) {
                array_push(result, { speaker: Speaker.Kirk, line: lang_get("lrs.request"), voice: vo_kirk_sensor_scan });
            }
            if (global.ent.system.lrs >= 50) {
                array_push(result, { speaker: Speaker.Spock, line: lang_get("report.onscreen"), voice: vo_spock_onscreen });
            } else {
                array_push(result, { speaker: Speaker.Spock, line: lang_get("report.screenbroken") });
            }
            break;
    }
    
    return result;
}

/// @description Queues dialog for starbase docking requests
function dialog_docking() {
    var sector = global.galaxy[global.ent.sx][global.ent.sy];
    
    if (sector.basenum < 1) {
        queue_dialog(Speaker.Kirk, "contact.requestbase1", vo_kirk_uhura, undefined);
        queue_dialog(Speaker.Kirk, "contact.requestbase2");
        queue_dialog("Uhura", "contact.nobases");
    } else {
        queue_dialog(Speaker.Kirk, "contact.nearbase", vo_kirk_starbase, undefined);
        if (sector.enemynum > 0) {
            queue_dialog("Uhura", "contact.danger");
        } else {
            queue_dialog("Uhura", "contact.candock");
            obj_controller_player.contactedbase = true;
        }
    }
}

/// @description: Queues dialog for enemy scan
/// @param {real} enemy: Enemy index for lookup
function dialog_srs(enemy) {
    
    // SRS is broken, can't scan
    if (global.ent.system.srs < 75) {
        queue_dialog(Speaker.Spock, "srs.damaged");
    }
    
    // Pull the player and local enemy data to get the global index
    var player = instance_find(obj_controller_player, 0);
    var local_enemy = player.local_enemies[enemy];
    
    // Get global enemy data using local enemy's index
    var global_enemy_idx = local_enemy.index;
    
    var ge = global.allenemies[global_enemy_idx];
    
    // Debug: Display global enemy data
    show_debug_message("Global enemy[" + string(global_enemy_idx) + "]: energy=" + string(ge.energy) + 
                       ", maxenergy=" + string(ge.maxenergy) + ", lx=" + string(ge.lx) + ", ly=" + string(ge.ly));
    
    // Dialog logic using global enemy data
    if (ge.energy == ge.maxenergy) {
        queue_dialog(Speaker.Sulu, "srs.nodamage");
    } else if (ge.energy < 20) {
        queue_dialog(Speaker.Spock, "srs.majordamage");
    } else if (ge.energy < ge.maxenergy) {
        queue_dialog(Speaker.Spock, "srs.energy", noone, { energy: ge.energy });
    }
    
    if (global.ent.shields < 100) {
        queue_dialog(Speaker.Spock, "srs.warn");
    }
}

/// @description: Dispatches dialog responses based on player request
/// @param {real} action: Action type (HoverState enum)
function dialog_response(action) {
    switch (action) {
        case HoverState.ScottStatus:
            return dialog_report(Reports.Damage);
        case HoverState.WarpSpeed:
            dialog_navigation(1);
            break;
        case HoverState.ImpulseSpeed:
            dialog_navigation(2);
            break;
        case HoverState.Phasers:
            dialog_weapons(1);
            break;
        case HoverState.Torpedoes:
            dialog_weapons(2);
            break;
        case HoverState.LongRangeSensors:
            return dialog_report(Reports.Scan);
        case HoverState.MissionStatus:
            return dialog_report(Reports.Mission);
        case HoverState.DockingProcedures:
            dialog_docking();
            break;
        default:
            show_debug_message("Started a dialog command but got no valid arguments!");
            break;
    }
}

/// @description: Queues ship status dialog and ends game if condition requires.
function dialog_condition() {
	if (global.game.state == State.Win || global.game.state == State.Lose) return;

	switch (global.ent.condition) {
		case Condition.Destroyed:
			queue_dialog(Speaker.Spock, "condition.destroyed1");
			break;

		case Condition.Stranded:
			queue_dialog(Speaker.Spock, "condition.stranded1");
			queue_dialog(Speaker.Scott, "condition.stranded2");
			break;
	}

	// If the condition is one that ends the game, queue winlose after dialog
	if (
		global.ent.condition == Condition.Destroyed ||
		global.ent.condition == Condition.Stranded ||
		global.ent.condition == Condition.NoTime
	) {
		global.queue[array_length(global.queue)] = function() {
			global.busy = true;
			winlose();
		};
	}
}

/// @description: Queues and returns dialog for repair announcements
/// @param {real} n: Repair state (1 = repaired, 2 = progress)
/// @param {string} key: Dialog key for Enterprise system that was repaired
function dialog_repairs(n, key) {
    var pretty_name = variable_struct_get(global.systems, key);
    
    var line_id = (n == 1) ? "time.repaired" : "time.progress";
    var format = { system: pretty_name };
    queue_dialog(Speaker.Scott, line_id, -1, format);
    return { speaker: Speaker.Scott, line: lang_format(line_id, format) };
}

/// @description Handles dialog related to canceling management
/// @param {real} type: Shields (1), Phasers (2)
function dialog_cancel(type) {
	switch (type) {
		case 1: queue_dialog(Speaker.Scott, "shields.notchanged"); break;
        case 2: queue_dialog(Speaker.Chekov, "phasers.notchanged"); break;
		default: break;
    }
	return function() {};
}