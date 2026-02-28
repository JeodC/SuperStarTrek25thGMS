/// scr_effects
/// helper functions and special effects

/// @description: Returns an integer 0-3 representing direction based on vector dx, dy
/// @param {real} dx: Horizontal component of the vector
/// @param {real} dy: Vertical component of the vector
function calculate_direction(dx, dy) {
  if (dx == 0 && dy == 0)
    return 0; // default up

  if (abs(dx) > abs(dy)) {
    if (dx > 0)
      return 1; // right
    else
      return 3; // left
  } else {
    if (dy < 0)
      return 0; // up
    else
      return 2; // down
  }
}

/// @description: Returns a color based on a passed value
/// @param {real} value: Value to check against
function get_color(value) {
  if (is_undefined(value))
    return c_white;
  if (value == 100)
    return global.t_colors.green;
  if (value >= 50)
    return global.t_colors.yellow;
  return global.t_colors.red;
}

/// @description: Gets the index of a value in an array. Returns -1 if not found.
/// @param {array} arr: The array to search
/// @param {any} val: The value to search for
function array_index_of(arr, val) {
  for (var i = 0; i < array_length(arr); i++) {
    if (arr[i] == val)
      return i;
  }
  return -1;
}

/// @description: Finds path from start to goal using BFS on walkable cells
/// @param {real} start_x: Starting local X coordinate (0 to 7)
/// @param {real} start_y: Starting local Y coordinate (0 to 7)
/// @param {real} goal_x: Goal local X coordinate (0 to 7)
/// @param {real} goal_y: Goal local Y coordinate (0 to 7)
/// @param {struct} sector: Sector struct containing available_cells array
/// @return {array|undefined} Path array of [x, y] steps if found, otherwise undefined
function find_path(start_x, start_y, goal_x, goal_y, sector) {
  // Validate inputs and sector
  if (!is_array(sector.available_cells)) {
    return undefined;
  }
  if (start_x < 0 || start_x > 7 || start_y < 0 || start_y > 7 || goal_x < 0 ||
      goal_x > 7 || goal_y < 0 || goal_y > 7) {
    return undefined;
  }

  // Create walkable grid (8x8, 0 = unwalkable, 1 = walkable)
  var walkable_grid = ds_grid_create(8, 8);
  ds_grid_clear(walkable_grid, 0);
  for (var i = 0; i < array_length(sector.available_cells); i++) {
    var c = sector.available_cells[i];
    if (c[0] >= 0 && c[0] < 8 && c[1] >= 0 && c[1] < 8) {
      ds_grid_set(walkable_grid, c[0], c[1], 1);
    }
  }

  // Check if start and goal are walkable
  var start_walkable = ds_grid_get(walkable_grid, start_x, start_y);
  var goal_walkable = ds_grid_get(walkable_grid, goal_x, goal_y);
  if (!start_walkable || !goal_walkable) {
    ds_grid_destroy(walkable_grid);
    return undefined;
  }

  // BFS setup
  var queue = ds_queue_create();
  var came_from = ds_map_create();
  var start_key = string(start_x) + "," + string(start_y);
  ds_queue_enqueue(queue, [ start_x, start_y ]);
        came_from[? start_key] = undefined;

        while (!ds_queue_empty(queue)) {
          var current = ds_queue_dequeue(queue);
          var cx = current[0];
          var cy = current[1];

          // Reached goal
          if (cx == goal_x && cy == goal_y) {
            var path = [];
            var cur_key = string(cx) + "," + string(cy);
            while (cur_key != start_key) {
              array_insert(path, 0, [ cx, cy ]);
                                var prev = came_from[? cur_key];
                                cx = prev[0];
                                cy = prev[1];
                                cur_key = string(cx) + "," + string(cy);
            }
            array_insert(path, 0, [ start_x, start_y ]);

            ds_queue_destroy(queue);
            ds_map_destroy(came_from);
            ds_grid_destroy(walkable_grid);
            return path;
          }

          // Check neighbors (up, right, down, left)
          var neighbors = [[cx, cy - 1], // up
                           [cx + 1, cy], // right
                           [cx, cy + 1], // down
                           [cx - 1, cy]  // left
          ];

          for (var i = 0; i < 4; i++) {
            var nx = neighbors[i][0];
            var ny = neighbors[i][1];

            // Skip if out of bounds
            if (nx < 0 || nx > 7 || ny < 0 || ny > 7)
              continue;

            var nkey = string(nx) + "," + string(ny);
            if (ds_map_exists(came_from, nkey))
              continue; // already visited

            // Check walkability
            if (!ds_grid_get(walkable_grid, nx, ny))
              continue;

            ds_queue_enqueue(queue, [ nx, ny ]);
                        came_from[? nkey] = [cx, cy];
          }
        }

        // No path found
        ds_queue_destroy(queue);
        ds_map_destroy(came_from);
        ds_grid_destroy(walkable_grid);
        return undefined;
}

/// @description: Draws an animated sprite that pauses on the last frame before looping.
/// @param {any} spr: The sprite to draw
/// @param {real} x: X position
/// @param {real} y: Y position
/// @param {real} anim_speed: Animation speed (frames per step)
/// @param {real} pause_steps: Steps to pause on the last frame
/// @param {struct} state: Animation state (caller-owned)
function draw_animation(spr, x, y, anim_speed, pause_steps, state) {
  var total_frames = sprite_get_number(spr);

  if (!is_struct(state)) {
    show_debug_message("Can't animate " + string(spr) + "!");
    return;
  }

  // Initialize if needed
  if (!variable_struct_exists(state, "frame"))
    state.frame = 0;
  if (!variable_struct_exists(state, "timer"))
    state.timer = 0;
  if (!variable_struct_exists(state, "paused"))
    state.paused = false;

  // Animation logic
  if (!state.paused) {
    state.timer += anim_speed;
    if (state.timer >= 1) {
      state.timer -= 1;
      state.frame += 1;

      if (state.frame >= total_frames) {
        state.frame = total_frames - 1;
        state.paused = true;
        state.timer = 0;
      }
    }
  } else {
    state.timer += 1;
    if (state.timer >= pause_steps) {
      state.frame = 0;
      state.timer = 0;
      state.paused = false;
    }
  }

  // Draw the current frame
  draw_sprite(spr, state.frame, x, y);
}

/// @description: Generates particles at position (x,y) within this obj_particle instance
/// @param {real} px: X coordinate
/// @param {real} py: Y coordinate
/// @param {real} r: Max radius of particles
/// @param {real} num: Number of particles to spawn
/// @param {real} speed_factor: Multiplier for velocity (optional)
function generate_particles(px, py, r, num, speed_factor = 1) {
  if ((is_array(particles)) && num > array_length(particles))
    num = array_length(particles);

  var count = 0;
  for (var i = 0; i < array_length(particles); i++) {
    if (!particles[i].alive) {
      var p = particles[i];
      p.cx = px;
      p.cy = py;
      p.vx = random_range(-1.0, 1.0) * speed_factor;
      p.vy = random_range(-1.0, 1.0) * speed_factor;
      p.mass = random_range(0.5, 2.5);
      p.r = random_range(0.5, r);
      p.r_i = p.r;
      p.alive = true;

      count++;
      if (count >= num)
        break;
    }
  }
}

/// @description: Creates a particle explosion at sector cell (cx, cy)
/// @param {real} cx: Cell X coordinate (0-based)
/// @param {real} cy: Cell Y coordinate (0-based)
/// @param {real} speed_factor: Optional speed multiplier for particles
function particle_explosion(cx, cy, speed_factor = 1) {
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  var px = map_offset_x + cx * size_cell_x + size_cell_x / 2;
  var py = map_offset_y + cy * size_cell_y + size_cell_y / 2;

  var inst = instance_create_layer(0, 0, "Overlay", obj_particle);
  inst.explosion_timer = 500;
  inst.speed_factor = speed_factor;
  with(inst) { generate_particles(px, py, 5.0, particles_count, speed_factor); }
}

/// @description: Draws a line between the centers of two sector cells
/// @param {any} color: Color to draw the line with
/// @param {real} x1: Source cell X (0–7)
/// @param {real} y1: Source cell Y (0–7)
/// @param {real} x2: Destination cell X (0-7)
/// @param {real} y2: Destination cell Y (0-7)
function draw_phaserline(color, x1, y1, x2, y2) {
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  // Calculate center positions of the source and target cells
  var px1 = map_offset_x + x1 * size_cell_x + size_cell_x / 2;
  var py1 = map_offset_y + y1 * size_cell_y + size_cell_y / 2;
  var px2 = map_offset_x + x2 * size_cell_x + size_cell_x / 2;
  var py2 = map_offset_y + y2 * size_cell_y + size_cell_y / 2;

  draw_set_color(color);
  draw_line(px1, py1, px2, py2);
}