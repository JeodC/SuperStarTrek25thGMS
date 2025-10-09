/// @description obj_torpedo Step Event - Move, check 8x8 grid boundaries, and range

// Skip checks on first step to avoid immediate destruction on spawn
if (first_step) {
    first_step = false;
    exit;
}

global.busy = true;

// Map parameters for grid conversion
var map_offset_x = 121;
var map_offset_y = 31;
var size_cell_x = 10;
var size_cell_y = 9;

// Update grid position based on pixel position
old_grid_x = grid_x;
old_grid_y = grid_y;
grid_x = floor((x - map_offset_x) / size_cell_x);
grid_y = floor((y - map_offset_y) / size_cell_y);

// Update approximate distance traveled in grid units
distance_traveled += speed / max(size_cell_x, size_cell_y);

// Helper function to check base presence in current sector grid
function check_base_at_cell(sx, sy, lx, ly) {
    var sector = global.galaxy[sx][sy];
    if (sector == undefined) return false;
    if (!variable_struct_exists(sector, "bases")) return false;

    var bases = sector.bases;
    for (var b = 0; b < array_length(bases); b++) {
        var base = bases[b];
        if (is_struct(base) && base.lx == lx && base.ly == ly) {
            return true;
        }
    }
    return false;
}

// Check enemies in current sector at grid cell
function enemy_index_at_cell(sx, sy, lx, ly) {
    for (var i = 0; i < array_length(global.allenemies); i++) {
        var e = global.allenemies[i];
        if (is_struct(e) && e.energy > 0 && e.sx == sx && e.sy == sy && e.lx == lx && e.ly == ly) {
            return i;
        }
    }
    return -1;
}

// Check stars in current sector at grid cell
function star_at_cell(sx, sy, lx, ly) {
    var sector = global.galaxy[sx][sy];
    if (sector == undefined) return false;
    if (!variable_struct_exists(sector, "stars")) return false;

    var stars = sector.stars;
    for (var s = 0; s < array_length(stars); s++) {
        var star = stars[s];
        if (is_struct(star) && star.lx == lx && star.ly == ly) {
            return true;
        }
    }
    return false;
}

// Current sector coordinates
var sx = global.ent.sx;
var sy = global.ent.sy;

// Check for base hit
if (check_base_at_cell(sx, sy, grid_x, grid_y)) {
    queue_dialog(Speaker.Chekov, "torpedo.hitbase");
    destroy_reason = "Torpedo hit base at grid (" + string(grid_x) + ", " + string(grid_y) + ")";
}
// Check for enemy hit
else {
    var enemy_idx = enemy_index_at_cell(sx, sy, grid_x, grid_y);
    if (enemy_idx >= 0) {
        destroy_enemy(enemy_idx);
        get_sector_data();
        dialog_condition();
        destroy_reason = "Torpedo hit enemy at grid (" + string(grid_x) + ", " + string(grid_y) + ")";
    }
}
// Check for star hit
if (destroy_reason == "" && star_at_cell(sx, sy, grid_x, grid_y)) {
    queue_dialog(Speaker.Chekov, "torpedo.hitstar");
    destroy_reason = "Torpedo hit star at grid (" + string(grid_x) + ", " + string(grid_y) + ")";
}

// Check if torpedo left sector boundaries
if (destroy_reason == "" && (grid_x < 0 || grid_x > 7 || grid_y < 0 || grid_y > 7)) {
    queue_dialog(Speaker.Chekov, "torpedo.missed");
    destroy_reason = "Torpedo left the sector";
}

// If any destruction condition met, destroy torpedo instance and cleanup
if (destroy_reason != "") {
    global.inputmode.type = undefined;
    global.inputmode.mode = InputMode.Bridge;
    obj_controller_player.display = Reports.Default;
    instance_destroy();
}