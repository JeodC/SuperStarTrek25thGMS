/// scr_options
/// functions for managing the game options and menu

/// @description: Changes the current language by a given amount (e.g. next or previous), wraps around, and updates the language list
/// @param {real} delta: Amount to change the language index by (can be negative)
function update_language_index(delta) {
  var len = array_length(global.langs);
  if (len <= 0)
    return;

  // Wrap index within valid range [0, len-1]
  global.lang_index = (global.lang_index + delta + len) mod len;
  global.lang_selected = global.langs[global.lang_index];

  reorder_languages();
}

/// @description: Moves the selected language to the top of the list and resets the index
function reorder_languages() {
  if (!is_array(global.langs)) {
    return;
  }

  if (global.lang_selected == "" ||
      !array_contains(global.langs, global.lang_selected)) {
    show_debug_message("Invalid language selected: " +
                       string(global.lang_selected));
    return;
  }

  var len = array_length(global.langs);
  if (len <= 1)
    return;

  var current_index = array_index_of(global.langs, global.lang_selected);
  if (current_index == -1) {
    show_debug_message("Error: Language " + global.lang_selected +
                       " not in global.langs");
    return;
  }

  var new_langs = [];
  array_push(new_langs, global.lang_selected);
  for (var i = 0; i < len; i++) {
    if (i != current_index) {
      array_push(new_langs, global.langs[i]);
    }
  }

  global.langs = new_langs;
  global.lang_index = 0;
}

/// @description: Loads game options from ini specified in global.ini
function load_options() {
  if file_exists (global.ini) {
    ini_open(global.ini);
    global.audio_mode = ini_read_real("Game", "audio_mode", 0);
    global.difficulty = ini_read_real("Game", "difficulty", 1);
    var saved_lang = ini_read_string("Game", "lang", "en");
    if (is_array(global.langs) && array_contains(global.langs, saved_lang)) {
      global.lang_selected = saved_lang;
      global.lang = saved_lang;
      load_language(saved_lang);
    }
    ini_close();
    show_debug_message("Options loaded from " + global.ini);
  } else {
    show_debug_message("Warning: " + string(global.ini) +
                       " not found, using defaults");
    init_options();
  }
}

/// @description: Saves game options to ini specified in global.ini
function save_options() {
  if file_exists (global.ini) {
    ini_open(global.ini);
    ini_write_real("Game", "audio_mode", global.audio_mode);
    ini_write_real("Game", "difficulty", global.difficulty);
    ini_write_string("Game", "lang", global.lang);
    ini_close();
    show_debug_message("Options saved to " + global.ini);
  } else {
    show_debug_message("Unable to save options to " + string(global.ini) + "!");
  }
}

/// @description: Clears out all ui button instances
function cleanup_buttons() {
  var button_lists = [ global.title_buttons, global.options_buttons ];

  for (var j = 0; j < array_length(button_lists); j++) {
    var list = button_lists[j];
    if (is_array(list)) {
      for (var i = 0; i < array_length(list); i++) {
        if (instance_exists(list[i])) {
          instance_destroy(list[i]);
        }
      }
    }
  }

  global.title_buttons = [];
  global.options_buttons = [];
  global.selected_index = -1;
}

/// @description: Creates instances of title menu buttons
function create_title_buttons() {
  cleanup_buttons();
  var titles =
      [ "ui.newgame", "ui.continue", "ui.options", "ui.credits", "ui.exit" ];
  for (var i = 0; i < array_length(titles); i++) {
    var b = instance_create_layer(12, 90 + i * 20, "Overlay", obj_ui_button);
    setup_menu_button(b, titles[i]);
    b.type = "title";
    array_push(global.title_buttons, b);
  }
}

/// @description: Creates and lays out the options menu buttons
function create_options_buttons() {
  cleanup_buttons();

  global.game.state = State.OptMenu;
  global.inputmode.mode = InputMode.UI;
  global.options_buttons_created = true;

  var x_base = 130;
  var y_base = 50;
  var spacing = 32;

  // Difficulty mode
  var b_diff =
      instance_create_layer(x_base - 30, y_base, "Overlay", obj_ui_button);
  setup_menu_button(b_diff, "ui.difficulty");
  array_push(global.options_buttons, b_diff);

  // Audio mode
  var b_sub =
      instance_create_layer(x_base - 30, y_base + 20, "Overlay", obj_ui_button);
  setup_menu_button(b_sub, "ui.subtitles");
  array_push(global.options_buttons, b_sub);

  var y_lang = y_base + 20 + spacing;

  // Left language button
  var b_left =
      instance_create_layer(x_base - 24, y_lang, "Overlay", obj_ui_button);
  setup_menu_button(b_left, "ui.langleft");
  array_push(global.options_buttons, b_left);

  // Right language button
  var b_right =
      instance_create_layer(x_base + 72, y_lang, "Overlay", obj_ui_button);
  setup_menu_button(b_right, "ui.langright");
  array_push(global.options_buttons, b_right);

  var y_action = y_lang + spacing;

  // Apply button
  var b_apply =
      instance_create_layer(x_base - 48, y_action, "Overlay", obj_ui_button);
  setup_menu_button(b_apply, "ui.apply");
  array_push(global.options_buttons, b_apply);

  // Reset defaults button
  var b_default =
      instance_create_layer(x_base + 48, y_action, "Overlay", obj_ui_button);
  setup_menu_button(b_default, "ui.default");
  array_push(global.options_buttons, b_default);

  var y_quit = y_action + spacing;

  // Conditional extra buttons if in-game
  if (instance_exists(obj_controller_player)) {
    // Return to Game
    var b_return =
        instance_create_layer(x_base - 48, y_quit, "Overlay", obj_ui_button);
    setup_menu_button(b_return, "ui.return");
    array_push(global.options_buttons, b_return);

    // Quit to Title
    var b_quit =
        instance_create_layer(x_base + 48, y_quit, "Overlay", obj_ui_button);
    setup_menu_button(b_quit, "ui.quit");
    array_push(global.options_buttons, b_quit);
  } else {
    // Quit (from title/options)
    var b_quit =
        instance_create_layer(x_base, y_quit, "Overlay", obj_ui_button);
    setup_menu_button(b_quit, "ui.quit");
    array_push(global.options_buttons, b_quit);
  }
}

/// @description: Creates and switches active ui buttons based on state
function switch_menu(new_state) {
  global.game.state = new_state;

  if (new_state == State.Title) {
    create_title_buttons();
    global.active_buttons = global.title_buttons;
  } else if (new_state == State.OptMenu) {
    create_options_buttons();
    global.active_buttons = global.options_buttons;
  }
}

/// @description: Configures a menu button
/// @param {id.Instance} button: The button instance
/// @param {string} menu_id: The menu identifier (e.g., ui.default)
function setup_menu_button(button, menu_id) {
  button.label = menu_id;
  button.menu_id = menu_id;
  button.is_hovered = false;
  button.text = "";
  button.sprite_index = spr_btn_rect;
  switch (menu_id) {
  case "ui.langleft":
    button.sprite_index = spr_btn_square;
    button.text = "<";
    break;
  case "ui.langright":
    button.sprite_index = spr_btn_square;
    button.text = ">";
    break;
  case "ui.subtitles":
    break;
  default:
    button.text = lang_get(menu_id);
    break;
  }
}

/// @description: Updates text for all option buttons
function refresh_button_text() {
  if (is_array(global.options_buttons)) {
    for (var i = 0; i < array_length(global.options_buttons); i++) {
      var b = global.options_buttons[i];
      if (!is_undefined(b) && instance_exists(b)) {
        if (b.label == "ui.subtitles") {
          switch (global.audio_mode) {
          case 0:
            b.text = lang_get("opt.audiomode1");
            break;
          case 1:
            b.text = lang_get("opt.audiomode2");
            break;
          case 2:
            b.text = lang_get("opt.audiomode3");
            break;
          default:
            b.text = lang_get("opt.audiomode1");
          }
        } else if (b.label == "ui.difficulty") {
          switch (global.difficulty) {
          case 1:
            b.text = lang_get("opt.diff1");
            break;
          case 2:
            b.text = lang_get("opt.diff2");
            break;
          case 3:
            b.text = lang_get("opt.diff3");
            break;
          case 4:
            b.text = lang_get("opt.diff4");
            break;
          default:
            b.text = lang_get("opt.diff1");
          }
        } else if (b.label == "ui.langleft") {
          b.text = "<";
        } else if (b.label == "ui.langright") {
          b.text = ">";
        } else {
          b.text = lang_get(b.label);
        }
      }
    }
  }
}
