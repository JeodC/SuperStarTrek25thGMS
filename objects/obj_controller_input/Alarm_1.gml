/// @obj_controller_input_Alarm1
/// @description Processes UI actions based on global.menu_selected

var menu_id = global.menu_selected;
audio_stop_sound(mus_title);

// Check what the player picked
switch (menu_id) {
  case "ui.newgame":
    global.inputmode.mode = InputMode.None;
    global.game.state = State.Movie;
    cleanup_buttons();
    if (!instance_exists(obj_controller_movies)) {
      instance_create_layer(0, 0, "Overlay", obj_controller_movies);
    }
    show_debug_message("Game started!");
    generate_galaxy();
    break;
  case "ui.continue":
    cleanup_buttons();
    draw_clear_alpha(c_black, 1);
    show_debug_message("Game started!");

    var result = load_game("sst25th.dat");
    if (result.ok) {
      global.game.state = State.Loading;
      global.inputmode.mode = InputMode.Bridge;
      global.loaded_state = result.state;
      room_goto(rm_game);
    } else {
      show_debug_message("No valid save found or file corrupted!");
      global.game.state = State.Title;
      create_title_buttons();
    }
    break;
  case "ui.options":
    create_options_buttons();
    break;
  case "ui.credits":
    global.game.state = State.Credits;
    room_goto(rm_endgame);
    break;
  case "ui.exit":
    if (global.game.state == State.Title) {
      game_end();
    }
    break;
  case "ui.default":
    global.audio_mode = 0;
    global.lang_index = 0;
    global.lang_selected = "en";
    reorder_languages();
    load_language(global.lang_selected);
    global.lang = global.lang_selected;
    refresh_button_text();
    break;
  case "ui.restart":
    game_restart();
    break;
  case "ui.difficulty":
    // global.game.difficulty copies global.difficulty in generate_galaxy
    global.difficulty = (global.difficulty % 4) + 1;
    break;
  case "ui.subtitles":
    global.audio_mode = (global.audio_mode + 1) % 3;
    refresh_button_text();
    break;
  case "ui.langleft":
    update_language_index(-1);
    load_language(global.lang_selected);
    refresh_button_text();
    break;
  case "ui.langright":
    update_language_index(1);
    load_language(global.lang_selected);
    refresh_button_text();
    break;
  case "ui.apply":
    // Validate lang_selected
    if (!is_string(global.lang_selected) || global.lang_selected == "" || !array_contains(global.langs, global.lang_selected)) {
      global.lang_selected = array_length(global.langs) > 0 ? global.langs[0] : "en";
      show_debug_message("Invalid lang_selected, using: " + global.lang_selected);
    }
    save_options();
    // Cleanup
    cleanup_buttons();
    global.options_buttons_created = false;
    global.game.state = State.Title;
    if (instance_exists(obj_controller_player)) {
      global.game.state = State.Playing;
      global.inputmode.mode = InputMode.Bridge;
    } else {
      global.game.state = State.Title;
      global.inputmode.mode = InputMode.UI;
      create_title_buttons();
    }
    break;
  case "ui.return":
    cleanup_buttons();
    global.options_buttons_created = false;
    global.game.state = State.Playing;
    global.inputmode.mode = InputMode.Bridge;
    break;
  case "ui.quit":
    cleanup_buttons();
    global.options_buttons_created = false;
    global.game.state = State.Title;
    global.inputmode.mode = InputMode.UI;
    if (room == rm_game) {
      reset_game();
    }
    create_title_buttons();
    break;
}

global.menu_selected = "";