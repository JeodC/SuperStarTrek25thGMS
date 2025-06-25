/// @description: Hotkeys for testing
function debug_handle_keys() {
  if (!global.debug || global.busy || global.inputmode.mode != InputMode.Bridge)
    return;

  // Move sector
  var dir_keys = [[ord("W"), 0, -1], [ord("S"), 0, 1], [ord("A"), -1, 0],
                  [ord("D"), 1, 0]];

  for (var i = 0; i < array_length(dir_keys); i++) {
    if (keyboard_check_pressed(dir_keys[i][0])) {
      global.inputmode.mode = InputMode.Warp;
      change_sector(global.ent.sx + dir_keys[i][1],
                    global.ent.sy + dir_keys[i][2]);
    }
  }

  // Print debug stats
  if (keyboard_check_pressed(vk_divide)) {
    debug_print_stats();
  }
  // Generate ten galaxies
  else if (keyboard_check_pressed(vk_decimal)) {
    for (var i = 0; i < 10; i++) {
      clear_galaxy();
      generate_galaxy();
    }
  }
  // Toggle destroyed
  else if (keyboard_check_pressed(vk_numpad0)) {
    global.busy = true;
    global.ent.condition = Condition.Destroyed;
    dialog_condition();
  }
  // Toggle stranded
  else if (keyboard_check_pressed(vk_numpad1)) {
    global.busy = true;
    global.ent.condition = Condition.Stranded;
    dialog_condition();
  }
  // Toggle win
  else if (keyboard_check_pressed(vk_numpad2)) {
    global.game.totalenemies = 0;
    global.busy = true;
    array_resize(global.queue, global.index);
    array_push(
        global.queue,
        function() { return immediate_dialog(Speaker.Uhura, "condition.win1"); });
    array_push(
        global.queue, function() {
          return immediate_dialog(Speaker.Kirk, "condition.win2",
                                  vo_kirk_onscreen);
        });
    array_push(
        global.queue, function() {
          global.ent.condition = Condition.Win;
          global.busy = true;
          winlose();
          return undefined;
        });
  }
  // Damage random systems
  else if (keyboard_check_pressed(vk_numpad3)) {
    damage_random_systems(25);
  }
  // Advance time by n days
  if (keyboard_check_pressed(vk_numpad4)) {
    advancetime(1);
  }
  // Repair systems
  else if (keyboard_check_pressed(vk_numpad9)) {
    init_enterprise();
    update_ship_condition();
  }
}

/// @description: Draws some debug text to the screen
function debug_draw() {
  if (global.debug) {
    var xx = 240;
    var yy = 160;
    draw_set_color(global.t_colors.yellow);
    draw_text(xx, yy, "InputMode: " + string(global.inputmode.mode));
    draw_text(xx, yy + 10, "Busy: " + string(global.busy));
    draw_text(xx, yy + 20,
              "HoverState: " + string(obj_controller_input.hover_state));
    draw_text(xx, yy + 30, "State: " + string(global.game.state));
  }
}

/// @description: Shows current sector as a debug message for logging
function debug_sector() {
  var sx = global.ent.sx;
  var sy = global.ent.sy;
  var sector = global.galaxy[sx][sy];
}

/// @description: Shows generated galaxy as a debug message for logging
function debug_galaxy() {
  // Galaxy contents
  show_debug_message(
      "Galaxy generated -- Enemies: " + string(global.game.totalenemies) +
      " Bases: " + string(global.game.totalbases) +
      " Difficulty: " + string(global.difficulty));
  debug_sector();
  for (var sx = 0; sx < 8; sx++) {
    var row = "";
    for (var sy = 0; sy < 8; sy++) {
      var s = global.galaxy[sx][sy];
      row += "[" + string(sx) + "," + string(sy) + "]: " + string(s.enemynum) +
             string(s.basenum) + string(s.starnum);
      if (sy < 7)
        row += " ";
    }
    show_debug_message(row);
  }
}

/// @description: Prints the values of various game stats to debug log
function debug_print_stats() {
  var daysleft = (global.game.t0 + (global.game.maxdays - global.game.date));
  show_debug_message("Application difficulty: " + string(global.difficulty) +
                     ", Game difficulty: " + string(global.game.difficulty));
  show_debug_message("Game date: " + string(global.game.date),
                     +", Time left: " + string(daysleft));
  show_debug_message("Enemy power: " + string(global.game.enemypower));
  show_debug_message("All Enemies Array: " + string(global.allenemies));
  show_debug_message("Current sector: " + string(global.ent.sx) + "," +
                     string(global.ent.sy));
  show_debug_message("Local Enemies: " +
                     string(obj_controller_player.local_enemies));
  show_debug_message("Local Objects: " +
                     string(obj_controller_player.local_objects));
}