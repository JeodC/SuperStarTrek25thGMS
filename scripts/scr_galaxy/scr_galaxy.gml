/// @description: Places enemies with 3x3 cell clearance
/// @param {real} enemy_count - Number of enemies already placed
/// @param {real} total_enemies - Target number of enemies to place
/// @param {array} all_occupied_cells - Reference array to track placed positions
function place_enemies(enemy_count, total_enemies, all_occupied_cells) {
  var attempts = 0;
  var max_attempts = min(total_enemies * 5, 200);

  while (enemy_count < total_enemies && attempts < max_attempts) {
    attempts++;

    // Pick a random sector
    var sx = irandom(7);
    var sy = irandom(7);
    var s = global.galaxy[sx][sy];

    // Skip if sector is full
    if (s.enemynum >= 3)
      continue;

    // Random fleet size: 15% chance for 2, 10% chance for 3
    var r1 = irandom_range(1, 20);
    var fleet_size = 1;
    if (r1 > 18)
      fleet_size = 3;
    else if (r1 > 15)
      fleet_size = 2;

    // Clamp fleet size
    fleet_size = min(fleet_size, total_enemies - enemy_count, 3 - s.enemynum);

    // Precompute valid cells with clearance
    var valid_cells = [];
    var occupied_map = create_coord_map(all_occupied_cells,
                                        true); // Use sector-specific keys
    for (var i = 0; i < array_length(s.available_cells); i++) {
      var lx = s.available_cells[i][0];
      var ly = s.available_cells[i][1];
      var too_close = false;

      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          var nx = lx + dx;
          var ny = ly + dy;
          if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
            if (has_coord_map(occupied_map, nx, ny, sx, sy)) {
              too_close = true;
              break;
            }
          }
        }
        if (too_close)
          break;
      }

      if (!too_close)
        array_push(valid_cells, [ lx, ly ]);
    }
    ds_map_destroy(occupied_map);

    // Skip if no valid cells
    if (array_length(valid_cells) == 0)
      continue;

    // Place fleet members
    var placed = 0;
    var temp_occupied = [];
    var valid_cells_length = array_length(valid_cells);

    while (placed < fleet_size && valid_cells_length > 0) {
      var idx = irandom(valid_cells_length - 1);
      var lx = valid_cells[idx][0];
      var ly = valid_cells[idx][1];

      // Check clearance against temp_occupied
      var too_close = false;
      for (var j = 0; j < array_length(temp_occupied); j++) {
        var dx = temp_occupied[j][0] - lx;
        var dy = temp_occupied[j][1] - ly;
        if (abs(dx) <= 1 && abs(dy) <= 1) {
          too_close = true;
          break;
        }
      }
      if (too_close) {
        valid_cells[idx] = valid_cells[valid_cells_length - 1];
        array_pop(valid_cells);
        valid_cells_length--;
        continue;
      }

      // Create and initialize enemy ship
      var e = EnemyShip();
      e.sx = sx;
      e.sy = sy;
      e.lx = lx;
      e.ly = ly;
      e.dir = irandom(4);

      var kenergy = (50 + irandom(100)) / 100.0;
      e.maxenergy = round(global.game.enemypower * kenergy);
      e.energy = e.maxenergy;

      // Add to global state
      array_push(global.allenemies, e);
      array_push(all_occupied_cells, [ sx, sy, lx, ly ]);
      array_push(temp_occupied, [ lx, ly ]);

      // Remove used cell
      remove_coord(s.available_cells, lx, ly);

      // Update valid_cells
      valid_cells[idx] = valid_cells[valid_cells_length - 1];
      array_pop(valid_cells);
      valid_cells_length--;

      enemy_count++;
      placed++;
    }

    // Update sector
    if (placed > 0) {
      s.enemynum += placed;
      global.galaxy[sx][sy] = s;
    }
  }

  if (attempts >= max_attempts) {
    show_debug_message(
        "Warning: Reached max attempts in place_enemies. Placed " +
        string(enemy_count) + " out of " + string(total_enemies));
  }

  return enemy_count;
}

/// @function: place_starbases
/// @description: Places starbases with 3x3 cell clearance
/// @param {real} base_count - Number of starbases already placed
/// @param {real} total_bases - Target number of starbases to place
/// @param {array} all_occupied_cells - Reference array to track placed positions
function place_starbases(base_count, total_bases, all_occupied_cells) {
  // Cache valid sectors
  var valid_sectors = [];
  for (var sx = 0; sx < 8; sx++) {
    for (var sy = 0; sy < 8; sy++) {
      var s = global.galaxy[sx][sy];
      if (s.basenum == 0 && array_length(s.available_cells) > 0) {
        array_push(valid_sectors, [ sx, sy ]);
      }
    }
  }

  // Shuffle sectors for randomness
  valid_sectors = array_shuffle(valid_sectors);

  // Limit attempts
  var attempts = 0;
  var max_attempts = total_bases * 10;

  var sector_idx = 0;
  while (base_count < total_bases && sector_idx < array_length(valid_sectors) &&
         attempts < max_attempts) {
    attempts++;
    var sx = valid_sectors[sector_idx][0];
    var sy = valid_sectors[sector_idx][1];
    var s = global.galaxy[sx][sy];
    sector_idx++;

    // Precompute valid cells with 3x3 clearance
    var valid_cells = [];
    for (var i = 0; i < array_length(s.available_cells); i++) {
      var lx = s.available_cells[i][0];
      var ly = s.available_cells[i][1];
      var too_close = false;

      for (var j = 0; j < array_length(all_occupied_cells); j++) {
        if (all_occupied_cells[j][0] == sx && all_occupied_cells[j][1] == sy) {
          var dx = all_occupied_cells[j][2] - lx;
          var dy = all_occupied_cells[j][3] - ly;
          if (abs(dx) <= 1 && abs(dy) <= 1) {
            too_close = true;
            break;
          }
        }
      }

      if (!too_close)
        array_push(valid_cells, [ lx, ly ]);
    }

    if (array_length(valid_cells) == 0)
      continue;

    // Pick random valid cell
    var base_cell = valid_cells[irandom(array_length(valid_cells) - 1)];
    var lx = base_cell[0];
    var ly = base_cell[1];

    // Place starbase
    s.basenum = 1;
    array_push(all_occupied_cells, [ sx, sy, lx, ly ]);
    remove_coord(s.available_cells, lx, ly);

    var base = Starbase();
    base.sx = sx;
    base.sy = sy;
    base.lx = lx;
    base.ly = ly;
    base.num = base_count;
    array_push(global.allbases, base);
    base_count++;

    global.galaxy[sx][sy] = s;
  }

  if (attempts >= max_attempts) {
    show_debug_message(
        "Warning: Reached max attempts in place_starbases. Placed " +
        string(base_count) + " out of " + string(total_bases));
  }

  return base_count;
}

/// @description: Places stars with 3x3 clearance
/// Enforces unique row/column for first 8 stars
/// @param {array} all_occupied_cells - Reference array to track placed positions
function place_stars(all_occupied_cells) {
  for (var sx = 0; sx < 8; sx++) {
    for (var sy = 0; sy < 8; sy++) {
      var s = global.galaxy[sx][sy];
      s.starnum = irandom_range(1, global.game.maxstars);
      s.star_positions = [];
      var reserved_cells = [];

      // Bitfields for row/column
      var used_rows = 0;
      var used_cols = 0;

      // Cache sector-specific occupied cells
      var sector_occupied = [];
      for (var i = 0; i < array_length(all_occupied_cells); i++) {
        if (all_occupied_cells[i][0] == sx && all_occupied_cells[i][1] == sy) {
          array_push(sector_occupied,
                     [ all_occupied_cells[i][2], all_occupied_cells[i][3] ]);
        }
      }
      var sector_occupied_map = create_coord_map(sector_occupied, false);

      var tries = 0;
      var max_tries = 50;
      while (array_length(s.star_positions) < s.starnum && tries < max_tries &&
             array_length(s.available_cells) > 0) {
        var valid_candidates = [];
        for (var i = 0; i < array_length(s.available_cells); i++) {
          var lx = s.available_cells[i][0];
          var ly = s.available_cells[i][1];

          if (array_length(s.star_positions) < 8) {
            if (used_rows & (1 << ly) || used_cols & (1 << lx))
              continue;
          }

          var too_close = false;
          for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
              var nx = lx + dx;
              var ny = ly + dy;
              if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                if (has_coord_map(sector_occupied_map, nx, ny) ||
                    has_coord(s.star_positions, nx, ny)) {
                  too_close = true;
                  break;
                }
              }
            }
            if (too_close)
              break;
          }

          if (!too_close)
            array_push(valid_candidates, [ lx, ly, i ]);
        }

        if (array_length(valid_candidates) == 0) {
          tries++;
          continue;
        }

        var choice =
            valid_candidates[irandom(array_length(valid_candidates) - 1)];
        var lx = choice[0];
        var ly = choice[1];

        array_push(s.star_positions, [ lx, ly ]);
        if (array_length(s.star_positions) <= 8) {
          used_rows |= (1 << ly);
          used_cols |= (1 << lx);
        }
        array_push(all_occupied_cells, [ sx, sy, lx, ly ]);
        ds_map_add(sector_occupied_map, string(lx) + "," + string(ly), true);
        array_push(sector_occupied, [ lx, ly ]);

        // Remove star and surrounding cells
        for (var dx = -1; dx <= 1; dx++) {
          for (var dy = -1; dy <= 1; dy++) {
            var nx = lx + dx;
            var ny = ly + dy;
            if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8 &&
                !has_coord(reserved_cells, nx, ny)) {
              array_push(reserved_cells, [ nx, ny ]);
              remove_coord(s.available_cells, nx, ny);
            }
          }
        }

        tries = 0;
      }

      s = restore_reserved_cells(s, reserved_cells, sector_occupied);
      global.galaxy[sx][sy] = s;
      ds_map_destroy(sector_occupied_map);
    }
  }
}

/// @description: Places player with at least 3 neighboring available cells
/// @param {array} all_occupied_cells - Reference array to track placed positions
function place_player(all_occupied_cells) {
  // Cache valid sectors
  var valid_sectors = [];
  for (var sx = 0; sx < 8; sx++) {
    for (var sy = 0; sy < 8; sy++) {
      var s = global.galaxy[sx][sy];
      if (array_length(s.available_cells) > 0) {
        array_push(valid_sectors, [ sx, sy ]);
      }
    }
  }
  valid_sectors = array_shuffle(valid_sectors);

  // Cache all_occupied_cells as ds_map for faster checks
  var occupied_map = create_coord_map(all_occupied_cells, true);

  // Limit attempts
  var max_attempts = array_length(valid_sectors) * 2;
  var attempts = 0;

  for (var i = 0; i < array_length(valid_sectors) && attempts < max_attempts;
       i++) {
    attempts++;
    var sx = valid_sectors[i][0];
    var sy = valid_sectors[i][1];
    var sector = global.galaxy[sx][sy];

    // Create ds_map for available_cells
    var available_map = create_coord_map(sector.available_cells);

    // Precompute valid cells with 3 neighbors
    var valid_cells = [];
    for (var j = 0; j < array_length(sector.available_cells); j++) {
      var lx = sector.available_cells[j][0];
      var ly = sector.available_cells[j][1];
      if (has_clearance(sector.available_cells, lx, ly, 3)) {
        array_push(valid_cells, [ lx, ly ]);
      }
    }
    ds_map_destroy(available_map);

    if (array_length(valid_cells) == 0)
      continue;

    // Pick random valid cell
    var cell = valid_cells[irandom(array_length(valid_cells) - 1)];
    var lx = cell[0];
    var ly = cell[1];

    // Place player
    global.ent.sx = sx;
    global.ent.sy = sy;
    global.ent.lx = lx;
    global.ent.ly = ly;
    sector.seen = true;

    // Reserve neighbors
    var reserved_cells = [];
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        var nx = lx + dx;
        var ny = ly + dy;
        if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8 &&
            !has_coord_map(occupied_map, nx, ny, sx, sy)) {
          if (!has_coord(reserved_cells, nx, ny)) {
            array_push(reserved_cells, [ nx, ny ]);
          }
          remove_coord(sector.available_cells, nx, ny);
        }
      }
    }

    // Add player cell back if needed
    if (!has_coord(sector.available_cells, lx, ly)) {
      array_push(sector.available_cells, [ lx, ly ]);
    }

    // Restore reserved cells
    var sector_occupied = [];
    for (var j = 0; j < array_length(all_occupied_cells); j++) {
      if (all_occupied_cells[j][0] == sx && all_occupied_cells[j][1] == sy) {
        array_push(sector_occupied,
                   [ all_occupied_cells[j][2], all_occupied_cells[j][3] ]);
      }
    }
    sector = restore_reserved_cells(sector, reserved_cells, sector_occupied);

    global.galaxy[sx][sy] = sector;
    ds_map_destroy(occupied_map);

    show_debug_message("Player placed at sector [" + string(sx) + "," +
                       string(sy) + "] cell [" + string(lx) + "," + string(ly) +
                       "]");
    return;
  }

  ds_map_destroy(occupied_map);
  show_debug_message("Failed to place player with proper clearance.");
}

/// @description: Generates the game map and populates sectors
function generate_galaxy() {
  randomize();
  global.game.difficulty = global.difficulty;
  global.game.totalbases = max(1, 5 - global.game.difficulty);
  global.game.initenemies =
      17 + (global.game.difficulty * 3) + irandom_range(0, 5);

  var enemy_count = 0;
  var base_count = 0;
  var all_occupied_cells = []; // Local array to track occupied cells

  // Reset and verify sectors
  for (var sx = 0; sx < 8; sx++) {
    for (var sy = 0; sy < 8; sy++) {
      var s = global.galaxy[sx][sy];

      // Reset fields to prevent memory accumulation
      s.starnum = 0;
      s.basenum = 0;
      s.enemynum = 0;
      s.star_positions = [];
      s.available_cells = [];
      for (var lx = 0; lx < 8; lx++) {
        for (var ly = 0; ly < 8; ly++) {
          array_push(s.available_cells, [ lx, ly ]);
        }
      }
    }
  }

  // Place enemies, starbases, stars, player
  enemy_count = place_enemies(enemy_count, global.game.initenemies, all_occupied_cells);
  global.game.totalenemies = enemy_count;

  if (enemy_count != global.game.initenemies) {
    show_debug_message("Enemy count mismatch: Expected " +
                       string(global.game.initenemies) + ", placed " +
                       string(enemy_count));
    game_restart();
  }

  base_count =
      place_starbases(base_count, global.game.totalbases, all_occupied_cells);
  place_stars(all_occupied_cells);
  place_player(all_occupied_cells);

  // Validate available_cells
  validate_available_cells(all_occupied_cells);

  debug_galaxy();
}

/// @description: Returns the contents of the galaxy map
function get_galaxy_data() {
  if (!is_array(global.galaxy))
    return [];

  var width = array_length(global.galaxy);
  if (width == 0)
    return [];

  var height = array_length(global.galaxy[0]);
  var data = array_create(width * height, "***");

  for (var sx = 0; sx < width; sx++) {
    var row = global.galaxy[sx];
    if (!is_array(row))
      continue;

    var row_height = array_length(row);
    for (var sy = 0; sy < row_height; sy++) {
      var sector = get_sector_data(sx, sy);
      var index = sy * width + sx;

      if (sector.seen) {
        if (sector.enemynum >= 0) {
          data[index] = string(sector.enemynum) + string(sector.basenum) +
                        string(sector.starnum);
        }
      }
    }
  }

  return data;
}

/// @description: Returns true if cell at (lx, ly) has at least `required`
/// neighbors in `cell_array`.
function has_clearance(cell_array, lx, ly, required) {
  var count = 0;
  for (var dx = -1; dx <= 1; dx++) {
    for (var dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0)
        continue;
      var nx = lx + dx;
      var ny = ly + dy;
      if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
        if (has_coord(cell_array, nx, ny)) {
          count++;
          if (count >= required)
            return true;
        }
      }
    }
  }
  return false;
}

/// @description: Creates a ds_map from cell_array for fast coordinate lookups
function create_coord_map(cell_array, use_sector = false) {
  var coord_map = ds_map_create();
  for (var i = 0; i < array_length(cell_array); i++) {
    var key = use_sector
                  ? string(cell_array[i][0]) + "," + string(cell_array[i][1]) +
                        ":" + string(cell_array[i][2]) + "," +
                        string(cell_array[i][3])
                  : string(cell_array[i][0]) + "," + string(cell_array[i][1]);
    ds_map_add(coord_map, key, true);
  }
  return coord_map;
}

/// @description: Checks if coordinate exists in ds_map
function has_coord_map(coord_map, lx, ly, sx = undefined, sy = undefined) {
  var key =
      (sx == undefined || sy == undefined)
          ? string(lx) + "," + string(ly)
          : string(sx) + "," + string(sy) + ":" + string(lx) + "," + string(ly);
  return ds_map_exists(coord_map, key);
}

/// @description: Returns true if `cell_array` contains the coordinate (lx, ly)
/// in sector (sx, sy).
function has_coord(cell_array, lx, ly, sx = undefined, sy = undefined) {
  for (var i = 0; i < array_length(cell_array); i++) {
    if (sx == undefined && sy == undefined) {
      if (array_length(cell_array[i]) == 2 && cell_array[i][0] == lx &&
          cell_array[i][1] == ly) {
        return true;
      }
    } else {
      if (array_length(cell_array[i]) == 4 && cell_array[i][0] == sx &&
          cell_array[i][1] == sy && cell_array[i][2] == lx &&
          cell_array[i][3] == ly) {
        return true;
      }
    }
  }
  return false;
}

/// @description: Removes the coordinate (lx, ly) from `cell_array` if found.
function remove_coord(cell_array, lx, ly) {
  var i = 0;
  while (i < array_length(cell_array)) {
    if (cell_array[i][0] == lx && cell_array[i][1] == ly) {
      array_delete(cell_array, i, 1);
    } else {
      i++;
    }
  }
}

/// @description: Ensures no occupied cells are in available_cells
function validate_available_cells(all_occupied_cells) {
  var occupied_map = create_coord_map(all_occupied_cells, true);
  var errors = 0;
  for (var sx = 0; sx < 8; sx++) {
    for (var sy = 0; sy < 8; sy++) {
      var s = global.galaxy[sx][sy];
      for (var i = 0; i < array_length(s.available_cells); i++) {
        var lx = s.available_cells[i][0];
        var ly = s.available_cells[i][1];
        if (has_coord_map(occupied_map, lx, ly, sx, sy)) {
          show_debug_message("Error: Occupied cell [" + string(lx) + "," +
                             string(ly) + "] in sector [" + string(sx) + "," +
                             string(sy) + "] is in available_cells.");
          errors++;
        }
      }
    }
  }
  ds_map_destroy(occupied_map);
  if (errors > 0) {
    show_debug_message("Validation failed with " + string(errors) +
                       " errors. Consider debugging placement logic.");
  }
}

/// @description: Restores reserved cells to available_cells, excluding occupied cells
function restore_reserved_cells(sector, reserved_cells, occupied_cells) {
  var occupied_map = create_coord_map(occupied_cells);
  var available_map = create_coord_map(sector.available_cells);
  for (var i = 0; i < array_length(reserved_cells); i++) {
    var lx = reserved_cells[i][0];
    var ly = reserved_cells[i][1];
    if (!has_coord_map(occupied_map, lx, ly) &&
        !has_coord_map(available_map, lx, ly)) {
      array_push(sector.available_cells, [ lx, ly ]);
    }
  }
  ds_map_destroy(occupied_map);
  ds_map_destroy(available_map);
  return sector;
}

/// @description: Resets the galaxy array
function clear_galaxy() {
  global.galaxy = array_create(8);
  for (var sx = 0; sx < 8; sx++) {
    global.galaxy[sx] = array_create(8);
    for (var sy = 0; sy < 8; sy++) {
      global.galaxy[sx][sy] = Sector();
      global.galaxy[sx][sy].available_cells = [];
      for (var lx = 0; lx < 8; lx++) {
        for (var ly = 0; ly < 8; ly++) {
          array_push(global.galaxy[sx][sy].available_cells, [ lx, ly ]);
        }
      }
    }
  }
}