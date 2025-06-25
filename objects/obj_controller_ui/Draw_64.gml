/// @obj_controller_ui_DrawGUI
/// @description: Draw elements based on game state

// Control drawing based on game state
switch (global.game.state) {
case State.Title:
  draw_title_info();
  break;
case State.OptMenu:
  break;
case State.Movie:
  break;
case State.Briefing:
  draw_briefing();
  break;
case State.Intro:
  break;
case State.Loading:
  break;
case State.Playing:
  break;
case State.Win:
case State.Lose:
  draw_gameover_text();
  break;
}

debug_draw();

/// @description: Draws titlescreen info
function draw_title_info() {
  var tx = 240;
  var ty = 150;
  var wrap = 180; // Max pixel width for wrapping
  var spacing = 8;

  // Prevent text from going offscreen horizontally
  var margin = 10;
  var gui_w = display_get_gui_width();

  // Adjust tx for centered text, ensuring text block stays within margins
  var text_left_edge = tx - wrap / 2;
  var text_right_edge = tx + wrap / 2;

  draw_set_halign(fa_center);
  draw_set_valign(fa_top);

  // Draw info
  draw_set_color(global.t_colors.blue);
  var text = lang_get("title.info1");
  draw_outline(tx, ty, text);
  draw_set_color(global.t_colors.blue);
  draw_text_ext(tx, ty, text, spacing, wrap);
  ty += 10;
  text = lang_get("title.info2");
  draw_outline(tx, ty, text);
  draw_set_color(global.t_colors.yellow);
  draw_text_ext(tx, ty, text, spacing, wrap);
  ty += 14;
  text = lang_get("title.info3");
  draw_outline(tx, ty, text);
  draw_set_color(global.t_colors.blue);
  draw_text_ext(tx, ty, text, spacing, wrap);
  ty += 10;
  text = lang_get("title.info4");
  draw_outline(tx, ty, text);
  draw_set_color(global.t_colors.yellow);
  draw_text_ext(tx, ty, text, spacing, wrap);
  ty += 5;
  text = lang_format("title.version", {version : global.version});

  var version_text =
      (is_undefined(global.version) || string(global.version) == "")
          ? "v0.0.0"
          : string(global.version);
  draw_outline(275, 5, text);
  draw_set_color(global.t_colors.yellow);
  draw_text_ext(275, 5, text, spacing, wrap);

  // Reset
  draw_set_halign(fa_left);
  draw_set_valign(fa_top);
}

function draw_outline(tx, ty, text) {
  var wrap = 180; // Max pixel width for wrapping
  var spacing = 8;
  // Draw black outline (1 pixel offset in 4 directions)
  draw_set_color(c_black);
  draw_text_ext(tx - 1, ty, text, spacing, wrap); // Left
  draw_text_ext(tx + 1, ty, text, spacing, wrap); // Right
  draw_text_ext(tx, ty - 1, text, spacing, wrap); // Up
  draw_text_ext(tx, ty + 1, text, spacing, wrap); // Down
}