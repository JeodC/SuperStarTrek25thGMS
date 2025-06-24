/// @obj_ui_button_Draw
/// @description: Instances of buttons that change their text dynamically

// Draw a blue border when pressed
if (pressed || menu_id == global.menu_selected) {
    draw_set_color(global.t_colors.blue);
    draw_rectangle(x - 1, y - 1, x + sprite_width, y + sprite_height, false);
	if (!instance_exists(obj_fade)) {
		instance_create_layer(0, 0, "Overlay", obj_fade);
	}
	pressed = false;
}

// Highlight when hovered or keyboard selected
if (hovered || is_selected) {
    image_index = 1;  // Highlighted sprite
} else {
    image_index = 0;  // Normal sprite
}

draw_self();

draw_set_font(fnt_ship);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
if (menu_id == "ui.continue") {
	draw_set_color(continue_color);
}
else {
	draw_set_color(c_yellow);
}
draw_text(x + sprite_width / 2, y + sprite_height / 2, text);

if (menu_id == "ui.langleft") {
	draw_text(self.x + 56, self.y + 8, lang_get("lang." + global.lang));
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);