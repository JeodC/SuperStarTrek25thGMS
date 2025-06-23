// @obj_controller_ui_Draw
/// @description Draws specifics for UI

// Draw black background if using Options menu
if (global.game.state == State.OptMenu) {
	draw_clear(c_black);
	draw_sprite(spr_bg_stars, 0, 0, 0);
}