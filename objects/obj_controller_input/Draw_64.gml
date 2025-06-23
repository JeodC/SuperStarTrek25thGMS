// @obj_controller_input_DrawGUI
/// @description: Handles inputs based on mode

if (global.busy == false && global.inputmode.mode != InputMode.Torpedoes || global.inputmode.mode == InputMode.UI) {
	draw_sprite(spr_cursor, 0, global.input.mx, global.input.my);
}
else if (global.busy == true && global.inputmode.mode != InputMode.Torpedoes) {
	draw_sprite(spr_cursor, 1, global.input.mx, global.input.my);
}