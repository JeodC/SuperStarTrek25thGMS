// @obj_controller_ui_Step
/// @description Manages active buttons

switch (global.game.state) {
    case State.Title:
	global.inputmode.mode = InputMode.UI;
        global.active_buttons = global.title_buttons;
        global.options_buttons_created = false;
        break;
    case State.OptMenu:
		global.inputmode.mode = InputMode.UI;
        global.active_buttons = global.options_buttons;
        break;
}

// Check if we came from the credits
if (from_credits) {
	create_title_buttons();
	from_credits = false;
}