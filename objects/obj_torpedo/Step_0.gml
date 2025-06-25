/// @description obj_torpedo Step Event - Move, check 8x8 grid boundaries, and
/// range
// Skip checks on first step to avoid immediate destruction
if (first_step) {
  first_step = false;
  exit;
}

global.busy = true;

// Map parameters
var map_offset_x = 121;
var map_offset_y = 31;
var size_cell_x = 10;
var size_cell_y = 9;

// Update grid position based on pixel position
old_grid_x = grid_x;
old_grid_y = grid_y;
grid_x = floor((x - map_offset_x) / size_cell_x);
grid_y = floor((y - map_offset_y) / size_cell_y);

// Update distance traveled (approximate grid distance)
distance_traveled += speed / max(size_cell_x, size_cell_y);

// Loop through local_objects to find a matching cell
var objects = obj_controller_player.local_objects;
for (var i = 0; i < array_length(objects); i++) {
  var obj = objects[i];
  if (is_struct(obj) && obj.lx == grid_x && obj.ly == grid_y) {
    switch (obj.type) {
    case "base":
      queue_dialog(Speaker.Chekov, "torpedo.hitbase");
      destroy_reason =
          "hit base at grid (" + string(grid_x) + ", " + string(grid_y) + ")";
      break;
    case "enemy":
      destroy_enemy(obj.index);
      dialog_condition();
      destroy_reason =
          "hit enemy at grid (" + string(grid_x) + ", " + string(grid_y) + ")";
      break;
    case "star":
      queue_dialog(Speaker.Chekov, "torpedo.hitstar");
      destroy_reason =
          "hit star at grid (" + string(grid_x) + ", " + string(grid_y) + ")";
      break;
    }
    break; // Stop after first match
  }
}

// Check conditions for destruction
//   "torpedo.missed": "Captain, spread missed, sir.",
if (grid_x < 0 || grid_x > 7 || grid_y < 0 || grid_y > 7) {
  queue_dialog(Speaker.Chekov, "torpedo.missed");
  destroy_reason = "left the sector.";
}

// Destroy if any condition is met
if (destroy_reason != "") {
  show_debug_message("Torpedo " + destroy_reason);
  global.inputmode.type = undefined;
  global.inputmode.mode = InputMode.Bridge;
  obj_controller_player.display = Reports.Default;
  instance_destroy();
}