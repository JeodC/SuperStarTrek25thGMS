/// @description: Resets the Enterprise to its initial state
function init_enterprise() {
  audio_play_sound(snd_starbase_refill, 0, false);
  if (global.ent.generaldamage > 1) {
    queue_dialog(Speaker.Kirk, "docked.fixed1");
    queue_dialog(Speaker.Scott, "docked.fixed2");
    queue_dialog(Speaker.Kirk, "docked.fixed3");
    queue_dialog(Speaker.Scott, "docked.fixed4");
  }
  // Reset ship properties
  global.ent.energy = global.game.maxenergy;
  // global.ent.torpedoes = global.game.maxtorpedoes; -- Makes game too easy
  global.ent.shields = 0;
  global.ent.isdocked = false;

  // Reinitialize systems
  global.ent.generaldamage = 0;
  global.ent.system = {
    warp : 100,
    srs : 100,
    lrs : 100,
    phasers : 100,
    torpedoes : 100,
    navigation : 100,
    shields : 100
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
  show_debug_message(
      "[DAMAGE PHASE] Threshold: " + string_format(thresh, 0, 2) +
      " | Difficulty: " + string(global.game.difficulty));

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

      show_debug_message("- System '" + key + "' took " +
                         string(damage - overkill) +
                         " damage (modifier: " + string(modifier) + ")");
    }
  }

  // Update general damage status
  global.ent.generaldamage = 0;
  for (var i = 0; i < array_length(damage_keys); i++) {
    var val = global.ent.system[$ damage_keys[i]];
    if (val < 90 && global.ent.generaldamage < 1)
      global.ent.generaldamage = 1;
    if (val < 66 && global.ent.generaldamage < 2)
      global.ent.generaldamage = 2;
    if (val < 33 && global.ent.generaldamage < 3)
      global.ent.generaldamage = 3;
  }
  show_debug_message("General damage level: " +
                     string(global.ent.generaldamage));
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

    show_debug_message(
        "- Repaired system '" + key + "' by " + string(after - before) +
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
    if (val < 90 && global.ent.generaldamage < 1)
      global.ent.generaldamage = 1;
    if (val < 66 && global.ent.generaldamage < 2)
      global.ent.generaldamage = 2;
    if (val < 33 && global.ent.generaldamage < 3)
      global.ent.generaldamage = 3;
  }

  show_debug_message("- General damage level: " +
                     string(global.ent.generaldamage));
}

/// @description: Advances game date by a given number of whole days
/// @param {real} days: Days to advance (must be an integer)
function advancetime(days) {
  // Ensure days is an integer
  if (!is_real(days) || days != floor(days)) {
    show_debug_message("advancetime() called with non-integer value: " +
                       string(days));
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
  var lowPower = (global.ent.energy + global.ent.shields + global.ent.phasers) <
                 global.game.maxenergy / 10;

  // Track old condition to see if it changed
  var old_condition = global.ent.condition;
  var new_condition;

  if (global.ent.shields < 0) {
    new_condition = Condition.Destroyed;
    show_debug_message("Player was destroyed!");
  } else if (global.ent.shields < 2 && global.ent.energy < 2) {
    new_condition = Condition.Stranded;
    show_debug_message("Player was stranded (Out of energy)!");
  } else if (global.ent.system.warp < 10 && sector.basenum < 1) {
    new_condition = Condition.Stranded;
    show_debug_message("Player was stranded (damaged warp core)!");
  } else if (global.ent.system.warp < 10 && global.ent.system.navigation < 10) {
    new_condition = Condition.Stranded;
    show_debug_message("Player was stranded (damaged navigation)!");
  } else if (daysleft < 1) {
    new_condition = Condition.NoTime;
    show_debug_message("Player ran out of time!");
  } else if (lowPower || global.ent.generaldamage > 1) {
    new_condition =
        (global.ent.generaldamage > 2) ? Condition.Red : Condition.Yellow;
  } else {
    new_condition = Condition.Green;
  }

  global.ent.condition = new_condition;

  // If condition changed and it's critical, queue dialog
  var should_dialog = (new_condition == Condition.Stranded ||
                       new_condition == Condition.Destroyed ||
                       new_condition == Condition.NoTime);
  if (should_dialog && old_condition != new_condition && !global.busy) {
    global.busy = true;
    array_resize(global.queue, global.index);
    array_push(
        global.queue, function() {
          dialog_condition();
          return undefined;
        });
  }
}

/// @description: Returns stars, bases, and enemies in the specified sector,
/// updating player arrays if sector matches player's.
/// @param {real} sx: Sector x coordinate (defaults to player's current sector)
/// @param {real} sy: Sector y coordinate (defaults to player's current sector)
function get_sector_data(sx = global.ent.sx, sy = global.ent.sy) {
  var s = {
    enemynum: 0,
    basenum: 0,
    starnum: 0,
    enemies: [],
    bases: [],
    stars: []
  };

  // Get sector data struct
  var sector = global.galaxy[sx][sy];
  s.enemynum = sector.enemynum;
  s.basenum = sector.basenum;
  s.starnum = sector.starnum;

  // Populate stars from sector.star_positions
  for (var i = 0; i < array_length(sector.star_positions); i++) {
    var pos = sector.star_positions[i];
    array_push(s.stars, { lx: pos[0], ly: pos[1], index: i });
  }

  // Create maps for caching enemies and bases in this sector
  var enemy_map = ds_map_create();
  var base_map = ds_map_create();

  // Collect alive enemies in sector
  for (var i = 0; i < array_length(global.allenemies); i++) {
    var e = global.allenemies[i];
    if (!is_struct(e) || e.sx != sx || e.sy != sy || e.energy <= 0) continue;

    ds_map_add(enemy_map, string(i), {
      lx: e.lx,
      ly: e.ly,
      energy: e.energy,
      maxenergy: e.maxenergy,
      index: i
    });
  }

  // Collect bases in sector
  for (var i = 0; i < array_length(global.allbases); i++) {
    var b = global.allbases[i];
    if (!is_struct(b) || b.sx != sx || b.sy != sy) continue;

    ds_map_add(base_map, string(i), {
      lx: b.lx,
      ly: b.ly,
      energy: variable_struct_exists(b, "energy") ? b.energy : -1,
      index: i
    });
  }

  // Populate enemies array from enemy_map
  var enemy_keys = ds_map_keys_to_array(enemy_map);
  for (var i = 0; i < array_length(enemy_keys); i++) {
    array_push(s.enemies, enemy_map[? enemy_keys[i]]);
  }

  // Populate bases array from base_map
  var base_keys = ds_map_keys_to_array(base_map);
  for (var i = 0; i < array_length(base_keys); i++) {
    array_push(s.bases, base_map[? base_keys[i]]);
  }

  // Update counts based on filtered arrays
  s.enemynum = array_length(s.enemies);
  s.basenum = array_length(s.bases);
  s.starnum = array_length(s.stars);

  // Update player local arrays if this sector is the player's current sector
  if (sx == global.ent.sx && sy == global.ent.sy) {
    var player = instance_find(obj_controller_player, 0);
    if (player) {
      player.local_objects = [];
      player.local_enemies = [];
      player.local_stars = [];
      player.local_bases = [];

      var object_map = ds_map_create(); // to avoid duplicates

      // Add stars to player arrays
      for (var i = 0; i < array_length(s.stars); i++) {
        var star = s.stars[i];
        var key = "star:" + string(star.index);
        if (!ds_map_exists(object_map, key)) {
          var star_obj = { type: "star", lx: star.lx, ly: star.ly, index: star.index };
          array_push(player.local_objects, star_obj);
          array_push(player.local_stars, star_obj);
          ds_map_add(object_map, key, true);
        }
      }

      // Add bases to player arrays
      for (var i = 0; i < array_length(s.bases); i++) {
        var base = s.bases[i];
        var key = "base:" + string(base.index);
        if (!ds_map_exists(object_map, key)) {
          var base_obj = {
            type: "base",
            lx: base.lx,
            ly: base.ly,
            energy: base.energy,
            index: base.index
          };
          array_push(player.local_objects, base_obj);
          array_push(player.local_bases, base_obj);
          ds_map_add(object_map, key, true);
        }
      }

      // Add enemies as references (indices only)
      for (var i = 0; i < array_length(s.enemies); i++) {
        var enemy = s.enemies[i];
        var key = "enemy:" + string(enemy.index);
        if (!ds_map_exists(object_map, key)) {
          var enemy_ref = { type: "enemy", index: enemy.index };
          array_push(player.local_objects, enemy_ref);
          array_push(player.local_enemies, enemy.index);
          ds_map_add(object_map, key, true);
        }
      }

      ds_map_destroy(object_map);

      // Update SRS regions for hover UI if enemies present
      if (array_length(player.local_enemies) > 0) {
        update_srs_regions();
      } else {
        obj_controller_input.srs_regions = [];
        obj_controller_input.all_regions = array_concat(
          obj_controller_input.hover_regions,
          obj_controller_input.srs_regions
        );
      }

      // Set save alarm to persist progress
      obj_controller_player.alarm[0] = 30;
    }
  }

  ds_map_destroy(enemy_map);
  ds_map_destroy(base_map);

  return s;
}

/// @description: Updates the dynamic enemy regions on the sector grid and
/// pushes to hover_regions
function update_srs_regions() {
  var start_time = get_timer();
  var player = instance_find(obj_controller_player, 0);

  // Sector grid
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  // Clear existing
  obj_controller_input.all_regions = [];
  obj_controller_input.srs_regions = [];

  // Add enemies by index
  for (var i = 0; i < array_length(player.local_enemies); i++) {
    var enemy_index = player.local_enemies[i];
    if (enemy_index >= 0 && enemy_index < array_length(global.allenemies)) {
      var enemy = global.allenemies[enemy_index];

      if (is_struct(enemy) && enemy.energy > 0) {
        var lx = enemy.lx;
        var ly = enemy.ly;

        // Calculate pixel coordinates of this cell on the SRS
        var x1 = map_offset_x + lx * size_cell_x;
        var y1 = map_offset_y + ly * size_cell_y;
        var x2 = x1 + size_cell_x;
        var y2 = y1 + size_cell_y;

        array_push(obj_controller_input.srs_regions, {
          x1 : x1,
          x2 : x2,
          y1 : y1,
          y2 : y2,
          state : HoverState.Enemy + i,
          enemy_index : enemy_index
        });
      }
    }
  }

  // Combine
  obj_controller_input.all_regions = array_concat(
    obj_controller_input.hover_regions, obj_controller_input.srs_regions);
}

/// @description: Moves the player to a new sector in the galaxy, called during warp
/// @param {real} x: Sector x coordinate
/// @param {real} y: Sector y coordinate
function change_sector(x, y) {

  // Validate sector coordinates
  if (x < 0 || x > 7 || y < 0 || y > 7) {
    show_debug_message("Tried to move to invalid sector coordinates: [" +
                       string(x) + "," + string(y) + "]");
    log_resource_usage("Change Sector [Invalid]", start_time);
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
  var available_map = create_coord_map(sector.available_cells);
  if (array_length(sector.available_cells) > 0) {
    sector.seen = true;
    var idx = irandom(array_length(sector.available_cells) - 1);
    global.ent.lx = sector.available_cells[idx][0];
    global.ent.ly = sector.available_cells[idx][1];
    // Ensure player’s cell is in available_cells
    if (!has_coord_map(available_map, global.ent.lx, global.ent.ly)) {
      array_push(sector.available_cells, [ global.ent.lx, global.ent.ly ]);
    }
  } else {
    // Fallback with clearance check
    global.ent.lx = irandom(7);
    global.ent.ly = irandom(7);
    var player_cell = [ global.ent.lx, global.ent.ly ];
    var all_occupied_cells = []; // Rebuild for clearance check
    for (var i = 0; i < array_length(global.allenemies); i++) {
      var e = global.allenemies[i];
      if (is_struct(e))
        array_push(all_occupied_cells, [ e.sx, e.sy, e.lx, e.ly ]);
    }
    for (var i = 0; i < array_length(global.allbases); i++) {
      var b = global.allbases[i];
      if (is_struct(b))
        array_push(all_occupied_cells, [ b.sx, b.sy, b.lx, b.ly ]);
    }
    var occupied_map = create_coord_map(all_occupied_cells, true);
    var too_close = false;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        var nx = global.ent.lx + dx;
        var ny = global.ent.ly + dy;
        if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8 &&
            has_coord_map(occupied_map, nx, ny, x, y)) {
          too_close = true;
          break;
        }
      }
    }
    ds_map_destroy(occupied_map);
    if (!too_close) {
      array_push(sector.available_cells, player_cell);
      sector.seen = true;
    } else {
      show_debug_message("Warning: Fallback cell [" + string(global.ent.lx) +
                         "," + string(global.ent.ly) + "] in sector [" +
                         string(x) + "," + string(y) + "] lacks clearance");
    }
  }
  ds_map_destroy(available_map);

  // Repopulate local sector data
  var sector_data_time = get_timer();
  get_sector_data(global.ent.sx, global.ent.sy);

  // Clear the resolve queue
  global.queue = [];
  global.index = 0;

  // Call the warp movie
  if (!instance_exists(obj_controller_movies)) {
    instance_create_layer(0, 0, "Overlay", obj_controller_movies);
  }

  // Queue up new turn events
  array_push(
      global.queue, function() {
        obj_controller_player.contactedbase = false;
        obj_controller_player.speech_phaserwarn = false;
        obj_controller_player.speech_damaged = false;
        if (random(1) < 0.7)
          obj_controller_player.speech_phaserfire = false;
        if (random(1) < 0.7)
          obj_controller_player.speech_torparm = false;
      });

  debug_sector();
  return true;
}

/// @description: Returns true if (cx, cy) is a valid destination in the current sector
/// @param {real} cx: Cell x
/// @param {real} cy: Cell y
function check_valid_move(cx, cy) {
  // Out-of-bounds check
  if (cx < 0 || cx >= 8 || cy < 0 || cy >= 8)
    return false;
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

/// @description: Checks if the player is next to a starbase in current sector,
/// called after an impulse move
/// @param {real} lx: Local x coordinate
/// @param {real} ly: Local y coordinate
function check_baseloc(lx, ly) {
  var current_sx = global.ent.sx;
  var current_sy = global.ent.sy;

  for (var i = 0; i < array_length(global.allbases); i++) {
    var base = global.allbases[i];
    if (!is_undefined(base) && is_struct(base) && base.sx == current_sx &&
        base.sy == current_sy) {
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
    var enemybonus = global.game.initenemies * 100;
    var timebonus = max(0, global.game.maxdays - global.game.date);
    var basespenalty = global.game.totalbases * 100;
    var efficiencybonus =
        global.ent.energy + global.ent.shields + (global.ent.torpedoes * 20);
    var difficultybonus = (global.game.difficulty - 1) * 10;

    show_debug_message("Score: " + string(enemybonus) + " + " +
                       string(timebonus) + " + " + string(efficiencybonus) +
                       " - " + string(basespenalty) + " + " +
                       string(difficultybonus));
    var raw_score = enemybonus + timebonus + efficiencybonus - basespenalty +
                    difficultybonus;

    global.score = max(0, round(raw_score));
    show_debug_message("Total score: " + string(global.score));

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
  if (obj_controller_dialog.voice_handle == -1 &&
      obj_controller_input.attack_delay <= 0) {

    // Check if there are unresolved items in the dialog/action queue
    if (global.index < array_length(global.queue)) {

      // Only process the next item if no dialog is shown
      if (!instance_exists(obj_controller_dialog) ||
          !obj_controller_dialog.show_text) {
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
          with(obj_controller_dialog) { process_dialog(result); }
        }

        // Exit to enforce delay
        return;
      }
    }

    // Queue condition check (once per step)
    else if (!end_turn && global.game.state != State.Win &&
             global.game.state != State.Lose) {
      global.queue[array_length(global.queue)] = function() {
        return update_ship_condition();
      };
      end_turn = true;
    }

    // If queue is fully resolved and no dialog or voice is active
    else {
      if (!obj_controller_dialog.show_text &&
          obj_controller_dialog.voice_handle == -1) {
        // Reset busy only if shields are not negative OR if dialog
        // finished for destroyed condition
        if (global.game.state != State.Win && global.game.state != State.Lose) {
          if (global.ent.shields >= 0 ||
              (global.ent.condition == Condition.Destroyed &&
               !obj_controller_dialog.show_text &&
               obj_controller_dialog.voice_handle == -1)) {
            global.busy = false;
          }
        }
      }
    }
  }
}
