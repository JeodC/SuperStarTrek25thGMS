/// @obj_ui_button_Step
/// @description: Instances of buttons that change their text dynamically

var buttons = global.active_buttons;

// Determine if this button should be disabled
var is_disabled = false;


// Dynamic shutoff for no existing save
if (menu_id == "ui.continue") {
	can_continue = file_exists("sst25th.dat");
	continue_color = can_continue ? c_yellow : c_grey;
}

if (menu_id == "ui.continue" && !can_continue) {
    is_disabled = true;
}

// Dynamic label for scale
if (menu_id == "ui.scale") {
    sprite_index = spr_btn_rect_long;
	switch (global.scale) {
		case 0: text = lang_get("ui.scale1"); break; // Stretch to fit
		case 1: text = lang_get("ui.scale2"); break; // Integer scale
	}
}

// Dynamic label for subtitles mode
if (menu_id == "ui.subtitles") {
	sprite_index = spr_btn_rect_long;
    switch (global.audio_mode) {
        case 0: text = lang_get("opt.audiomode1"); break;
        case 1: text = lang_get("opt.audiomode2"); break;
        case 2: text = lang_get("opt.audiomode3"); break;
    }
}

// Dynamic label for difficulty
if (menu_id == "ui.difficulty") {
	sprite_index = spr_btn_rect_long;
    switch (global.difficulty) {
        case 1: text = lang_get("opt.diff") + ": " + lang_get("opt.diff1"); break;
        case 2: text = lang_get("opt.diff") + ": " + lang_get("opt.diff2"); break;
        case 3: text = lang_get("opt.diff") + ": " + lang_get("opt.diff3"); break;
		case 4: text = lang_get("opt.diff") + ": " + lang_get("opt.diff4"); break;
    }
}

if (!is_disabled) {
	// Check if this button is selected (via keyboard/gamepad)
	if (is_array(buttons) && global.selected_index >= 0 && global.selected_index < array_length(buttons)) {
	    is_selected = (buttons[global.selected_index] == id);
	}

	// Check if mouse is over this button
	hovered = point_in_rectangle(mouse_x, mouse_y, x, y, x + sprite_width, y + sprite_height);

	// Update highlight and selection index based on input source
	if (hovered) {
	    image_index = 1; // Hover sprite
	    if (global.input.source == InputSource.Mouse) {
	        var idx = array_index_of(buttons, id);
	        if (idx != -1 && global.selected_index != idx) {
	            global.selected_index = idx;
	        }
	    }
	} else {
	    image_index = 0; // Default sprite
	}
}