/// @obj_controller_input_Step
/// @description: Handles inputs based on mode

if (mouse_x != last_mx || mouse_y != last_my) {
  global.input.mx = mouse_x;
  global.input.my = mouse_y;
}

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
    handle_bridge_input();
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
    show_debug_message("InputMode not recognized! Mode: " +
                      string(global.inputmode.mode));
    break;
}

/// @description: Updates global.input based on input sources
function check_input() {
  action = -1;
  var old_source = global.input.source;

  // Update input source
  get_input_source();

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

/// @description: Updates global.input.source
function get_input_source() {
  if (keyboard_check_pressed(vk_anykey)) {
    global.input.source = InputSource.Keyboard;
  } else if (mouse_check_button_pressed(mb_any) ||
             (mouse_x != last_mx || mouse_y != last_my)) {
    global.input.source = InputSource.Mouse;
  } else if (gamepad_is_connected(0)) {
    for (var i = 0; i < array_length(gp_buttons); i++) {
      if (gamepad_button_check_pressed(0, gp_buttons[i])) {
        global.input.source = InputSource.Gamepad;
        break;
      }
    }
  }
}

/// @description: Handles UI button input
function handle_ui_input() {
  var buttons = global.active_buttons;
  var max_index = is_array(buttons) ? array_length(buttons) - 1 : -1;

  button_listener(buttons);

  if (global.input.up) {
    global.selected_index--;
    if (global.selected_index < 0)
      global.selected_index = max_index;

    // Skip disabled buttons by checking their menu_id or custom flag
    while (global.selected_index >= 0 && global.selected_index <= max_index) {
      var btn = buttons[global.selected_index];
      if (!btn.can_continue) {
        global.selected_index--;
        if (global.selected_index < 0)
          global.selected_index = max_index;
      } else
        break;
    }
  }

  if (global.input.down) {
    global.selected_index++;
    if (global.selected_index > max_index)
      global.selected_index = 0;

    // Skip disabled buttons by checking their menu_id or custom flag
    while (global.selected_index >= 0 && global.selected_index <= max_index) {
      var btn = buttons[global.selected_index];
      if (!btn.can_continue) {
        global.selected_index++;
        if (global.selected_index > max_index)
          global.selected_index = 0;
      } else
        break;
    }
  }

  if (global.input.cancel && global.game.state == State.OptMenu) {
    if instance_exists (obj_controller_player) {
      cleanup_buttons();
      global.options_buttons_created = false;
      global.game.state = State.Playing;
      global.inputmode.mode = InputMode.Bridge;
    } else {
      cleanup_buttons();
      global.options_buttons_created = false;
      global.game.state = State.Title;
      global.inputmode.mode = InputMode.UI;
      create_title_buttons();
    }
  }
}

/// @desciption: Feedback if a UI button is pressed
/// @param {array} buttons: Array of UI buttons to listen to
function button_listener(buttons) {
  if (global.input.confirm && is_array(buttons)) {
    if (global.selected_index >= 0 &&
        global.selected_index < array_length(buttons)) {
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
    global.input.confirm = false;
  }
}

/// @description: Handles Bridge input
function handle_bridge_input() {
  var min_state = all_regions[0].state;
  var max_state = all_regions[array_length(all_regions) - 1].state;
  var sector;
  if (is_array(global.galaxy) && global.ent.sx >= 0 && global.ent.sy >= 0 &&
      array_length(global.galaxy) > global.ent.sx &&
      is_array(global.galaxy[global.ent.sx]) &&
      array_length(global.galaxy[global.ent.sx]) > global.ent.sy) {
    sector = global.galaxy[global.ent.sx][global.ent.sy];
  }

  // Help/Report screens
  if (instance_exists(obj_controller_player) &&
      obj_controller_player.display != Reports.Default) {
    global.busy = true;
    if (input_any()) {
      obj_controller_player.display = Reports.Default;
      obj_controller_player.data = [];
      global.busy = false;
      hover_state = HoverState.None;
      global.input.confirm = false;
      global.input.cancel = false;
      global.input.up = false;
      global.input.down = false;
      global.input.left = false;
      global.input.right = false;
      global.input.pressed = false;
      // Reset virtual cursor to default position
      global.input.mx = 0;
      global.input.my = 0;
    }
    return;
  }

  // Bridge mode: Hover + Action selection
  if (!global.busy) {
    var prev_hover_state = hover_state;

    // Keyboard/Gamepad navigation
    if (global.input.left || global.input.right) {
      var dir = global.input.left ? -1 : 1;
      var next_state = hover_state;
      if (global.input.source != InputSource.Mouse) {
        global.input.source = (global.input.source == InputSource.Keyboard)
                                  ? InputSource.Keyboard
                                  : InputSource.Gamepad;
      }
      repeat(max_state - min_state + 1) {
        next_state += dir;
        if (next_state > max_state)
          next_state = min_state;
        else if (next_state < min_state)
          next_state = max_state;
        if (hover_state_is_valid(next_state)) {
          hover_state = next_state;
          // Update virtual cursor position
          update_virtual_cursor(hover_state);
          break;
        }
      }
    }

    // Mouse input: Select hover_state based on click
    if (global.input.source == InputSource.Mouse) {
      var mx = device_mouse_x_to_gui(0);
      var my = device_mouse_y_to_gui(0);
      var new_hover = HoverState.None;
      for (var i = 0; i < array_length(all_regions); i++) {
        var r = all_regions[i];
        if (mx >= r.x1 && mx <= r.x2 && my >= r.y1 && my <= r.y2) {
          new_hover = r.state;
          break;
        }
      }
      if (new_hover != HoverState.None && new_hover != hover_state) {
        hover_state = new_hover;
        update_virtual_cursor(hover_state);
      }
    }

    // Confirm action
    if (global.input.confirm) {
      action = hover_state;
      last_state = hover_state;
      execute_hover_action(action);
      global.input.confirm = false;
    }

    // Check custom input shortcuts
    check_shortcuts();
  }

  // Restore hover after action queue clears
  if (!global.busy && array_length(global.queue) == 0 &&
      !is_undefined(last_state)) {
    if (hover_state_is_valid(last_state)) {
      hover_state = last_state;
      update_virtual_cursor(hover_state);
    }
    last_state = undefined;
  }
}

/// @description: Updates virtual cursor position based on hover_state
function update_virtual_cursor(state) {
  var matched_region = undefined;
  for (var i = 0; i < array_length(all_regions); i++) {
    var r = all_regions[i];
    if (r.state == state) {
      matched_region = r;
      break;
    }
  }
  if (!is_undefined(matched_region)) {
    global.input.mx = (matched_region.x1 + matched_region.x2) / 2;
    global.input.my = (matched_region.y1 + matched_region.y2) / 2;
  } else {
    global.input.mx = 0;
    global.input.my = 0;
    hover_state = HoverState.None;
  }
}

/// @description: Resets input struct to default
function reset_input() {
  global.input = {
    source : global.input.source,
    confirm : false,
    cancel : false,
    up : false,
    down : false,
    left : false,
    right : false,
    mx : global.input.mx, // Preserve virtual cursor
    my : global.input.my,
    programmatic_move : false
  };
}

/// @description: Check if a selected hotspot is valid
function hover_state_is_valid(state) {
  for (var i = 0; i < array_length(all_regions); i++) {
    if (all_regions[i].state == state)
      return true;
  }
  return false;
}

/// @description: Handles executing a hover action
function execute_hover_action(action) {
  // Stop voice playback
  if (obj_controller_dialog.voice_handle != -1 &&
      audio_is_playing(obj_controller_dialog.voice_handle)) {
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
      var report =
          (action == HoverState.ScottStatus) ? Reports.Damage : Reports.Mission;
      obj_controller_player._report = report; // GML anonymous functions don't capture local vars and will error, use a temp instance var instead
      global.queue[array_length(global.queue)] = function() {
        obj_controller_player.display = obj_controller_player._report;
        obj_controller_player.data =
            action_on_screen(obj_controller_player._report);
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
      queue_dialog(Speaker.Spock, "engines.warp.damaged");
    } else if (sector.enemynum > 0) {
      queue_dialog(Speaker.Sulu, "engines.warn1");
      // Pull up the warp map anyway
      global.queue[array_length(global.queue)] = function() {
        obj_controller_player.display =
            Reports.Warp; // Stop drawing the current sector and draw
                          // the galaxy map
        global.inputmode.mode = InputMode.Warp;
      };
    } else {
      // Pull up the warp map
      global.queue[array_length(global.queue)] = function() {
        obj_controller_player.display =
            Reports.Warp; // Stop drawing the current sector and draw
                          // the galaxy map
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
    if (!instance_exists(obj_fade)) {
      instance_create_layer(0, 0, "Overlay", obj_fade);
    }
    create_options_buttons();
    break;
  case HoverState.Help:
    obj_controller_player.display = Reports.Help;
    break;
  // Since we can have a range of enemies, deal with it in the default case
  default:
    if (action >= HoverState.Enemy &&
        action < HoverState.Enemy + array_length(all_regions)) {
      // Calculate which enemy is selected
      var enemy_index = action - HoverState.Enemy;

      obj_controller_input._index = enemy_index;

      if (obj_controller_input._index >= 0) {
        array_push(
            global.queue,
            function() { return dialog_srs(obj_controller_input._index); });
      }
    }
    break;
  }
}

/// @description: Handles input for warp navigation mode
function handle_warp_input() {
  var map_offset_x = 40;
  var map_offset_y = 14;
  var size_cell_x = 30;
  var size_cell_y = 22;

  // Mouse input
  if (global.input.source == InputSource.Mouse) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    global.input.mx = mx;
    global.input.my = my;
    if (mx >= 0 && mx < display_get_gui_width() && my >= 0 &&
        my < display_get_gui_height()) {
      mx -= map_offset_x;
      my -= map_offset_y;
      var grid_x = floor(mx / size_cell_x);
      var grid_y = floor(my / size_cell_y);
      if (mx >= 0 && mx < size_cell_x * global.inputmode.max_x && my >= 0 &&
          my < size_cell_y * global.inputmode.max_y) {
        if (grid_x >= 0 && grid_x < global.inputmode.max_x && grid_y >= 0 &&
            grid_y < global.inputmode.max_y) {
          global.inputmode.cursor_x = grid_x;
          global.inputmode.cursor_y = grid_y;
          global.input.mx = map_offset_x + (grid_x + 0.5) * size_cell_x;
          global.input.my = map_offset_y + (grid_y + 0.5) * size_cell_y;
        }
      }
    }
  }

  // Keyboard/gamepad directional input
  if (global.input.left) {
    global.inputmode.cursor_x--;
    if (global.inputmode.cursor_x < 0)
      global.inputmode.cursor_x = global.inputmode.max_x - 1;
    update_warp_cursor();
  }
  if (global.input.right) {
    global.inputmode.cursor_x++;
    if (global.inputmode.cursor_x >= global.inputmode.max_x)
      global.inputmode.cursor_x = 0;
    update_warp_cursor();
  }
  if (global.input.up) {
    global.inputmode.cursor_y--;
    if (global.inputmode.cursor_y < 0)
      global.inputmode.cursor_y = global.inputmode.max_y - 1;
    update_warp_cursor();
  }
  if (global.input.down) {
    global.inputmode.cursor_y++;
    if (global.inputmode.cursor_y >= global.inputmode.max_y)
      global.inputmode.cursor_y = 0;
    update_warp_cursor();
  }

  // Cancel input
  if (global.input.cancel) {
    global.inputmode.type = undefined;
    obj_controller_player.display = Reports.Default;
    global.inputmode.mode = InputMode.Bridge;
    global.input.mx = 0;
    global.input.my = 0;
    return;
  }

  // Confirm input
  if (global.input.confirm && !obj_controller_dialog.show_text) {
    var tx = global.inputmode.cursor_x;
    var ty = global.inputmode.cursor_y;
    var result = action_warp(tx, ty);
    global.inputmode.type = undefined;
    if (is_bool(result) && result) {
      change_sector(tx, ty);
    }
  }
}

/// @description: Updates the cursor on the warp map
function update_warp_cursor() {
  var map_offset_x = 40;
  var map_offset_y = 14;
  var size_cell_x = 30;
  var size_cell_y = 22;
  global.input.mx =
      map_offset_x + (global.inputmode.cursor_x + 0.5) * size_cell_x;
  global.input.my =
      map_offset_y + (global.inputmode.cursor_y + 0.5) * size_cell_y;
}

/// @description: Handle impulse input
function handle_impulse_input() {
  var sector = global.galaxy[global.ent.sx][global.ent.sy];
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  // Mouse input
  if (global.input.source == InputSource.Mouse &&
      !global.ent.animating_impulse) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    global.input.mx = mx;
    global.input.my = my;
    if (mx >= 0 && mx < display_get_gui_width() && my >= 0 &&
        my < display_get_gui_height()) {
      mx -= map_offset_x;
      my -= map_offset_y;
      var grid_x = floor(mx / size_cell_x);
      var grid_y = floor(my / size_cell_y);
      if (mx >= 0 && mx < size_cell_x * global.inputmode.max_x && my >= 0 &&
          my < size_cell_y * global.inputmode.max_y) {
        if (grid_x >= 0 && grid_x < global.inputmode.max_x && grid_y >= 0 &&
            grid_y < global.inputmode.max_y) {
          global.inputmode.cursor_x = grid_x;
          global.inputmode.cursor_y = grid_y;
          global.input.mx = map_offset_x + (grid_x + 0.5) * size_cell_x;
          global.input.my = map_offset_y + (grid_y + 0.5) * size_cell_y;
        }
      }
    }
  }

  // Keyboard/gamepad
  if (global.input.left) {
    global.inputmode.cursor_x = max(0, global.inputmode.cursor_x - 1);
    update_impulse_cursor();
  }
  if (global.input.right) {
    global.inputmode.cursor_x =
        min(global.inputmode.max_x - 1, global.inputmode.cursor_x + 1);
    update_impulse_cursor();
  }
  if (global.input.up) {
    global.inputmode.cursor_y = max(0, global.inputmode.cursor_y - 1);
    update_impulse_cursor();
  }
  if (global.input.down) {
    global.inputmode.cursor_y =
        min(global.inputmode.max_y - 1, global.inputmode.cursor_y + 1);
    update_impulse_cursor();
  }

  // Confirm or cancel
  if (global.input.confirm && !obj_controller_dialog.show_text)
    global.inputmode.type = "confirm";
  else if (global.input.cancel)
    global.inputmode.type = "cancel";

  // Process impulse action
  if (!global.ent.animating_impulse) {
    var result = action_impulse();
    if (is_bool(result)) {
      global.inputmode.type = undefined;
      if (!result) {
        obj_controller_player.display = Reports.Default;
        global.inputmode.mode = InputMode.Bridge;
        global.input.mx = 0;
        global.input.my = 0;
      }
    }
  }

  // Handle impulse animation
  if (global.ent.animating_impulse) {
    var done = global.ent.update_impulse_animation();
    if (done) {
      if (obj_controller_player.contactedbase &&
          check_baseloc(global.ent.lx, global.ent.ly)) {
        action_stardock();
      } else {
        obj_controller_player.display = Reports.Default;
        global.inputmode.mode = InputMode.Bridge;
        global.input.mx = 0;
        global.input.my = 0;
      }
    }
  }
}

/// @description: Updates the cursor on the impulse map
function update_impulse_cursor() {
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;
  global.input.mx =
      map_offset_x + (global.inputmode.cursor_x + 0.5) * size_cell_x;
  global.input.my =
      map_offset_y + (global.inputmode.cursor_y + 0.5) * size_cell_y;
}

/// @description: Handle torpedo input
function handle_torpedo_input() {
  if (instance_exists(obj_torpedo)) {
    global.busy = true;
    return;
  }
  var radius = 5;
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  // Mouse input
  if (global.input.source == InputSource.Mouse) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    if (mx >= 0 && mx < display_get_gui_width() && my >= 0 &&
        my < display_get_gui_height()) {
      // Calculate angle from player position to mouse
      var px = global.ent.lx;
      var py = global.ent.ly;
      var screen_px = map_offset_x + (px + 0.5) * size_cell_x;
      var screen_py = map_offset_y + (py + 0.5) * size_cell_y;
      obj_controller_player.torp_angle =
          point_direction(screen_px, screen_py, mx, my);
      global.input.mx = mx;
      global.input.my = my;
    }
  }

  // Keyboard/Gamepad angle adjustment
  if (global.input.source != InputSource.Mouse) {
    if (global.input.right) {
      obj_controller_player.torp_angle =
          (obj_controller_player.torp_angle - 10 + 360) mod 360;
    } else if (global.input.left) {
      obj_controller_player.torp_angle =
          (obj_controller_player.torp_angle + 10) mod 360;
    }
  }

  // Calculate target position
  var px = global.ent.lx;
  var py = global.ent.ly;
  var target_x = px + lengthdir_x(radius, obj_controller_player.torp_angle);
  var target_y = py + lengthdir_y(radius, obj_controller_player.torp_angle);
  target_x = round(target_x);
  target_y = round(target_y);
  target_x = clamp(target_x, 0, 7);
  target_y = clamp(target_y, 0, 7);

  // Update virtual cursor (snap to grid for consistency)
  global.inputmode.cursor_x = target_x;
  global.inputmode.cursor_y = target_y;
  if (global.input.source != InputSource.Mouse) {
    global.input.mx = map_offset_x + (target_x + 0.5) * size_cell_x;
    global.input.my = map_offset_y + (target_y + 0.5) * size_cell_y;
  }

  // Confirm or cancel
  if (global.input.confirm) {
    global.inputmode.type = "confirm";
  } else if (global.input.cancel) {
    global.inputmode.type = "cancel";
  }

  // Fire torpedo
  if (global.inputmode.type == "confirm") {
    global.ent.torpedoes -= 1;
    action_torpedo(global.inputmode.cursor_x, global.inputmode.cursor_y);
  } else if (global.inputmode.type == "cancel") {
    global.inputmode.type = undefined;
    obj_controller_player.display = Reports.Default;
    global.inputmode.mode = InputMode.Bridge;
    global.input.mx = 0;
    global.input.my = 0;
  }
}

/// @description: Handle manage input
function handle_manage_input() {
  if (obj_controller_dialog.show_text)
    return;
  var type = global.inputmode.type;
  var max_level = global.ent.energy;
  var increment = 50;
  var bx = 264;
  var by = 58;
  var by_up = by - 10;
  var by_down = by + 10;
  var by_confirm = by + 28;
  var btn_w = sprite_get_width(spr_btn_arrow);
  var btn_h = sprite_get_height(spr_btn_arrow);
  var confirm_w = sprite_get_width(spr_btn_confirm);
  var confirm_h = sprite_get_height(spr_btn_confirm);

  // Mouse input
  if (global.input.source == InputSource.Mouse) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    global.input.mx = mx;
    global.input.my = my;
    if (mx >= 0 && mx < display_get_gui_width() && my >= 0 &&
        my < display_get_gui_height()) {
      var in_up = point_in_rectangle(mx, my, bx - btn_w / 2, by_up - btn_h / 2,
                                     bx + btn_w / 2, by_up + btn_h / 2);
      var in_down =
          point_in_rectangle(mx, my, bx - btn_w / 2, by_down - btn_h / 2,
                             bx + btn_w / 2, by_down + btn_h / 2);
      var in_confirm = point_in_rectangle(
          mx, my, bx - confirm_w / 2, by_confirm - confirm_h / 2,
          bx + confirm_w / 2, by_confirm + confirm_h / 2);

      // Optional: Snap cursor to button center on hover for visual
      // feedback
      if (in_up) {
        global.input.mx = bx;
        global.input.my = by_up;
      } else if (in_down) {
        global.input.mx = bx;
        global.input.my = by_down;
      } else if (in_confirm) {
        global.input.mx = bx;
        global.input.my = by_confirm;
      }

      // Handle click actions
      if (global.input.confirm) {
        if (in_up) {
          global.inputmode.tmp_new =
              min(global.inputmode.tmp_new + increment, max_level);
          global.input.mx = bx;
          global.input.my = by_up;
        } else if (in_down) {
          global.inputmode.tmp_new =
              max(global.inputmode.tmp_new - increment, 0);
          global.input.mx = bx;
          global.input.my = by_down;
        } else if (in_confirm) {
          action_apply_change(type, global.inputmode.tmp_new);
          reset_inputmode();
          global.input.confirm = false;
          global.input.mx = 0;
          global.input.my = 0;
        }
      }
    }
  }

  // Keyboard/Gamepad input
  if (global.input.up) {
    global.inputmode.tmp_new =
        min(global.inputmode.tmp_new + increment, max_level);
    global.input.mx = bx;
    global.input.my = by_up;
  } else if (global.input.down) {
    global.inputmode.tmp_new = max(global.inputmode.tmp_new - increment, 0);
    global.input.mx = bx;
    global.input.my = by_down;
  } else if (global.input.confirm) {
    action_apply_change(type, global.inputmode.tmp_new);
    reset_inputmode();
    global.input.confirm = false;
  } else if (global.input.cancel) {
    global.queue[array_length(global.queue)] = dialog_cancel(type);
    reset_inputmode();
    global.input.cancel = false;
  }
}

/// @description: Resets input mode to bridge and clears temp values
function reset_inputmode() {
  global.inputmode.mode = InputMode.Bridge;
  global.inputmode.tmp_old = 0;
  global.inputmode.tmp_new = 0;
  global.inputmode.type = undefined;
  global.busy = true;
}

/// @description: Assigns input based on source
function assign_input() {
  global.input.confirm = keyboard_check_pressed(vk_space) ||
                         mouse_check_button_pressed(mb_left) ||
                         gamepad_button_check_pressed(0, gp_face1);

  global.input.cancel = keyboard_check_pressed(vk_escape) ||
                        mouse_check_button_pressed(mb_right) ||
                        gamepad_button_check_pressed(0, gp_face2);

  global.input.up = keyboard_check(vk_up) || gamepad_button_check(0, gp_padu);

  global.input.down =
      keyboard_check(vk_down) || gamepad_button_check(0, gp_padd);

  global.input.left =
      keyboard_check(vk_left) || gamepad_button_check(0, gp_padl);

  global.input.right =
      keyboard_check(vk_right) || gamepad_button_check(0, gp_padr);
}

/// @description: Assigns keyboard shortcuts to actions
function check_shortcuts() {
  if (keyboard_check_pressed(ord("L")))
    action = HoverState.LongRangeSensors;
  if (keyboard_check_pressed(ord("T")))
    action = HoverState.Torpedoes;
  if (keyboard_check_pressed(ord("S")))
    action = HoverState.Shields;
  if (keyboard_check_pressed(ord("P")))
    action = HoverState.Phasers;
  if (keyboard_check_pressed(ord("W")))
    action = HoverState.WarpSpeed;
  if (keyboard_check_pressed(ord("I")))
    action = HoverState.ImpulseSpeed;
  if (keyboard_check_pressed(ord("D")))
    action = HoverState.DamageStatus;
  if (keyboard_check_pressed(ord("C")))
    action = HoverState.DockingProcedures;
  if (keyboard_check_pressed(ord("R")))
    action = HoverState.MissionStatus;
  if (keyboard_check_pressed(ord("M")))
    action = HoverState.GalacticMap;
  if (gamepad_button_check(0, gp_select))
    action = HoverState.Options;
  if (keyboard_check_pressed(vk_f1))
    action = HoverState.Help;
  execute_hover_action(action);
}