/// @description: Initializes application
function scr_init() {

  // UI
  global.version = "1.0.3";
  global.lang_data = {};
  global.lang_index = 0;
  global.menu_selected = -1;
  global.selected_index = -1;

  // Options
  global.ini = "sst25th.ini";
  global.audio_mode = 0;
  global.difficulty = 1;
  global.lang = "en";
  global.debug = false;

  // Init
  init_scale(4);
  init_languages();
  load_options();
  init_game();
}

/// @description: Initializes an instance of Game struct and other game-related globals
function init_game() {

  // Core game state
  global.game = Game();
  global.game.difficulty = global.difficulty;
  global.game.date = 5943 + irandom(1000);
  global.game.enemypower = round(160 * (1 + global.game.difficulty / 10));
  global.game.maxdays = irandom_range(26, 31);
  global.game.t0 = global.game.date;
  global.game.state = State.Title;

  enum State {
    Title,
    Credits,
    Movie,
    Briefing,
    Intro,
    Loading,
    OptMenu,
    Playing,
    Win,
    Lose
  }

  // Resolve queue -- handles all dialog and actions in sequential order, see
  // handle_queue() in scr_resolve
  global.queue = [];
  global.index = 0;
  global.busy = false;

  // Static assets
  global.systems = {
    warp : lang_get("device.warp"),
    srs : lang_get("device.srs"),
    lrs : lang_get("device.lrs"),
    phasers : lang_get("device.phasers"),
    torpedoes : lang_get("device.torpedoes"),
    navigation : lang_get("device.navigation"),
    shields : lang_get("device.shields"),
  };

  global.p_colors = [ c_white, c_gray, c_ltgray, c_red, c_orange, c_yellow ];
  global.t_colors =
      {
        blue : make_color_rgb(107, 146, 255),
        yellow : c_yellow,
        red : c_red,
        green : make_color_rgb(0, 255, 62),
        pink : make_color_rgb(230, 129, 213),
        magenta : make_color_rgb(255, 51, 230),
      }

  // Dynamic objects initialization
  // ---------------------------------
  // global.allenemies: Array storing all enemy ship instances generated
  // after galaxy creation global.allbases: Array storing all starbase
  // instances generated after galaxy creation
  global.allenemies = [];
  global.allbases = [];

  // Player ship
  global.ent = Ship();

  // Empty galaxy
  global.galaxy = array_create(8);
  for (var sx = 0; sx < 8; sx++) {
    global.galaxy[sx] = array_create(8);
    for (var sy = 0; sy < 8; sy++) {
      var sector = Sector();
      sector.available_cells = [];
      for (var lx = 0; lx < 8; lx++) {
        for (var ly = 0; ly < 8; ly++) {
          array_push(sector.available_cells, [ lx, ly ]);
        }
      }
      global.galaxy[sx][sy] = sector;
    }
  }
}

/// @description Ensures options exist with defaults
function init_options() {
  ini_open(global.ini);

  // Check and write defaults if missing (write something to create the file)
  if (!ini_key_exists("Game", "audio_mode")) {
    ini_write_real("Game", "audio_mode", 0);
  }
  if (!ini_key_exists("Game", "difficulty")) {
    ini_write_real("Game", "difficulty", 1);
  }
  var lang = ini_read_string("Game", "lang", "");
  if (string_length(lang) == 0) {
    ini_write_string("Game", "lang", "en");
  }

  ini_close();
}

/// @description Initializes the language system using global.langs
function init_languages() {
  global.lang_data = {};
  global.lang_index = 0;
  global.lang_selected = "en";

  load_available_languages();

  if (is_array(global.langs) && array_length(global.langs) > 0) {
    if (array_contains(global.langs, "en")) {
      global.lang_selected = "en";
    } else {
      global.lang_selected = global.langs[0];
    }
    load_language(string(global.lang));
    reorder_languages();
  } else {
    global.langs = ["en"];
    global.lang_selected = "en";
    global.lang_index = 0;
    show_debug_message("Warning: No valid languages loaded, using default en");
  }

  global.lang = global.lang_selected;
  load_options(); // Load saved options
  show_debug_message("Initialized language: " + global.lang_selected);
}

/// @description Loads language codes from valid JSON files in lang/*.json into global.langs
function load_available_languages() {
  global.langs = [];

  var search_path = "lang/*.json";
  var file_name = file_find_first(search_path, fa_none);

  while (file_name != "") {
    var lang_code = string_copy(file_name, 1, string_length(file_name) - 5);
    var full_path = "lang/" + file_name;

    if (file_exists(full_path)) {
      var file = file_text_open_read(full_path);
      var content = "";
      while (!file_text_eof(file)) {
        content += file_text_readln(file);
        if (!file_text_eof(file)) {
          content += "\n";
        }
      }
      file_text_close(file);

      content = string_trim(content);

      try {
        var parsed = json_parse(content);
        array_push(global.langs, lang_code);
        show_debug_message("Valid language: " + lang_code);
      } catch (e) {
        show_debug_message("Invalid JSON in file: " + full_path);
      }
    } else {
      show_debug_message("File not found: " + full_path);
    }

    file_name = file_find_next();
  }
  file_find_close();

  array_sort(global.langs, true);
  show_debug_message("Available languages: " + string(global.langs));

  if (array_length(global.langs) == 0) {
    array_push(global.langs, "en");
    show_debug_message("Warning: No valid languages found, using default en");
  }
}

/// @description: Loads and parses the selected language file
function load_language(lang_code) {
  var lang_path = "lang/" + lang_code + ".json";

  if (file_exists(lang_path)) {
    var file = file_text_open_read(lang_path);
    var content = "";
    while (!file_text_eof(file)) {
      content += file_text_readln(file);
    }
    file_text_close(file);

    try {
      var parsed = json_parse(content);
      global.lang_data = parsed;
      global.lang = lang_code;
      show_debug_message("Language switched to " + string(lang_code));
    } catch (e) {
      show_debug_message("Error parsing language file: " + lang_path +
                         ". Falling back to English.");
      _load_english_fallback();
    }
  } else {
    show_debug_message("Missing language file: " + lang_path +
                       ". Falling back to English.");
    _load_english_fallback();
  }
}

/// @description: Explicitly loads the fallback language file 'en.json'
function _load_english_fallback() {
  var fallback_path = "lang/en.json";
  if (file_exists(fallback_path)) {
    var file = file_text_open_read(fallback_path);
    var content = "";
    while (!file_text_eof(file)) {
      content += file_text_readln(file);
    }
    file_text_close(file);

    try {
      var parsed = json_parse(content);
      global.lang_data = parsed;
      global.lang = "en";
    } catch (e) {
      show_debug_message("Error parsing fallback English file: " +
                         fallback_path);
      global.lang_data = {};
    }
  } else {
    show_debug_message(
        "Error: English fallback file (lang/en.json) not found!");
    global.lang_data = {};
  }
}

/// @description: Scales the window to a multiple of the native 320x200 size
function init_scale(scale_factor) {
  gpu_set_texfilter(false);
  var base_width = 320;
  var base_height = 200;
  var new_width = base_width * scale_factor;
  var new_height = base_height * scale_factor;

  // Set window and GUI size
  window_set_size(new_width, new_height);
  display_set_gui_size(base_width, base_height); // GUI stays unscaled
  window_center();

  // Resize application surface
  surface_resize(application_surface, new_width, new_height);

  // Enable view and set camera to draw 320x200 content scaled to window
  view_enabled = true;
  view_visible[0] = true;

  var cam = view_camera[0];
  cam = camera_create();
  view_camera[0] = cam;

  camera_set_view_size(cam, base_width, base_height); // Internal resolution
  camera_set_view_pos(cam, 0, 0);

  view_wport[0] = new_width; // How large it's rendered to window
  view_hport[0] = new_height;
}

/// @description Reinitializes globals for a fresh game session
function reset_game() {
  // Clear game state
  audio_stop_all();
  global.game = undefined;
  global.ent = undefined;
  global.galaxy = undefined;
  global.particles = undefined;
  global.allenemies = [];
  global.allbases = [];

  // Reset dialog/action queue
  global.queue = [];
  global.index = 0;
  global.busy = false;

  // Remove player object and reset to title screen
  if (instance_exists(obj_controller_player)) {
    instance_destroy(obj_controller_player);
    instance_destroy(obj_controller_ui);
    room_goto(rm_title);
    create_title_buttons();
    global.active_buttons = global.title_buttons;

    audio_play_sound(mus_title, 0, false);
  }

  // Reinitialize full game state
  init_game();
}

/// @description Returns true if any input is pressed
function input_any() {
  return (global.input.confirm || global.input.cancel || global.input.up ||
          global.input.down || global.input.left || global.input.right ||
          mouse_check_button_pressed(mb_any) ||
          keyboard_check_pressed(vk_anykey));
}