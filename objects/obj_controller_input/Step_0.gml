// @obj_controller_input_Step
/// @description: Handles inputs based on mode

// Update input states
check_input();

// Enforce attack delay
if (attack_delay > 0) {
    attack_delay -= 1;
}

// Debug Controls
if (global.debug && !global.busy && global.game.state == State.Playing) {
	debug_handle_keys(); // In scr_debug
}

// Delegate to state-specific input handler
switch (global.inputmode.mode) {
	case InputMode.None:
		break;
	case InputMode.UI:
		handle_ui_input();
		break;
	case InputMode.Bridge:
		handle_bridge_input(global.input.mx, global.input.my);
		break;
	case InputMode.Warp:
		global.busy = true;
		handle_warp_input();
		break;
	case InputMode.Impulse:
		global.busy = true;
		handle_impulse_input();
		break;
	case InputMode.Torpedoes:
		handle_torpedo_input();
		break;
	case InputMode.Manage:
		handle_manage_input();
		break;
	default:
		show_debug_message("InputMode not recognized! Mode: " + string(global.inputmode.mode));
		break;
}

/// @function: check_input
/// @description: Updates global.input based on input sources
function check_input() {
	
	// Clear action
	action = -1;
	
    // Update mouse position
	global.input.programmatic_move = false;
    var old_mx = global.input.mx;
    var old_my = global.input.my;

	// Update mouse position only for mouse input source
    if (global.input.source == InputSource.Mouse) {
        global.input.mx = mouse_x;
        global.input.my = mouse_y;
    }

    // Update input source
    get_input_source(old_mx, old_my);

    // Skip button input if on cooldown
    if (delay > 0) {
        reset_input();
        return;
    }
	
    // Assign input flags
    assign_input();

    // Set delay if any input, except confirm during dialog
    if (input_any() && !(global.input.confirm && obj_controller_dialog.show_text)) {
        delay = 10;
        alarm[0] = 10;
    }
}

/// @function: handle_ui_input
/// @description: Handles UI button input
function handle_ui_input() {
	var buttons = global.active_buttons;
	var max_index = is_array(buttons) ? array_length(buttons) - 1 : -1;

	button_listener(buttons);

	if (global.input.up) {
	    global.selected_index--;
	    if (global.selected_index < 0) global.selected_index = max_index;
    
	    // Skip disabled buttons by checking their menu_id or custom flag
	    while (global.selected_index >= 0 && global.selected_index <= max_index) {
	        var btn = buttons[global.selected_index];
	        if (!btn.can_continue) {
	            global.selected_index--;
	            if (global.selected_index < 0) global.selected_index = max_index;
	        } else break;
	    }
	}

	if (global.input.down) {
	    global.selected_index++;
	    if (global.selected_index > max_index) global.selected_index = 0;
    
	    // Skip disabled buttons by checking their menu_id or custom flag
	    while (global.selected_index >= 0 && global.selected_index <= max_index) {
	        var btn = buttons[global.selected_index];
	        if (!btn.can_continue) {
	            global.selected_index++;
	            if (global.selected_index > max_index) global.selected_index = 0;
	        } else break;
	    }
	}
	
	if (global.input.cancel && global.game.state == State.OptMenu) {
		if instance_exists(obj_controller_player) {
			cleanup_buttons();
			global.options_buttons_created = false;
			global.game.state = State.Playing;
			global.inputmode.mode = InputMode.Bridge;
		}
		else {
			cleanup_buttons();
			global.options_buttons_created = false;
			global.game.state = State.Title;
			global.inputmode.mode = InputMode.UI;
			create_title_buttons();
		}
	}
}

/// @function: handle_bridge_input
/// @description: Handles Bridge input
/// @param {real} mx: Mouse x position
/// @param {real} my: Mouse y position
function handle_bridge_input(mx, my) {
	
    var min_state = all_regions[0].state;
    var max_state = all_regions[array_length(all_regions) - 1].state;
    var sector;
    if (is_array(global.galaxy)
        && global.ent.sx >= 0 && global.ent.sy >= 0
        && array_length(global.galaxy) > global.ent.sx
        && is_array(global.galaxy[global.ent.sx])
        && array_length(global.galaxy[global.ent.sx]) > global.ent.sy) {
        sector = global.galaxy[global.ent.sx][global.ent.sy];
    }
	
    // Help/Report screens
    if (instance_exists(obj_controller_player) && obj_controller_player.display != Reports.Default) {
        global.busy = true;
        if (input_any()) {
            obj_controller_player.display = Reports.Default;
            obj_controller_player.data = [];
            global.busy = false;
            hover_state = HoverState.None;
            // Consume inputs to prevent double triggers
            global.input.confirm = false;
            global.input.cancel = false;
            global.input.up = false;
            global.input.down = false;
            global.input.left = false;
            global.input.right = false;
            global.input.pressed = false;
        }
        return;
    }

    // Bridge mode: Hover + Action selection
    if (!global.busy) {
        // Track previous hover_state to detect changes
        var prev_hover_state = hover_state;
		
        // Keyboard / Gamepad
		if (global.input.left || global.input.right) {
		    var dir = global.input.left ? -1 : 1;
		    var next_state = hover_state;

		    repeat (max_state - min_state + 1) {
		        next_state += dir;
		        if (next_state > max_state) next_state = min_state;
		        else if (next_state < min_state) next_state = max_state;

		        if (hover_state_is_valid(next_state)) {
		            hover_state = next_state;
		            break;
		        }
		    }
		}

        // Update input position for keyboard/gamepad navigation
        if ((global.input.left || global.input.right) &&
            (global.input.source == InputSource.Keyboard || global.input.source == InputSource.Gamepad)) {
			// Find region corresponding to hover_state
			var matched_region = undefined;
			for (var i = 0; i < array_length(all_regions); i++) {
			    var r = all_regions[i];
			    if (r.state == hover_state) {
			        matched_region = r;
			        break;
			    }
			}

			// Only move the mouse if hover_state is valid (i.e., found in all_regions)
			if (!is_undefined(matched_region)) {
			    // Calculate center of the region (in 320x200 room coordinates)
			    var center_x = (matched_region.x1 + matched_region.x2) / 2;
			    var center_y = (matched_region.y1 + matched_region.y2) / 2;

			    // Update global input position
			    global.input.mx = center_x;
			    global.input.my = center_y;

			    // Scale to window coordinates (e.g., 1280x800)
			    var window_x = center_x * (window_get_width() / 320);
			    var window_y = center_y * (window_get_height() / 200);

			    global.input.programmatic_move = true;
			    window_mouse_set(window_x, window_y);
			}
        }

        // Mouse
        if (global.input.source == InputSource.Mouse) {
            var new_hover = HoverState.None;
            for (var i = 0; i < array_length(all_regions); i++) {
                var r = all_regions[i];
                if (mx >= r.x1 && mx <= r.x2 && my >= r.y1 && my <= r.y2) {
                    new_hover = r.state;
                    break;
                }
            }
            hover_state = new_hover;
        }

        // Action Trigger
		if (global.input.confirm) {
			action = hover_state;
			last_state = hover_state;
		    execute_hover_action(action);
		    global.input.confirm = false;
		}
		
		// Check shortcuts
		check_shortcuts();
    }
	
	if (!global.busy && array_length(global.queue) == 0 && !is_undefined(last_state) && global.input.source != InputSource.Mouse) {
	    hover_state = last_state;

	    // Optionally reposition mouse to match restored hover
	    for (var i = 0; i < array_length(all_regions); i++) {
	        var r = all_regions[i];
	        if (r.state == hover_state) {
	            var center_x = (r.x1 + r.x2) / 2;
	            var center_y = (r.y1 + r.y2) / 2;

	            global.input.mx = center_x;
	            global.input.my = center_y;

	            var window_x = center_x * (window_get_width() / 320);
	            var window_y = center_y * (window_get_height() / 200);
	            window_mouse_set(window_x, window_y);
	            break;
	        }
	    }

	   last_state = undefined; // Clear once restored
	}
}

/// @function: execute_hover_action
/// @description: Handles executing a hover action
function execute_hover_action(action) {
    // Stop voice playback
    if (obj_controller_dialog.voice_handle != -1 && audio_is_playing(obj_controller_dialog.voice_handle)) {
        audio_stop_sound(obj_controller_dialog.voice_handle);
        obj_controller_dialog.voice_handle = -1;
    }

    // Clear resolve state
    obj_controller_player.end_turn = false;
    global.queue = [];
    global.index = 0;

    // Dispatch action
    handle_hover_action(action);

    // Mark busy if queue is populated or for Shields
    if (array_length(global.queue) > 0 || action == HoverState.Shields) {
        global.busy = true;
    }
}

/// @function: handle_hover_action
/// @description: Routes actions based on selected hover state
/// @param {real} action: hover_state enum
function handle_hover_action(action) {
	var sector = global.galaxy[global.ent.sx][global.ent.sy];
    switch (action) {
		
        case HoverState.Energy:
            obj_controller_player.display = Reports.Mission;
            obj_controller_player.data = action_on_screen(Reports.Mission);
            break;
			
        case HoverState.DamageStatus:
            obj_controller_player.display = Reports.Damage;
            obj_controller_player.data = action_on_screen(Reports.Damage);
            break;
			
		case HoverState.ScottStatus:
		case HoverState.MissionStatus:
		    global.queue[array_length(global.queue)] = function() {
		        return dialog_response(action);
		    };
		    if (global.ent.system.srs > 10) {
		        var report = (action == HoverState.ScottStatus) ? Reports.Damage : Reports.Mission;
				obj_controller_player._report = report; // GML anonymous functions don't capture local vars and will error, use a temp instance var instead
				global.queue[array_length(global.queue)] = function() {
				    obj_controller_player.display = obj_controller_player._report;
				    obj_controller_player.data = action_on_screen(obj_controller_player._report);
				    obj_controller_player._report = undefined;
				    return;
				};
		    }
		    break;
			
        case HoverState.LongRangeSensors:
            global.queue[array_length(global.queue)] = function() {
                return dialog_response(action);
            };
            if (global.ent.system.lrs > 10 && global.ent.system.srs > 10) {
                global.queue[array_length(global.queue)] = function() {
                    obj_controller_player.display = Reports.Scan;
                    obj_controller_player.data = action_on_screen(Reports.Scan);
                    obj_controller_player.askedforlrs++;
                };
            }
            break;
			
        case HoverState.WarpSpeed:
            global.queue[array_length(global.queue)] = function() {
                return dialog_response(action);
            };
            break;
			
        case HoverState.GalacticMap:
			global.inputmode.cursor_x = global.ent.sx;
			global.inputmode.cursor_y = global.ent.sy;
	        if (global.ent.system.warp < 10) {
	            queue_dialog("Spock", "engines.warp.damaged");
	        } else if (sector.enemynum > 0) {
	            queue_dialog("Sulu", "engines.warn1");
				// Pull up the warp map anyway
				global.queue[array_length(global.queue)] = function() {
					obj_controller_player.display = Reports.Warp; // Stop drawing the current sector and draw the galaxy map
					global.inputmode.mode = InputMode.Warp;
				};
	        } else {
				// Pull up the warp map
				global.queue[array_length(global.queue)] = function() {
					obj_controller_player.display = Reports.Warp; // Stop drawing the current sector and draw the galaxy map
					global.inputmode.mode = InputMode.Warp;
				};
			}
			break;
			
        case HoverState.ImpulseSpeed:
            global.queue[array_length(global.queue)] = function() {
                return dialog_response(action);
            };
            break;
			
        case HoverState.Torpedoes:
            global.queue[array_length(global.queue)] = function() {
                return dialog_response(action);
            };
            break;
			
        case HoverState.DockingProcedures:
            global.queue[array_length(global.queue)] = function() {
                return dialog_response(action);
            };
            break;
			
        case HoverState.Shields:
            action_setstate(action);
            break;
			
        case HoverState.Phasers:
            global.queue[array_length(global.queue)] = function() {
                return dialog_response(action);
            };
            break;
        case HoverState.Options:
			if (global.game.state != State.OptMenu) {
				create_options_buttons();
			}
            break;
        case HoverState.Help:
            obj_controller_player.display = Reports.Help;
            break;
		// Since we can have a range of enemies, deal with it in the default case
		default:
	        if (action >= HoverState.Enemy && action < HoverState.Enemy + array_length(all_regions)) {
	            // Calculate which enemy is selected
	            var enemy_index = action - HoverState.Enemy;

	            obj_controller_input._index = enemy_index;

	            if (obj_controller_input._index >= 0) {
	                array_push(global.queue, function() {
	                    return dialog_srs(obj_controller_input._index);
	                });
	            }
	        }
	        break;
    }
}

/// @function: handle_warp_input
/// @description: Handles input for warp navigation mode
function handle_warp_input() {
	
    // Mouse cursor movement
    if (global.input.source == InputSource.Mouse) {
        var map_offset_x = 40;
        var map_offset_y = 14;
        var size_cell_x = 30;
        var size_cell_y = 22;

        var mx = global.input.mx - map_offset_x;
        var my = global.input.my - map_offset_y;
        var grid_x = floor(mx / size_cell_x);
        var grid_y = floor(my / size_cell_y);

        if (mx >= 0 && mx < size_cell_x * global.inputmode.max_x &&
            my >= 0 && my < size_cell_y * global.inputmode.max_y) {
            if (grid_x >= 0 && grid_x < global.inputmode.max_x &&
                grid_y >= 0 && grid_y < global.inputmode.max_y) {
                global.inputmode.cursor_x = grid_x;
                global.inputmode.cursor_y = grid_y;
            }
        }
    }

    // Keyboard/gamepad directional input
    if (global.input.source != InputSource.Mouse || !mouse_check_button_pressed(mb_any)) {
		if (global.input.left) {
		    global.inputmode.cursor_x--;
		    if (global.inputmode.cursor_x < 0) {
		        global.inputmode.cursor_x = global.inputmode.max_x - 1;
		    }
		}
		if (global.input.right) {
		    global.inputmode.cursor_x++;
		    if (global.inputmode.cursor_x >= global.inputmode.max_x) {
		        global.inputmode.cursor_x = 0;
		    }
		}
		if (global.input.up) {
		    global.inputmode.cursor_y--;
		    if (global.inputmode.cursor_y < 0) {
		        global.inputmode.cursor_y = global.inputmode.max_y - 1;
		    }
		}
		if (global.input.down) {
		    global.inputmode.cursor_y++;
		    if (global.inputmode.cursor_y >= global.inputmode.max_y) {
		        global.inputmode.cursor_y = 0;
		    }
		}
    }

    // Cancel input
    if (global.input.cancel) {
        global.inputmode.type = undefined;
        obj_controller_player.display = Reports.Default;
        global.inputmode.mode = InputMode.Bridge;
        return;
    }

    // Confirm input
    if (global.input.confirm && !obj_controller_dialog.show_text) {
        var tx = global.inputmode.cursor_x;
        var ty = global.inputmode.cursor_y;

        var result = action_warp(tx, ty);
        global.inputmode.type = undefined;

        if (is_bool(result)) {
            if (result) {
                change_sector(tx, ty);
            }
        }
    }
}

/// @function: handle_impulse_input
/// @description: Handles input for impulse movement mode
function handle_impulse_input() {
    var sector = global.galaxy[global.ent.sx][global.ent.sy];
    
    // Process mouse cursor movement if source is Mouse
    if (global.input.source == InputSource.Mouse && !global.ent.animating_impulse) {
        // Map mouse coordinates to grid cell
        var map_offset_x = 121;
        var map_offset_y = 31;
        var size_cell_x = 10;
        var size_cell_y = 9;
        var mx = global.input.mx - map_offset_x;
        var my = global.input.my - map_offset_y;
        var grid_x = floor(mx / size_cell_x);
        var grid_y = floor(my / size_cell_y);
        
        // Check if mouse is within grid bounds
        if (mx >= 0 && mx < size_cell_x * global.inputmode.max_x &&
            my >= 0 && my < size_cell_y * global.inputmode.max_y) {
            // Validate grid coordinates and move cursor if valid
            if (grid_x >= 0 && grid_x < global.inputmode.max_x && 
                grid_y >= 0 && grid_y < global.inputmode.max_y) {
                global.inputmode.cursor_x = grid_x;
                global.inputmode.cursor_y = grid_y;
            }
        }
	}

    // Process keyboard and gamepad
    if (global.input.source != InputSource.Mouse || !mouse_check_button_pressed(mb_any)) {
        if (global.input.left)  global.inputmode.cursor_x = max(0, global.inputmode.cursor_x - 1);
        if (global.input.right) global.inputmode.cursor_x = min(global.inputmode.max_x - 1, global.inputmode.cursor_x + 1);
        if (global.input.up)    global.inputmode.cursor_y = max(0, global.inputmode.cursor_y - 1);
        if (global.input.down)  global.inputmode.cursor_y = min(global.inputmode.max_y - 1, global.inputmode.cursor_y + 1);
    }

    // Confirm or cancel
    if (global.input.confirm && !obj_controller_dialog.show_text) global.inputmode.type = "confirm";
    else if (global.input.cancel) global.inputmode.type = "cancel";

    // Process impulse action if player hasn't started moving
	if (!global.ent.animating_impulse) {
	    var result = action_impulse();

	    if (is_bool(result)) {
	        global.inputmode.type = undefined;

	        if (!result) {
	            // Cancel or invalid move — revert
	            obj_controller_player.display = Reports.Default;
	            global.inputmode.mode = InputMode.Bridge;
	        }
	    }
	}
    
    // Handle impulse animation
    if (global.ent.animating_impulse) {
        var done = global.ent.update_impulse_animation();
        if (done) {
			// If player contacted starbase and landed next to it initiate docking
			if (obj_controller_player.contactedbase && check_baseloc(global.ent.lx, global.ent.ly)) {
				action_stardock();
			}
			else {
	            obj_controller_player.display = Reports.Default;
	            global.inputmode.mode = InputMode.Bridge;
			}
        }
    }
}

/// @function: handle_torpedo_input
/// @description: Handles input for torpedo firing
function handle_torpedo_input() {
	
	// Only one torpedo allowed
	if (instance_exists(obj_torpedo)) {
		global.busy = true;
		return;
	}
	
    var radius = 5; // in grid units

	// Update angle using keyboard
	if (global.input.source != InputSource.Mouse) {
	    if (global.input.right) {
	        obj_controller_player.torp_angle = (obj_controller_player.torp_angle - 10 + 360) mod 360;
	    } else if (global.input.left) {
	        obj_controller_player.torp_angle = (obj_controller_player.torp_angle + 10) mod 360;
	    }
	}

	// Override angle if mouse moved
	if (global.input.source == InputSource.Mouse) {
	    var px = global.ent.lx;
	    var py = global.ent.ly;

	    var screen_px = map_offset_x + px * size_cell_x + size_cell_x * 0.5;
	    var screen_py = map_offset_y + py * size_cell_y + size_cell_y * 0.5;

	    var dx = device_mouse_x_to_gui(0) - screen_px;
	    var dy = device_mouse_y_to_gui(0) - screen_py;

	    obj_controller_player.torp_angle = point_direction(0, 0, dx, dy);
	}

    // Calculate target position relative to player using the angle
    var px = global.ent.lx;
    var py = global.ent.ly;

    var target_x = px + lengthdir_x(radius, obj_controller_player.torp_angle);
    var target_y = py + lengthdir_y(radius, obj_controller_player.torp_angle);

    // Round target position to nearest grid cell
    target_x = round(target_x);
    target_y = round(target_y);

    // Clamp target position to 8x8 sector grid (0 to 7)
    target_x = clamp(target_x, 0, 7);
    target_y = clamp(target_y, 0, 7);

    // Update cursor position for display or targeting UI
    global.inputmode.cursor_x = target_x;
    global.inputmode.cursor_y = target_y;

    // Confirm fire or cancel input
    if (global.input.confirm) {
        global.inputmode.type = "confirm";
    } else if (global.input.cancel) {
        global.inputmode.type = "cancel";
    }

    // On confirm, fire torpedo
    if (global.inputmode.type == "confirm") {
		global.ent.torpedoes -= 1;
        action_torpedo(global.inputmode.cursor_x, global.inputmode.cursor_y);
    }
	
    // On cancel, exit without firing
    else if (global.inputmode.type == "cancel") {
        global.inputmode.type = undefined;
		obj_controller_player.display = Reports.Default;
        global.inputmode.mode = InputMode.Bridge;
    }
}


/// @function: handle_manage_input
/// @description: Handles input for shield/phasers power management
function handle_manage_input() {
    if (obj_controller_dialog.show_text) return;

    var type = global.inputmode.type;
    var max_level = global.ent.energy;
    var increment = 50;

    // Button base positions
    var bx = 264;
    var by = 58;
    var by_up = by - 10;
    var by_down = by + 10;
    var by_confirm = by + 28;

    // Dimensions
    var btn_w = sprite_get_width(spr_btn_arrow);
    var btn_h = sprite_get_height(spr_btn_arrow);
    var confirm_w = sprite_get_width(spr_btn_confirm);
    var confirm_h = sprite_get_height(spr_btn_confirm);

    // Mouse
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var is_mouse = (global.input.source == InputSource.Mouse);
    var confirm = global.input.confirm;

    // Button areas
    var in_up = point_in_rectangle(mx, my, bx - btn_w / 2, by_up - btn_h / 2, bx + btn_w / 2, by_up + btn_h / 2);
    var in_down = point_in_rectangle(mx, my, bx - btn_w / 2, by_down - btn_h / 2, bx + btn_w / 2, by_down + btn_h / 2);
    var in_confirm = point_in_rectangle(mx, my, bx - confirm_w / 2, by_confirm - confirm_h / 2, bx + confirm_w / 2, by_confirm + confirm_h / 2);

	// Input
    if (global.input.up || (confirm && in_up)) {
        global.inputmode.tmp_new = min(global.inputmode.tmp_new + increment, max_level);
    }
    else if (global.input.down || (confirm && in_down)) {
        global.inputmode.tmp_new = max(global.inputmode.tmp_new - increment, 0);
    }
    else if ((confirm && !is_mouse) || (confirm && in_confirm)) {
        action_apply_change(type, global.inputmode.tmp_new);
        reset_inputmode();
        global.input.confirm = false;
    }
    else if (global.input.cancel) {
        global.queue[array_length(global.queue)] = dialog_cancel(type);
        reset_inputmode();
        global.input.cancel = false;
    }
}

/// @function: reset_inputmode
/// @description: Resets input mode to bridge and clears temp values
function reset_inputmode() {
    global.inputmode.mode = InputMode.Bridge;
    global.inputmode.tmp_old = 0;
    global.inputmode.tmp_new = 0;
    global.inputmode.type = undefined;
    global.busy = true;
}

/// @function: reset_input
/// @description: Resets the input struct to default
function reset_input() {
	global.input = {
		source: global.input.source,
		confirm: false,
		cancel: false,
		up: false,
		down: false,
		left: false,
		right: false,
		mx: mouse_x,
		my: mouse_y,
		programmatic_move: global.input.programmatic_move,
	};
}

/// @function: get_input_source
/// @description: Updates global.input.source
/// @param {real} old_mx: Old mouse x
/// @param {real} old_my: Old mouse y
function get_input_source(old_mx, old_my) {
    if (keyboard_check_pressed(vk_anykey)) {
        global.input.source = InputSource.Keyboard;
        global.input.programmatic_move = false; // Reset flag on keyboard input
    } else if (!global.input.programmatic_move && 
               (mouse_check_button_pressed(mb_any) || 
                (mouse_x != old_mx || mouse_y != old_my))) {
        global.input.source = InputSource.Mouse;
        global.input.programmatic_move = false; // Reset flag on actual mouse input
    } else if (gamepad_is_connected(0)) {
        for (var i = 0; i < array_length(gp_buttons); i++) {
            if (gamepad_button_check_pressed(0, gp_buttons[i])) {
                global.input.source = InputSource.Gamepad;
                global.input.programmatic_move = false; // Reset flag on gamepad input
                break;
            }
        }
    }
}

/// @function: assign_input()
/// @description: Assigns input based on source
function assign_input() {
	global.input.confirm = keyboard_check_pressed(vk_space)
		|| mouse_check_button_pressed(mb_left)
		|| gamepad_button_check_pressed(0, gp_face1);

	global.input.cancel = keyboard_check_pressed(vk_escape)
		|| mouse_check_button_pressed(mb_right)
		|| gamepad_button_check_pressed(0, gp_face2);

	global.input.up = keyboard_check(vk_up)
		|| gamepad_button_check(0, gp_padu);

	global.input.down = keyboard_check(vk_down)
		|| gamepad_button_check(0, gp_padd);

	global.input.left = keyboard_check(vk_left)
		|| gamepad_button_check(0, gp_padl);

	global.input.right = keyboard_check(vk_right)
		|| gamepad_button_check(0, gp_padr);
}

function check_shortcuts() {
    if (keyboard_check_pressed(ord("L"))) action = HoverState.LongRangeSensors;
    if (keyboard_check_pressed(ord("T"))) action = HoverState.Torpedoes;
    if (keyboard_check_pressed(ord("S"))) action = HoverState.Shields;
    if (keyboard_check_pressed(ord("P"))) action = HoverState.Phasers;
    if (keyboard_check_pressed(ord("W"))) action = HoverState.WarpSpeed;
    if (keyboard_check_pressed(ord("I"))) action = HoverState.ImpulseSpeed;
    if (keyboard_check_pressed(ord("D"))) action = HoverState.DamageStatus;
    if (keyboard_check_pressed(ord("C"))) action = HoverState.DockingProcedures;
    if (keyboard_check_pressed(ord("R"))) action = HoverState.MissionStatus;
    if (keyboard_check_pressed(ord("M"))) action = HoverState.GalacticMap;
	if (gamepad_button_check(0, gp_select))  action = HoverState.Options;
    if (keyboard_check_pressed(vk_f1))    action = HoverState.Help;
	execute_hover_action(action);
}

/// @function: button_listener
/// @desciption: Feedback if a UI button is pressed
/// @param {array} buttons: Array of UI buttons to listen to
function button_listener(buttons) {
	if (global.input.confirm && is_array(buttons)) {
	    if (global.selected_index >= 0 && global.selected_index < array_length(buttons)) {
	        var btn = buttons[global.selected_index];
			
			// Tell the button it was pressed
	        if (instance_exists(btn)) {
	            btn.pressed = true;
	            global.menu_selected = btn.menu_id;
	            audio_play_sound(snd_ui_click, 0, false);
				global.busy = true;
				alarm[1] = 5;
	        }
	    }
		global.selected_index = 0;
	    global.input.confirm = false;
	}
}

/// @function: check_hotspot_valid
/// @desciption: Check if a selected hotspot is valid
/// @param {any} state: The enum HoverState to check
function hover_state_is_valid(state) {
    for (var i = 0; i < array_length(all_regions); i++) {
        if (all_regions[i].state == state) return true;
    }
    return false;
}