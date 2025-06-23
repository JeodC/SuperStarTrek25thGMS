// @obj_controller_ui_Create
/// @description: Initialization and UI

// Initialize
scr_init();
global.title_buttons = [];
global.options_buttons = [];
global.slider_buttons = [];

global.options_buttons_created = false;

// Local
text = "";
from_credits = false;
surf = -1;

create_title_buttons();
global.active_buttons = global.title_buttons;

audio_play_sound(mus_title, 0, false);