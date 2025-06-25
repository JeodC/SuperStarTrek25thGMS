/// @obj_controller_dialog_Create
/// @description: Handles text processing and display

text_handle = [];
text_index = 0;
show_text = false;
voice_handle = -1;
no_voice_timer = 0;
voice_attempted = -1;
no_voice_duration = 10;
skip_cooldown = 0.5;
depth = 100;

// Speakers
enum Speaker {
  Chekov,
  Spock,
  Scott,
  Sulu,
  McCoy,
  Kirk,
  Uhura,
  None
}

speakers = array_create(array_length(Speaker.None));

speakers[Speaker.Chekov] = {x : 193, y : 109, color : global.t_colors.magenta};
speakers[Speaker.Spock] = {x : 286, y : 90, color : global.t_colors.blue};
speakers[Speaker.Scott] = {x : 50, y : 100, color : global.t_colors.red};
speakers[Speaker.Sulu] = {x : 50, y : 110, color : global.t_colors.yellow};
speakers[Speaker.McCoy] = {x : 50, y : 100, color : global.t_colors.blue};
speakers[Speaker.Kirk] = {x : 160, y : 150, color : global.t_colors.yellow};
speakers[Speaker.Uhura] = {x : 300, y : 151, color : global.t_colors.pink};
speakers[Speaker.None] = {x : 160, y : 106, color : global.t_colors.yellow};