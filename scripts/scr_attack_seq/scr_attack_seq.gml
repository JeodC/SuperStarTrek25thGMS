/// @description: Entrypoint for enemy attack sequence
/// @param {any} post: Player impulse path (array) or warp destination ([tx, ty]) -- Gets passed into queue_next_enemy_attack
function enemy_attack(post = undefined) {
  var player = instance_find(obj_controller_player, 0);
  if (!player) return;

  global.busy = true;

  // Hide input modes like impulse during enemy attack phase
  global.inputmode.tmp_old = global.inputmode.mode;

  // Filter out invalid or destroyed enemies in-place
  cleanup_sequence();

  show_debug_message("[STARTING ENEMY ATTACK SEQUENCE]");
  show_debug_message("Found " + string(array_length(player.local_enemies)) + " valid enemies to attack.");

  queue_next_enemy_attack(0, post);
}

/// @description: Recursive function that queues an enemy attack in an attack sequence
/// @param {real} i: Index in local_enemies to process
/// @param {any} post: Player impulse path (array) or warp destination ([tx, ty])
function queue_next_enemy_attack(i, post) {
  var player = instance_find(obj_controller_player, 0);
  if (!player) return;

  var len = array_length(player.local_enemies);

  // Done processing all attacks
  if (i >= len) {
    array_push(global.queue, function() {
      var data = obj_controller_player._data;
      cleanup_sequence();
      global.inputmode.mode = global.inputmode.tmp_old;
      show_debug_message("[ENEMY ATTACK SEQUENCE RESOLVED]");

      // Process post-attack warp or impulse moves
      if (is_struct(data) && global.ent.condition != Condition.Destroyed) {
        if (!is_undefined(data.post)) {
          if (is_array(data.post) && array_length(data.post) > 0 &&
              is_array(data.post[0])) {
            global.ent.impulse_move(data.post);
          } else if (array_length(data.post) == 2) {
            change_sector(data.post[0], data.post[1]);
          }
        }
      }

      return {delay : 10};
    });

    // Reset global queue
    array_push(global.queue, function() {
      global.queue = [];
      global.index = 0;
      global.busy = false;
      return undefined;
    });

    return;
  }

  // Get enemy index from local_enemies and use it to populate enemy var
  var enemy_index = player.local_enemies[i];
  var enemy = global.allenemies[enemy_index];

  // Validate enemy by index
  if (!is_numeric(enemy_index) || enemy_index < 0 || enemy_index >= array_length(global.allenemies)) {
    queue_next_enemy_attack(i + 1, post);
    return;
  }

  // Validate enemy by data
  if (!is_struct(enemy) || enemy.energy <= 0 || enemy.sx != global.ent.sx || enemy.sy != global.ent.sy) {
    queue_next_enemy_attack(i + 1, post);
    return;
  }

  // Get player/enemy coordinates
  var px = global.ent.lx;
  var py = global.ent.ly;
  var lx = enemy.lx;
  var ly = enemy.ly;

  var dx = abs(px - lx);
  var dy = abs(py - ly);
  var distance = max(point_distance(px, py, lx, ly), 1);
  var modifier = 2.0 + random(1.0);
  var damage = ceil((enemy.energy / 2) * modifier / distance);

  var queue_index = array_length(global.queue);

  // Create attack metadata
  var data = {
    lx : lx,
    ly : ly,
    energy : enemy.energy,
    idx : enemy_index,
    px : px,
    py : py,
    difficulty : global.game.difficulty,
    damage : damage,
    base_index : queue_index,
    current_enemy : i,
    attack_count : len,
    i : i,
    post : post
  };

  obj_controller_player._data = data;

  // Reserve multiple queue slots for the different phases of this enemy's attack sequence
  // Each slot corresponds to a queued function that handles a specific step in the attack process
  player.attack_buffer[queue_index] = data; // Store attack data in the player's attack buffer at the appropriate index
  player.attack_indexes[queue_index + 0] = queue_index; // Attack dialog
  player.attack_indexes[queue_index + 1] = queue_index; // Visual effect
  player.attack_indexes[queue_index + 2] = queue_index; // Damage application/dialog
  player.attack_indexes[queue_index + 3] = queue_index; // Queue next enemy (recursive continuation)
  if (i < len - 1) {
    player.attack_indexes[queue_index + 4] = queue_index; // Delay between attacks (if not last enemy)
  }

  show_debug_message("Enemy " + string(enemy_index) + " at [" + string(lx) + "," + string(ly) +
                     "] attacking player at [" + string(px) + "," + string(py) +
                     "] | Distance: " + string(distance) +
                     " | Energy: " + string(enemy.energy) +
                     " | Modifier: " + string(modifier) +
                     " | Damage: " + string(damage));

  // Queue attack dialog
  array_push(global.queue, function() {
    var idx = obj_controller_player.attack_indexes[global.index];
    var data = obj_controller_player.attack_buffer[idx];
    return immediate_dialog(
      Speaker.Sulu,
      "battle.enemyfiring",
      noone,
      {coord: string(data.lx + 1) + "," + string(data.ly + 1)}
    );
  });

  // Queue visual effect
  array_push(global.queue, function() {
    var idx = obj_controller_player.attack_indexes[global.index];
    var data = obj_controller_player.attack_buffer[idx];
    var enemy = global.allenemies[data.idx];

    if (is_struct(enemy)) {
      // Face player
      if (enemy.lx != data.px || enemy.ly != data.py) {
        var dx = data.px - enemy.lx;
        var dy = data.py - enemy.ly;
        enemy.dir = abs(dx) >= abs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0);
      }

      audio_play_sound(snd_enemy_phaser, 0, false);
      var p = instance_create_layer(0, 0, "Overlay", obj_phaser);
      p.x1 = data.lx;
      p.y1 = data.ly;
      p.x2 = data.px;
      p.y2 = data.py;
      p.type = 2;
      p.duration = 40;
    }

    return {delay: 40};
  });

  // Queue damage application
  array_push(global.queue, function() {
    var idx = obj_controller_player.attack_indexes[global.index];
    var data = obj_controller_player.attack_buffer[idx];
    var keys = variable_struct_get_names(global.ent.system);

    if (data.damage < 1) {
      return immediate_dialog(Speaker.Sulu, "battle.evade");
    }

    // Damage shields
    global.ent.shields -= round(data.damage);
    show_debug_message("Player hit for " + string(round(data.damage)) + " damage!");

    damage_random_systems(round(data.damage / (10 - data.difficulty)));

    // Update general damage
    global.ent.generaldamage = 0;
    for (var j = 0; j < array_length(keys); j++) {
      var val = global.ent.system[$ keys[j]];
      if (val < 90 && global.ent.generaldamage < 1) global.ent.generaldamage = 1;
      if (val < 66 && global.ent.generaldamage < 2) global.ent.generaldamage = 2;
      if (val < 33 && global.ent.generaldamage < 3) global.ent.generaldamage = 3;
    }

    // Drain enemy energy
    var enemy = global.allenemies[data.idx];
    if (is_struct(enemy)) {
      var emod = max(1.1, 3.0 + random(1.0));
      enemy.energy = max(round(enemy.energy / emod), 0);
    }

    // Check for destruction
    if (global.ent.shields < 0) {
      global.ent.condition = Condition.Destroyed;
      global.busy = true;
      array_resize(global.queue, global.index);

      array_push(global.queue, function() {
        return [immediate_dialog(Speaker.Spock, "redalert.shieldsdown")[0]];
      });
      array_push(global.queue, function() {
        dialog_condition();
        return undefined;
      });

      return undefined;
    }

    // If player survived, queue reaction dialog
    return dialog_disruptorhit(data.damage);
  });

  // Queue next attack
  array_push(global.queue, function() {
    var data = obj_controller_player._data;
    queue_next_enemy_attack(data.i + 1, data.post);
  });

  // Delay between attacks
  if (i < len - 1) {
    array_push(global.queue, function() { return {delay: 40}; });
  }
}

/// @description: Begins the player's phaser attack sequence
function player_phaser_attack() {
  global.busy = true;

  var player = instance_find(obj_controller_player, 0);
  
  // Validate enemies
  validate_enemies();

  // Sanitize
  player._data = undefined;
  player.attack_buffer = [];
  player.attack_index = 0;
  player.destroyed_count = 0;

  // Use local_enemies directly as the attack list
  var total_targets = array_length(player.local_enemies);
  var total_phasers = global.ent.phasers;
  var per_enemy_phasers = round(total_phasers / total_targets);

  global.ent.phasers -= per_enemy_phasers * total_targets;
  global.ent.phasers = max(0, global.ent.phasers);

  player.attack_phasers = per_enemy_phasers;
  player.attack_difficulty = global.game.difficulty;

  show_debug_message("[STARTING PLAYER ATTACK SEQUENCE]");
  show_debug_message("Player allotted " + string(total_phasers) + " energy to phasers.");
  show_debug_message("Calculated " + string(per_enemy_phasers) + " phasers per enemy.");

  // Start attack sequence, starting at index 0
  queue_next_attack(0);
}

/// @description: Recursive function to queue a player phaser attack for an enemy
/// @param {real} i: Index in local_enemies to process
function queue_next_attack(i) {
  var player = obj_controller_player;

  var targets = player.local_enemies;
  var len = array_length(targets);

  // Check if finished sequence
  if (i >= len) {
    player._data = undefined;
    player.destroyed_count = 0;

    array_push(global.queue, function() {
      cleanup_sequence();
      show_debug_message("[PLAYER ATTACK SEQUENCE RESOLVED]");
      
      // Enemies get to counterattack
      if (array_length(obj_controller_player.local_enemies) > 0) {
        enemy_attack();
      }
    });

    return;
  }

  // Pull enemy data
  var enemy_index = targets[i];
  var enemy = global.allenemies[enemy_index];

  // Player and enemy coords
  var px = global.ent.lx;
  var py = global.ent.ly;
  var lx = enemy.lx;
  var ly = enemy.ly;

  var dx = abs(px - lx);
  var dy = abs(py - ly);
  var distance = max(point_distance(px, py, lx, ly), 1);
  var modifier = min(2.5 + random(1.0), 3.5);
  var damage = ceil(player.attack_phasers * modifier / distance);
  var current_energy = enemy.energy;

  // Prepare attack data
  var data = {
    px: px,
    py: py,
    lx: lx,
    ly: ly,
    idx: enemy_index,
    difficulty: player.attack_difficulty,
    damage: damage,
    energy: current_energy,
    i: i
  };

  player._data = data;

  // Visual effect
  array_push(global.queue, function() {
    audio_play_sound(snd_player_phaser, 0, false);
    var p = instance_create_layer(0, 0, "Overlay", obj_phaser);
    p.x1 = obj_controller_player._data.px;
    p.y1 = obj_controller_player._data.py;
    p.x2 = obj_controller_player._data.lx;
    p.y2 = obj_controller_player._data.ly;
    p.type = 1;
    p.duration = 40;
    return {delay: 40};
  });

  // Damage and dialog
  array_push(global.queue, function() {
    var data = obj_controller_player._data;
    var idx = data.idx;

    if (idx < 0 || idx >= array_length(global.allenemies) || !is_struct(global.allenemies[idx])) {
      show_debug_message("Warning: Enemy index " + string(idx) + " invalid during damage phase!");
      return [];
    }

    var enemy = global.allenemies[idx];

    // Apply damage
    var new_energy = max(enemy.energy - data.damage, 0);
    enemy.energy = new_energy;

    show_debug_message("Firing on enemy index " + string(idx) + 
                       " at [" + string(data.lx) + "," + string(data.ly) + "].");
    show_debug_message("Calculated " + string(data.damage) + 
                       " damage. Enemy energy now " + string(new_energy) + 
                       " down from " + string(data.energy) + ".");

    return dialog_phaserhit(data.damage, data.energy, new_energy, data.lx, data.ly, idx);
  });

  // Queue next attack
  array_push(global.queue, function() {
    var data = obj_controller_player._data;
    obj_controller_player._data = undefined;
    queue_next_attack(data.i + 1);
  });
}

/// @description: Removes an enemy from the galaxy, creates explosion effect,
/// and queues dialog
/// @param {real} idx: Enemy index in global.allenemies
function destroy_enemy(idx) {
  
  // Validate index
  if (idx < 0 || idx >= array_length(global.allenemies) ||
      is_undefined(global.allenemies[idx]) ||
      !is_struct(global.allenemies[idx])) {
    show_debug_message("Error: Invalid enemy index " + string(idx));
    return;
  }

  var e = global.allenemies[idx];

  // Explosion effects
  audio_play_sound(snd_explosionsmall, 0, false);
  instance_create_layer(0, 0, "Overlay", obj_explosion, { lx: e.lx, ly: e.ly });
  particle_explosion(e.lx, e.ly);

  // Mark enemy as removed instead of deleting to keep index stable
  global.allenemies[idx] = undefined;

  // Update global counters
  global.game.totalenemies = max(global.game.totalenemies - 1, 0);

  // Update sector data
  var sx = e.sx;
  var sy = e.sy;
  var sector = global.galaxy[sx][sy];
  sector.enemynum = max(sector.enemynum - 1, 0);
  array_push(sector.available_cells, [e.lx, e.ly]);

  show_debug_message("Enemy at [" + string(e.lx) + "," + string(e.ly) + "] destroyed!");

  // Update player local arrays if in current sector
  // Unlike validate_enemies, this preserves the array indices so enemy counterattacks don't run into off-by-one errors
  // during enemy counterattack recursion (e.g. queue_next_enemy_attack)
  if (sx == global.ent.sx && sy == global.ent.sy) {
    var player = instance_find(obj_controller_player, 0);
    if (player) {
      // Remove enemy references by setting entries to undefined
      for (var i = array_length(player.local_objects) - 1; i >= 0; i--) {
        var obj = player.local_objects[i];
        if (is_struct(obj) && obj.type == "enemy" && obj.index == idx) {
          player.local_objects[i] = undefined;
        }
      }
      for (var i = array_length(player.local_enemies) - 1; i >= 0; i--) {
        if (player.local_enemies[i] == idx) {
          player.local_enemies[i] = undefined;
        }
      }
    }
  }

  // Queue dialog if last enemy in sector
  if (sector.enemynum < 1) {
    global.busy = true;
    array_push(global.queue, function() { return { delay: 60 }; });
    queue_dialog(Speaker.Spock, "weapons.lastone", vo_spock_noships);
    check_win();
  }
}

/// @description: Rebuilds player.local_enemies array with valid enemies
/// This is called at the start of the player attack sequence
/// and during the cleanup sequence
function validate_enemies() {
  var player = obj_controller_player;

  player.local_enemies = array_filter(player.local_enemies, function(idx) {
    if (!is_numeric(idx)) return false;
    if (idx < 0 || idx >= array_length(global.allenemies)) return false;

    var e = global.allenemies[idx];
    if (!is_struct(e)) return false;
    if (e.energy <= 0) return false;

    return true;
  });
}

/// @description: Clean up player local enemy references and refresh data
/// Called at the end of attack sequences
function cleanup_sequence() {

  // Refresh local sector data
  get_sector_data();
  
  // Validate local enemies
  validate_enemies();

  // Reset any attack buffers and queues
  var player = instance_find(obj_controller_player, 0);
  if (player) {
    player.attack_buffer = [];
    player.attack_indexes = [];
    player._data = undefined;
    player.attack_index = 0;
  }
}

/// @description: Checks if the player won
function check_win() {
  // Check if player won (no enemies left in galaxy)
  if (global.game.totalenemies <= 0) {
    queue_dialog(Speaker.Uhura, "condition.win1");
    queue_dialog(Speaker.Kirk, "condition.win2", vo_kirk_onscreen);
    array_push(global.queue, function() { return {delay: 20}; });
    array_push(global.queue, function() {
      global.ent.condition = Condition.Win;
      winlose();
    });
  }
}