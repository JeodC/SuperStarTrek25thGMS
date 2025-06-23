if (room == rm_endgame && global.game.state == State.Credits) {
    draw_credits();
}

function draw_credits() {
    var wrap = 180; // Max pixel width for wrapping
    var spacing = 8;
    var color = global.t_colors.yellow;

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
		
    // Draw each credit line
	for (var i = 0; i < array_length(credits_lines); i++) {
		var text = credits_lines[i].text;
		var y_pos = credits_lines[i].y;
		draw_set_color(color);
		draw_text_ext(tx, y_pos, text, spacing, wrap);
	}
	
	// If credits finished
	if (credits_finished) {
	    line_text = lang_get("intro.new8");
		draw_set_color(c_white);
		draw_set_halign(fa_center);
	    draw_text_ext(160, 140, line_text, spacing, wrap);
		draw_set_halign(fa_left);
		draw_set_color(global.t_colors.yellow);
	}
		
    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}