/// @description: Draws the text when hovering over an eligible region in the
/// Bridge play area
function draw_hover_text() {
  var state_name = "";
  var label_x = 160;
  var label_y = 106;
  draw_set_color(global.t_colors.blue);

  var hover = obj_controller_input.hover_state;
  var enemy_info = "";

  // Find the hovered region
  for (var i = 0; i < array_length(obj_controller_input.all_regions); i++) {
    var r = obj_controller_input.all_regions[i];
    if (r.state == hover) {
      if (hover >= HoverState.Enemy && hover < HoverState.Enemy + array_length(instance_find(obj_controller_player, 0).local_enemies)) {
        var player = instance_find(obj_controller_player, 0);
        if (player) {
          // Calculate the local enemy index from hover state
          var local_enemy_idx = hover - HoverState.Enemy;
          
          // Defensive check
          if (local_enemy_idx >= 0 && local_enemy_idx < array_length(player.local_enemies)) {
            var enemy_index = player.local_enemies[local_enemy_idx]; // global index
            if (enemy_index >= 0 && enemy_index < array_length(global.allenemies)) {
              var enemy = global.allenemies[enemy_index];
              if (is_struct(enemy)) {
                enemy_info = "(" + string(enemy.lx) + "," + string(enemy.ly) + ")";
              }
            }
          }
        }
      }
      break;
    }
  }

  switch (obj_controller_input.hover_state) {
  case HoverState.None:
    state_name = "";
    break;
  case HoverState.Shields:
    state_name = lang_get("hotspot.shields");
    break;
  case HoverState.Energy:
    state_name = lang_get("hotspot.status");
    break;
  case HoverState.DamageStatus:
    state_name = lang_get("hotspot.damage");
    break;
  case HoverState.ScottStatus:
    state_name = lang_get("hotspot.scott");
    break;
  case HoverState.WarpSpeed:
    state_name = lang_get("hotspot.warp");
    break;
  case HoverState.GalacticMap:
    state_name = lang_get("hotspot.map");
    break;
  case HoverState.ImpulseSpeed:
    state_name = lang_get("hotspot.impulse");
    break;
  case HoverState.LongRangeSensors:
    state_name = lang_get("hotspot.lrs");
    break;
  case HoverState.Phasers:
    state_name = lang_get("hotspot.phasers");
    break;
  case HoverState.Torpedoes:
    state_name = lang_get("hotspot.torpedoes");
    break;
  case HoverState.MissionStatus:
    state_name = lang_get("hotspot.mission");
    break;
  case HoverState.DockingProcedures:
    state_name = lang_get("hotspot.docking");
    break;
  case HoverState.Options:
    state_name = lang_get("hotspot.options");
    break;
  case HoverState.Help:
    state_name = lang_get("hotspot.help");
    break;
  default:
    if (obj_controller_input.hover_state >= HoverState.Enemy) {
      state_name = lang_get("hotspot.enemy") + " " + enemy_info;
      break;
    }
  }

  var text = state_name;
  var text_width = string_width(text);
  draw_set_font(fnt_ship);
  draw_text(label_x - text_width * 0.5, label_y, text);
}

/// @description: Draw two dots orbiting the player ship for torpedo targeting
function draw_torpedo_reticle() {
  var angle = obj_controller_player.torp_angle;

  // Map parameters (sector grid)
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  // Sector grid dimensions
  var grid_width = 8;  // 8 cells in x direction
  var grid_height = 8; // 8 cells in y direction

  // Calculate sector grid boundaries in pixels
  var grid_min_x = map_offset_x;
  var grid_max_x = map_offset_x + grid_width * size_cell_x;
  var grid_min_y = map_offset_y;
  var grid_max_y = map_offset_y + grid_height * size_cell_y;

  // Ship logical grid coordinates
  var lx = global.ent.lx;
  var ly = global.ent.ly;

  // Pixel center of the ship's grid cell
  var cx = map_offset_x + lx * size_cell_x + size_cell_x / 2;
  var cy = map_offset_y + ly * size_cell_y + size_cell_y / 2;

  // Radii for the two dots
  var radius1 = 8;
  var radius2 = 13;

  // First dot (inner)
  var dx1 = cx + lengthdir_x(radius1, angle);
  var dy1 = cy + lengthdir_y(radius1, angle);

  // Second dot (outer)
  var dx2 = cx + lengthdir_x(radius2, angle);
  var dy2 = cy + lengthdir_y(radius2, angle);

  draw_set_color(global.t_colors.blue);

  // Draw inner dot if within sector grid boundaries
  if (dx1 >= grid_min_x && dx1 < grid_max_x && dy1 >= grid_min_y &&
      dy1 < grid_max_y) {
    draw_circle(dx1, dy1, 1, false);
  }

  if (dx2 >= grid_min_x && dx2 < grid_max_x && dy2 >= grid_min_y &&
      dy2 < grid_max_y) {
    draw_circle(dx2, dy2, 1, false);
  }

  // Convert angle (0–360) to range 1.0–8.9
  var n = (angle mod 360) / 360 * 8.0 + 1.0;

  // Clamp to 1 decimal place
  n = round(n * 10) / 10;

  // Draw text at fixed screen location (e.g. lower center)
  var label_x = 160;
  var label_y = 106;
  var f = string_format(n, 1, 1);
  var text = "Press Left/Right (" + string(f) + ")";
  var text_width = string_width(text);
  draw_text(label_x - text_width * 0.5, label_y, text);
}

/// @description: Draws the ui box for shields/phasers adjustment
function draw_level_hud() {
  var key = "";
  var bx = 264, by = 58;
  var type = global.inputmode.type;
  switch (type) {
  case HoverState.Shields:
    key = "ui.shieldlevel";
    break;
  case HoverState.Phasers:
    key = "ui.phaserlevel";
    break;
  default:
    return;
  }
  draw_sprite(spr_bg_hud_level, 0, 56, 48);
  draw_sprite_ext(spr_btn_arrow, 0, bx, by - 1, 1, -1, 0, c_white, 1); // Up
  draw_sprite(spr_btn_arrow, 0, bx, by);                               // Down
  draw_sprite(spr_btn_confirm, 0, bx, by + 18);
  draw_set_color(global.t_colors.yellow);
  draw_text(60, 55, lang_format(key, {energy : global.ent.energy}));
}

/// @description: Draws the dynamic numbers in conjunction with draw_level_hud
function draw_numbers() {
  if (global.inputmode.mode != InputMode.Manage) {
    return;
  }
  var value = global.inputmode.tmp_new;
  var max_value = global.ent.energy;
  draw_set_color(global.t_colors.yellow);
  draw_text(60, 65, string(value) + "/" + string(max_value));
}

/// @description Draws the contents of the current sector
function draw_sector_contents() {
  // Screen is broken
  if (global.ent.system.srs < 50) {
    var sx = 70, sy = 30;
    draw_sprite(spr_grid_broken, 0, sx, sy);
    return;
  }

  // Map parameters
  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  var current_sector = global.galaxy[global.ent.sx][global.ent.sy];

  // Draw stars
  for (var i = 0; i < array_length(current_sector.star_positions); i++) {
    var pos = current_sector.star_positions[i];
    var screen_x = map_offset_x + pos[0] * size_cell_x;
    var screen_y = map_offset_y + pos[1] * size_cell_y;
    draw_sprite(spr_grid_star, 0, screen_x, screen_y);
  }

  // Draw starbase
  if (current_sector.basenum > 0) {
    for (var i = 0; i < array_length(global.allbases); i++) {
      var base = global.allbases[i];
      if (!is_undefined(base) && is_struct(base) && base.sx == global.ent.sx &&
          base.sy == global.ent.sy) {
        var screen_x = map_offset_x + base.lx * size_cell_x;
        var screen_y = map_offset_y + base.ly * size_cell_y;
        draw_sprite(spr_grid_starbase, 0, screen_x, screen_y);
        break;
      }
    }
  }

  // Draw enemies
  var enemy_count = current_sector.enemynum;
  for (var i = 0; i < array_length(global.allenemies); i++) {
    var enemy = global.allenemies[i];

    // Safety check -- if an enemy was destroyed they wouldn't be present to
    // draw
    if (!is_undefined(enemy) && is_struct(enemy)) {
      if (enemy.sx == global.ent.sx && enemy.sy == global.ent.sy &&
          enemy_count > 0) {
        var screen_x = map_offset_x + enemy.lx * size_cell_x;
        var screen_y = map_offset_y + enemy.ly * size_cell_y;
        var subimage = enemy.dir;
        draw_sprite(spr_grid_enemy, subimage, screen_x, screen_y);
        enemy_count--;
        if (enemy_count == 0)
          break;
      }
    }
  }

  // Draw player (animated or static)
  var pos_x =
      global.ent.animating_impulse ? global.ent.current_x : global.ent.lx;
  var pos_y =
      global.ent.animating_impulse ? global.ent.current_y : global.ent.ly;
  var subimage = global.ent.dir;

  var screen_x = map_offset_x + pos_x * size_cell_x;
  var screen_y = map_offset_y + pos_y * size_cell_y;
  draw_sprite(spr_grid_ship, subimage, screen_x, screen_y);
}

/// @description: Draws the red alert effect when enemies are present
function draw_redalert() {

  // Draw a semitransparent black rectangle
  draw_set_alpha(0.65);
  draw_set_color(c_black);

  var w = display_get_width();
  var h = display_get_height();

  var x1 = 70, y1 = 30;
  var x2 = 247, y2 = 102;

  draw_rectangle(0, 0, w, y1 - 1, false);
  draw_rectangle(0, y2 + 1, w, h, false);
  draw_rectangle(0, y1, x1 - 1, y2, false);
  draw_rectangle(x2 + 1, y1, w, y2, false);

  draw_set_alpha(1);

  // Draw glowing sprites
  draw_sprite(spr_fg_hud_redalert, 0, 0, 0);
  draw_sprite(spr_bg_hud_sign, 0, 0, 0);
}

/// @description: Draws reports to the ship console
function draw_ship_console(report) {
  var sx = 70, sy = 30, gx = 120, gy = 30;
  var label = "", subimage = 0, value;

  // Screen is broken
  if (global.ent.system.srs < 50) {
    draw_sprite(spr_grid_broken, 0, sx, sy);
    return;
  }

  // Brighten grid if used LRS
  if (obj_controller_player.askedforlrs) {
    subimage = 1;
  }

  if (global.ent.condition = Condition.Win) {
    subimage = 2;
  }

  // Populate data array with information
  var data = action_on_screen(report);

  // Draw data as text
  draw_set_font(fnt_ship);
  draw_set_color(c_white);
  var text_y = sy + 6;
  var text_x = sx + 10;
  var padding = 8;

  // Define each label
  var labels = {
    warp : lang_get("device.warp") + ": ",
    srs : lang_get("device.srs") + ": ",
    lrs : lang_get("device.lrs") + ": ",
    phasers : lang_get("device.phasers") + ": ",
    torpedoes : lang_get("device.torpedoes") + ": ",
    navigation : lang_get("device.navigation") + ": ",
    shields : lang_get("device.shields") + ": ",
    energy : lang_get("mission.energy") + ": ",
    shield_energy : lang_get("mission.shields") + ": ",
    available : lang_get("mission.available") + ": ",
    mission_torpedoes : lang_get("mission.torpedoes") + ": ",
    enemies_destroyed : lang_get("mission.enemiesdestroyed") + ": ",
    enemies_left : lang_get("mission.enemiesleft") + ": ",
    days_left : lang_get("mission.daysleft") + ": ",
  };

  // Loop through the labels and get their string length
  var max_label_width = 0;
  var keys = variable_struct_get_names(labels);

  for (var i = 0; i < array_length(keys); i++) {
    value = variable_struct_get(labels, keys[i]);
    max_label_width = max(max_label_width, string_width(value));
  }

  // Get what to draw -- default to aligned x-position
  switch (report) {
  case Reports.Damage:
    label = labels.warp;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.warp_engines));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.warp_engines) + "%");
    text_y += padding;

    label = labels.srs;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.short_range_sensors));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.short_range_sensors) + "%");
    text_y += padding;

    label = labels.lrs;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.long_range_sensors));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.long_range_sensors) + "%");
    text_y += padding;

    label = labels.phasers;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.phaser_controls));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.phaser_controls) + "%");
    text_y += padding;

    label = labels.torpedoes;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.photon_tubes));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.photon_tubes) + "%");
    text_y += padding;

    label = labels.navigation;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.navigation_computer));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.navigation_computer) + "%");
    text_y += padding;

    label = labels.shields;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(get_color(data.shields_controls));
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.shields_controls) + "%");
    break;
  case Reports.Mission:
    label = labels.energy;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.total_energy));
    text_y += padding;

    label = labels.shield_energy;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.energy_to_shields));
    text_y += padding;

    label = labels.available;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.available_energy));
    text_y += padding;

    label = labels.mission_torpedoes;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.torpedoes));
    text_y += padding;

    label = labels.enemies_destroyed;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.enemies_destroyed));
    text_y += padding;

    label = labels.enemies_left;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.enemies_left));
    text_y += padding;

    label = labels.days_left;
    draw_set_color(c_white);
    draw_text(text_x, text_y, label);
    draw_set_color(global.t_colors.yellow);
    draw_text(text_x + max_label_width + padding, text_y,
              string(data.days_remaining));
    draw_set_color(c_white);
    break;
  case Reports.Scan:
    var current_sx = global.ent.sx;
    var current_sy = global.ent.sy;
    text_y = sy + 12;
    text_x = sx + 56;
    padding = 20;

    // Draw 3x3 grid row by row
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        var index = row * 3 + col;
        value = data[index];
        if (value == "")
          value = "***";             // Fallback for empty values
        sx = current_sx + (col - 1); // Map col to dx
        sy = current_sy + (row - 1); // Map row to dy
        var e =
            (value == "***") ? 0 : real(string_char_at(value, 1)); // Extract E
        var b =
            (value == "***") ? 0 : real(string_char_at(value, 2)); // Extract B
        var s =
            (value == "***") ? 0 : real(string_char_at(value, 3)); // Extract S

        // Determine color priority
        var draw_color = c_white;
        if (sx == current_sx && sy == current_sy) {
          draw_color = global.t_colors.yellow; // Current sector
        } else if (e > 0) {
          draw_color = global.t_colors.red; // Has enemies
        } else if (b > 0) {
          draw_color = global.t_colors.blue; // Has base
        }

        // Draw each sector individually with its color
        draw_set_color(draw_color);
        var x_offset = col * (string_width("***") + 5);
        draw_text(text_x + x_offset, text_y, value);
      }
      text_y += padding;
    }
    draw_set_color(c_white);
    break;
  default:
    draw_sprite(spr_bg_grid, subimage, gx, gy);
    break;
  }
}

/// @description: Draws the galaxy map for new sector selection
function draw_galaxy_map() {
  draw_clear(c_black);
  draw_sprite(spr_bg_stars, 0, 0, 0);
  var gx = 30, gy = 22; // Size of each cell
  var ox = 40, oy = 14; // Start of top-left cell

  var current_sx = global.ent.sx;
  var current_sy = global.ent.sy;

  // Get the full galaxy data for all sectors [0-7, 0-7]
  var data = array_create(64, "***");
  for (var sy = 0; sy < 8; sy++) {
    for (var sx = 0; sx < 8; sx++) {
      var idx = sy * 8 + sx;
      var sector = get_sector_data(sx, sy);
      if (sector.enemynum >= 0) {
        data[idx] = string(sector.enemynum) + string(sector.basenum) +
                    string(sector.starnum);
      }
    }
  }

  for (var row = 0; row < 8; row++) {
    for (var col = 0; col < 8; col++) {
      var index = row * 8 + col;
      var value = data[index];

      // Check if sector seen, else "***"
      var sector_seen = global.galaxy[col][row].seen;
      if (!sector_seen) {
        value = "***";
      }
      if (value == "")
        value = "***";

      var e = (value == "***") ? 0 : real(string_char_at(value, 1));
      var b = (value == "***") ? 0 : real(string_char_at(value, 2));
      var s = (value == "***") ? 0 : real(string_char_at(value, 3));

      // Determine color priority
      var draw_color = c_white;
      if (col == current_sx && row == current_sy) {
        draw_color = global.t_colors.yellow; // current sector
      } else if (e > 0) {
        draw_color = global.t_colors.red; // enemies present
      } else if (b > 0) {
        draw_color = global.t_colors.blue; // base present
      }

      draw_set_color(draw_color);

      // Calculate cell top-left corner
      var cell_x = ox + col * gx;
      var cell_y = oy + row * gy;

      // Center the text inside the sector cell
      var tw = string_width(value);
      var th = string_height(value);

      var draw_x = cell_x + (gx / 2) - (tw / 2);
      var draw_y = cell_y + (gy / 2) - (th / 2);

      draw_text(draw_x, draw_y, value);
    }
  }

  // Draw thin gray grid lines for all sectors
  draw_set_color(c_dkgray);
  // Vertical lines
  for (var i = 0; i <= 8; i++) {
    var lx = ox + i * gx;
    draw_line(lx, oy, lx, oy + 8 * gy);
  }
  // Horizontal lines
  for (var j = 0; j <= 8; j++) {
    var ly = oy + j * gy;
    draw_line(ox, ly, ox + 8 * gx, ly);
  }

  // Draw a thin yellow grid line around the currently selected sector
  draw_set_color(global.t_colors.yellow);
  var sel_x = ox + global.inputmode.cursor_x * gx;
  var sel_y = oy + global.inputmode.cursor_y * gy;
  draw_rectangle(sel_x + 1, sel_y + 1, sel_x + gx - 1, sel_y + gy - 1, true);

  draw_set_color(c_white);
}

/// @description: Draws the impulse move selector
function draw_impulse_grid() {
  if (global.inputmode.mode != InputMode.Impulse)
    return;

  var map_offset_x = 121;
  var map_offset_y = 31;
  var size_cell_x = 10;
  var size_cell_y = 9;

  var drawx = map_offset_x + global.inputmode.cursor_x * size_cell_x;
  var drawy = map_offset_y + global.inputmode.cursor_y * size_cell_y;

  draw_sprite(spr_grid_selector, 0, drawx - 1, drawy - 1);
}

/// @description: Draws the enterprise shield, energy, and phasers bars
function draw_energy_bars() {
  var sector = global.galaxy[global.ent.sx][global.ent.sy];
  var shieldsbar =
      clamp((global.ent.shields / global.game.maxenergy) * 100, 0, 100);
  var energybar =
      clamp((global.ent.energy / global.game.maxenergy) * 100, 0, 100);
  var phasersbar =
      clamp((global.ent.phasers / global.game.maxenergy) * 100, 0, 100);

  var shield_col = global.t_colors.green;
  var energy_col = global.t_colors.yellow;
  var phasers_col = global.t_colors.red;

  // Draw healthbars
  draw_healthbar(91, 21, 127, 23, shieldsbar, shield_col, shield_col,
                 shield_col, 0, false, false);
  draw_healthbar(142, 21, 178, 23, energybar, energy_col, energy_col,
                 energy_col, 0, false, false);
  draw_healthbar(191, 21, 227, 23, phasersbar, phasers_col, phasers_col,
                 phasers_col, 0, false, false);

  // Draw shields sprite if active
  draw_sprite(spr_fg_static, (global.ent.shields <= 0), 0, 0);
}

/// @description: Draws the captain's log briefing text
function draw_briefing() {
  var margin = 20;
  var wrap_width = 320 - margin * 2;
  var spacing = 8;
  var ty = margin;

  // Background
  draw_clear(c_black);
  draw_sprite(spr_bg_stars, 0, 0, 0);
  draw_set_color(global.t_colors.yellow);
  draw_set_halign(fa_left);

  // Array of entries: [type, key, {optional format data}]
  var lines = [
    [ "format", "intro.new1", {date : global.game.date} ],
    [ "get", "intro.new2" ],
    [ "format", "intro.new3", {totalenemies : global.game.totalenemies} ],
    [ "format", "intro.new4", {maxdays : global.game.maxdays} ],
    (global.game.totalbases > 1)
        ? [ "format", "intro.new5", {totalbases : global.game.totalbases} ]
        : [ "get", "intro.new6" ],
    [ "get", "intro.new7" ]
  ];

  for (var i = 0; i < array_length(lines); i++) {
    var entry = lines[i];
    var line_text = entry[0] == "format" ? lang_format(entry[1], entry[2])
                                         : lang_get(entry[1]);

    draw_text_ext(margin, ty, line_text, spacing, wrap_width);
    ty += string_height_ext(line_text, spacing, wrap_width) + spacing;
  }

  // Final centered white line
  var final_line = lang_get("intro.new8");
  draw_set_color(c_white);
  draw_set_halign(fa_center);
  draw_text_ext(160, ty, final_line, spacing, wrap_width);

  // Restore
  draw_set_halign(fa_left);
  draw_set_color(global.t_colors.yellow);
}

/// @description: Draws the postgame text
function draw_gameover_text() {
  if (instance_exists(obj_controller_movies)) {
    if (global.ent.condition == Condition.Destroyed) {
      text = lang_get("condition.destroyed2");
    } else if (global.ent.condition == Condition.Stranded &&
               global.ent.system.warp < 10) {
      text = lang_get("condition.stranded4");
    } else if (global.ent.condition == Condition.Stranded) {
      text = lang_get("condition.stranded3");
    } else if (global.ent.condition == Condition.NoTime) {
      text = lang_get("condition.timesup");
    } else if (global.ent.condition == Condition.Win) {
      text = lang_get("condition.win3");
    }

    var wrap = 180; // max pixel width for wrapping
    var spacing = 8;
    var tx = 160;
    var ty = 110;
    var color = global.t_colors.yellow

    // Prevent text from going offscreen horizontally
    var margin = 10;
    var gui_w = display_get_gui_width();

    // Adjust tx for centered text, ensuring text block stays within margins
    var text_left_edge = tx - wrap / 2;
    var text_right_edge = tx + wrap / 2;

    // Clamp tx so the text block's edges stay within margins
    if (text_left_edge < margin) {
      tx += (margin - text_left_edge); // Shift right
    }
    if (text_right_edge > gui_w - margin) {
      tx -= (text_right_edge - (gui_w - margin)); // Shift left
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_top);

    // Draw black outline (1 pixel offset in 4 directions)
    draw_set_color(c_black);
    draw_text_ext(tx - 1, ty, text, spacing, wrap); // Left
    draw_text_ext(tx + 1, ty, text, spacing, wrap); // Right
    draw_text_ext(tx, ty - 1, text, spacing, wrap); // Up
    draw_text_ext(tx, ty + 1, text, spacing, wrap); // Down

    // Draw main text on top
    draw_set_color(color);
    draw_text_ext(tx, ty, text, spacing, wrap);

    // Reset
    draw_set_color(c_yellow);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
  }
}