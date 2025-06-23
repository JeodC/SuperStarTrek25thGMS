/// @function: place_enemies
/// @description: Places enemies with 3x3 cell clearance
/// @param {real} enemy_count - Number of enemies already placed
/// @param {real} total_enemies - Target number of enemies to place
/// @param {array} all_occupied_cells - Reference array to track placed positions
function place_enemies(enemy_count, total_enemies, all_occupied_cells) {
    // Limit placement attempts to avoid long loops
    var attempts = 0;
    var max_attempts = min(total_enemies * 10, 400);

    // Main placement loop
    while (enemy_count < total_enemies && attempts < max_attempts) {
        attempts++;

        // Pick a random sector
        var sx = irandom(7);
        var sy = irandom(7);
        var s = global.galaxy[sx][sy];

        // Random fleet size: 15% chance for 2, 10% chance for 3
        var r1 = irandom_range(1, 20);
        var fleet_size = 1;
        if (r1 > 18) fleet_size = 3;
        else if (r1 > 15) fleet_size = 2;

        // Clamp fleet size so we don't exceed total needed
        if (enemy_count + fleet_size > total_enemies) {
            fleet_size = total_enemies - enemy_count;
        }

        // Clamp to available space in this sector (max 3)
        var max_allowed = 3 - s.enemynum;
        if (max_allowed <= 0) continue;
        if (fleet_size > max_allowed) fleet_size = max_allowed;

        // Shuffle the sector’s available local cells
        s.available_cells = array_shuffle(s.available_cells);

        var placed = 0;
        var temp_occupied = []; // Track enemies placed in this fleet

        // Attempt to place fleet members in this sector
        for (var i = 0; i < array_length(s.available_cells) && placed < fleet_size; i++) {
            var lx = s.available_cells[i][0];
            var ly = s.available_cells[i][1];

            // Check clearance against all occupied cells and temp_occupied
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
            for (var j = 0; j < array_length(temp_occupied); j++) {
                var dx = temp_occupied[j][0] - lx;
                var dy = temp_occupied[j][1] - ly;
                if (abs(dx) <= 1 && abs(dy) <= 1) {
                    too_close = true;
                    break;
                }
            }

            if (too_close) continue;

            // Create and initialize the enemy ship
            var e = EnemyShip();
            e.sx = sx;
            e.sy = sy;
            e.lx = lx;
            e.ly = ly;
            e.dir = irandom(4);

            // Scale energy based on game difficulty
            var kenergy = (50 + irandom(100)) / 100.0;
            e.maxenergy = round(global.game.enemypower * kenergy);
            e.energy = e.maxenergy;

            // Add to global state
            array_push(global.allenemies, e);
            array_push(all_occupied_cells, [sx, sy, lx, ly]);
            array_push(temp_occupied, [lx, ly]); // Track for this fleet
            enemy_count++;
            placed++;

            // Remove the used cell and adjust loop
            array_delete(s.available_cells, i, 1);
            i--;
        }

        // Only update sector if we placed something
        if (placed > 0) {
            s.enemynum += placed;
            global.galaxy[sx][sy] = s;
        }
    }

    // Warn if max attempts reached
    if (attempts >= max_attempts) {
        show_debug_message("Warning: Reached max attempts in place_enemies. Placed " + string(enemy_count) + " out of " + string(total_enemies));
    }

    return enemy_count;
}

/// @description: Tests available cells in sectors and places starbases
function place_starbases(base_count, total_bases, all_occupied_cells) {
    while (base_count < total_bases) {
        var sx = irandom(7);
        var sy = irandom(7);
        var s = global.galaxy[sx][sy];
        if (s.basenum == 0 && array_length(s.available_cells) > 0) {
            s.basenum = 1;
            s.available_cells = array_shuffle(s.available_cells);
            
            var base_cell = s.available_cells[0];
            var lx = base_cell[0];
            var ly = base_cell[1];
            array_push(all_occupied_cells, [sx, sy, lx, ly]);
            array_delete(s.available_cells, 0, 1);

            var base = Starbase();
            base.sx = sx;
            base.sy = sy;
            base.lx = lx;
            base.ly = ly;
            //base.energy = irandom_range(9000, 15000);
            base.num = base_count;
            array_push(global.allbases, base);
            base_count++;

            global.galaxy[sx][sy] = s;
        }
    }
    return base_count;
}

/// @description: Places stars, enforcing one per row/column first, then two, etc.
function place_stars(all_occupied_cells) {
    for (var sx = 0; sx < 8; sx++) {
        for (var sy = 0; sy < 8; sy++) {
            var s = global.galaxy[sx][sy];
            s.starnum = irandom_range(1, global.game.maxstars);
            s.star_positions = [];
            var reserved_cells = []; // Track reserved cells for this sector
            
            // Use boolean arrays for quick row/col checks
            var used_rows = array_create(8, false); // ly used?
            var used_cols = array_create(8, false); // lx used?

            var row_counts = array_create(8, 0); // Stars per row (ly)
            var col_counts = array_create(8, 0); // Stars per column (lx)

            var tries = 0;
            while (array_length(s.star_positions) < s.starnum && tries < 100 && array_length(s.available_cells) > 0) {
                // Find valid candidates
                var valid_candidates = [];
                for (var i = 0; i < array_length(s.available_cells); i++) {
                    var lx = s.available_cells[i][0];
                    var ly = s.available_cells[i][1];

                    // For first 8 stars, enforce unique row/column
                    if (array_length(s.star_positions) < 8) {
                        if (used_rows[ly] || used_cols[lx]) {
                            continue;
                        }
                    }
                    
                    // Check distance to all placed stars and enemies
                    var too_close = false;
                    for (var j = 0; j < array_length(s.star_positions); j++) {
                        var star = s.star_positions[j];
                        var dx = star[0] - lx;
                        var dy = star[1] - ly;
                        if (abs(dx) <= 1 && abs(dy) <= 1) {
                            too_close = true;
                            break;
                        }
                    }
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

                    if (!too_close) {
                        array_push(valid_candidates, [lx, ly, i, row_counts[ly], col_counts[lx]]);
                    }
                }

                if (array_length(valid_candidates) == 0) {
                    tries++;
                    continue;
                }

                // Prioritize candidates with minimal row+column counts
                var min_count = 999;
                var best_candidates = [];
                for (var i = 0; i < array_length(valid_candidates); i++) {
                    var count = valid_candidates[i][3] + valid_candidates[i][4]; // row_count + col_count
                    if (count < min_count) {
                        best_candidates = [valid_candidates[i]];
                        min_count = count;
                    } else if (count == min_count) {
                        array_push(best_candidates, valid_candidates[i]);
                    }
                }

                // Select a random best candidate
                var choice = best_candidates[irandom(array_length(best_candidates) - 1)];
                var lx = choice[0];
                var ly = choice[1];
                var candidate_index = choice[2];

                // Place star
                var candidate = [lx, ly];
                array_push(s.star_positions, candidate);
                if (array_length(s.star_positions) <= 8) {
                    used_rows[ly] = true;
                    used_cols[lx] = true;
                }
                row_counts[ly]++;
                col_counts[lx]++;
                array_push(all_occupied_cells, [sx, sy, lx, ly]); // Track star position

                // Reserve neighbors and track them
                for (var dx = -1; dx <= 1; dx++) {
                    for (var dy = -1; dy <= 1; dy++) {
                        var nx = lx + dx;
                        var ny = ly + dy;
                        if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                            if (!has_coord(reserved_cells, nx, ny)) {
                                array_push(reserved_cells, [nx, ny]);
                            }
                            remove_coord(s.available_cells, nx, ny);
                        }
                    }
                }
                array_delete(s.available_cells, candidate_index, 1);
                tries = 0;
            }

            // Build sector_occupied from all_occupied_cells
            var sector_occupied = [];
            for (var i = 0; i < array_length(all_occupied_cells); i++) {
                if (all_occupied_cells[i][0] == sx && all_occupied_cells[i][1] == sy) {
                    array_push(sector_occupied, [all_occupied_cells[i][2], all_occupied_cells[i][3]]);
                }
            }

            // Restore reserved cells, excluding all occupied positions
            s = restore_reserved_cells(s, reserved_cells, sector_occupied);
            global.galaxy[sx][sy] = s;
        }
    }
}


/// @description: Places player and restores reserved cells
function place_player(all_occupied_cells) {
    var sectors = [];
    for (var sx = 0; sx < 8; sx++) {
        for (var sy = 0; sy < 8; sy++) {
            if (array_length(global.galaxy[sx][sy].available_cells) > 0) {
                array_push(sectors, [sx, sy]);
            }
        }
    }

    sectors = array_shuffle(sectors);

    for (var attempt = 0; attempt < array_length(sectors); attempt++) {
        var sx = sectors[attempt][0];
        var sy = sectors[attempt][1];
        var sector = global.galaxy[sx][sy];

        sector.available_cells = array_shuffle(sector.available_cells);

        var reserved_cells = [];
        for (var i = 0; i < array_length(sector.available_cells); i++) {
            var lx = sector.available_cells[i][0];
            var ly = sector.available_cells[i][1];

            if (has_clearance(sector.available_cells, lx, ly, 3)) {
                global.ent.sx = sx;
                global.ent.sy = sy;
                global.ent.lx = lx;
                global.ent.ly = ly;
                sector.seen = true;

                // Reserve neighbors and track them
                for (var dx = -1; dx <= 1; dx++) {
                    for (var dy = -1; dy <= 1; dy++) {
                        var nx = lx + dx;
                        var ny = ly + dy;
                        if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                            if (!has_coord(reserved_cells, nx, ny)) {
                                array_push(reserved_cells, [nx, ny]);
                            }
                            remove_coord(sector.available_cells, nx, ny);
                        }
                    }
                }

                // Add player cell back
                if (!has_coord(sector.available_cells, lx, ly)) {
                    array_push(sector.available_cells, [lx, ly]);
                }

                // Restore reserved cells, excluding occupied ones
                var sector_occupied = [];
                for (var j = 0; j < array_length(all_occupied_cells); j++) {
                    if (all_occupied_cells[j][0] == sx && all_occupied_cells[j][1] == sy) {
                        array_push(sector_occupied, [all_occupied_cells[j][2], all_occupied_cells[j][3]]);
                    }
                }
                sector = restore_reserved_cells(sector, reserved_cells, sector_occupied);

                global.galaxy[sx][sy] = sector;

                show_debug_message("Player placed at sector [" + string(sx) + "," + string(sy) + "] cell [" + string(lx) + "," + string(ly) + "]");
                return;
            }
        }
    }

    show_debug_message("Failed to place player with proper clearance.");
}

/// @description: Generates the game map and populates sectors
function generate_galaxy() {
    randomize();
	global.game.difficulty = global.difficulty;
    global.game.totalbases = max(1, 5 - global.game.difficulty);
    global.game.initenemies = 17 + (global.game.difficulty * 3) + irandom_range(0, 5);
    
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
                    array_push(s.available_cells, [lx, ly]);
                }
            }
        }
    }
    
    // Place enemies, starbases, stars, player
    enemy_count = place_enemies(enemy_count, global.game.initenemies, all_occupied_cells);
    global.game.totalenemies = enemy_count;
    
    if (enemy_count != global.game.initenemies) {
        show_debug_message("Enemy count mismatch: Expected " + string(global.game.initenemies) + ", placed " + string(enemy_count));
		game_restart();
    }
    
    base_count = place_starbases(base_count, global.game.totalbases, all_occupied_cells);
    place_stars(all_occupied_cells);
    place_player(all_occupied_cells);
    
    // Validate available_cells
    validate_available_cells(all_occupied_cells);
    
    debug_galaxy();
}

/// @description: Returns the contents of the galaxy map
function get_galaxy_data() {
    if (!is_array(global.galaxy)) return [];

    var width = array_length(global.galaxy);
    if (width == 0) return [];

    var height = array_length(global.galaxy[0]);
    var data = array_create(width * height, "***");

    for (var sx = 0; sx < width; sx++) {
        var row = global.galaxy[sx];
        if (!is_array(row)) continue;

        var row_height = array_length(row);
        for (var sy = 0; sy < row_height; sy++) {
            var sector = get_sector_data(sx, sy);
            var index = sy * width + sx;

            if (sector.seen) {
                if (sector.enemynum >= 0) {
                    data[index] = string(sector.enemynum) + string(sector.basenum) + string(sector.starnum);
                }
            }
        }
    }

    return data;
}

/// @description: Returns true if cell at (lx, ly) has at least `required` neighbors in `cell_array`.
function has_clearance(cell_array, lx, ly, required) {
    var count = 0;
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            var nx = lx + dx;
            var ny = ly + dy;
            if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                if (has_coord(cell_array, nx, ny)) {
                    count++;
                    if (count >= required) return true;
                }
            }
        }
    }
    return false;
}

/// @description: Returns true if `cell_array` contains the coordinate (lx, ly) in sector (sx, sy).
function has_coord(cell_array, lx, ly, sx=undefined, sy=undefined) {
    for (var i = 0; i < array_length(cell_array); i++) {
        if (sx == undefined && sy == undefined) {
            if (array_length(cell_array[i]) == 2 && cell_array[i][0] == lx && cell_array[i][1] == ly) {
                return true;
            }
        } else {
            if (array_length(cell_array[i]) == 4 && 
                cell_array[i][0] == sx && cell_array[i][1] == sy && 
                cell_array[i][2] == lx && cell_array[i][3] == ly) {
                return true;
            }
        }
    }
    return false;
}

/// @description: Removes the coordinate (lx, ly) from `cell_array` if found.
function remove_coord(cell_array, lx, ly) {
    for (var i = 0; i < array_length(cell_array); i++) {
        if (cell_array[i][0] == lx && cell_array[i][1] == ly) {
            array_delete(cell_array, i, 1);
            return;
        }
    }
}

/// @description: Ensures no occupied cells are in available_cells
function validate_available_cells(all_occupied_cells) {
    for (var sx = 0; sx < 8; sx++) {
        for (var sy = 0; sy < 8; sy++) {
            var s = global.galaxy[sx][sy];
            for (var i = 0; i < array_length(s.available_cells); i++) {
                var lx = s.available_cells[i][0];
                var ly = s.available_cells[i][1];
                if (has_coord(all_occupied_cells, lx, ly, sx, sy)) {
                    show_debug_message("Error: Occupied cell [" + string(lx) + "," + string(ly) + "] in sector [" + string(sx) + "," + string(sy) + "] is in available_cells.");
                }
            }
        }
    }
}

/// @description: Removes the cell and all its neighbors from `cell_array`.
function reserve_neighbors(cell_array, lx, ly) {
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            var nx = lx + dx;
            var ny = ly + dy;
            if (nx >= 0 && nx < 8 && ny >= 0 && ny < 8) {
                remove_coord(cell_array, nx, ny);
            }
        }
    }
}

/// @description: Restores reserved cells to available_cells, excluding occupied cells
function restore_reserved_cells(sector, reserved_cells, occupied_cells) {
    for (var i = 0; i < array_length(reserved_cells); i++) {
        var cell = reserved_cells[i];
        var lx = cell[0];
        var ly = cell[1];
        if (!has_coord(occupied_cells, lx, ly) && // Not occupied by anything
            !has_coord(sector.available_cells, lx, ly)) { // Not already in available_cells
            array_push(sector.available_cells, [lx, ly]);
        }
    }
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
                    array_push(global.galaxy[sx][sy].available_cells, [lx, ly]);
                }
            }
        }
    }
}

/// @description: Convert cells to string key
function cell_to_str(cx, cy) {
	return string(cx) + "," + string(cy);
}