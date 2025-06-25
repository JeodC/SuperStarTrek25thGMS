/// @obj_controller_dialog_DrawGUI
/// @description: Handles text processing and display

var wrap = 180;
var spacing = 8;

// Only draw text if we have text available to draw and the audio mode allows it
if (show_text && text_index < array_length(text_handle) &&
    global.audio_mode != 1) {
  var line = text_handle[text_index];

  if (is_struct(line) && variable_struct_exists(line, "speaker") &&
      variable_struct_exists(line, "line")) {
    var speaker_id = line.speaker;
    var text = string(line.line);

    var speaker_data;
    if (is_array(speakers) && speaker_id >= 0 &&
        speaker_id < array_length(speakers)) {
      speaker_data = speakers[speaker_id];
    } else {
      speaker_data = {x : 32, y : 32, color : c_white};
    }

    var tx = speaker_data.x;
    var ty = speaker_data.y;
    var color = speaker_data.color;

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