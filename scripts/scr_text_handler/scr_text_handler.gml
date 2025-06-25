/// @description: Returns normalized translation for a key from global.lang_data
/// @param {array} text: Dialog array (speaker, line, voice)
function process_dialog(text) {
  // Resolve speaker structs using speaker keys from struct
  for (var i = 0; i < array_length(text); i++) {
    var line = text[i];

    if (line.speaker != undefined) {
      var speaker_id = line.speaker;

      // Check that speaker_id is valid index for speakers array
      if (is_array(obj_controller_dialog.speakers) && speaker_id >= 0 &&
          speaker_id < array_length(obj_controller_dialog.speakers)) {
        line.speaker_data = obj_controller_dialog.speakers[speaker_id];
      } else {
        line.speaker_data = {x : 32, y : 32, color : c_white};
      }
    }
  }

  with(obj_controller_dialog) {
    text_handle = text;
    text_index = 0;
    show_text = true;
    voice_handle = -1;
    no_voice_timer = 0;
    timer = 0.3;
  }
}

/// @description: Returns a dialog array for immediate processing by handle_queue
/// @param {enum} speaker: The speaker enum
/// @param {string} line_id: The localization key for the dialog line
/// @param {any} voice_id: Sound asset to use or noone
/// @param {struct} format: Optional format arguments for lang_format
function immediate_dialog(speaker, line_id, voice_id = noone,
                          format = undefined) {
  var resolved_line =
      is_struct(format) ? lang_format(line_id, format) : lang_get(line_id);

  var dialog_line = {speaker : speaker, line : resolved_line, voice : voice_id};

  return [dialog_line];
}

/// @description: Queues a dialog line for handle_queue
/// @param {enum} speaker: The speaker enum
/// @param {string} line_id: The localization key for the dialog line
/// @param {any} voice_id: Sound asset to use or noone
/// @param {struct} format: Optional format arguments for lang_format
function queue_dialog(speaker, line_id, voice_id = noone, format = undefined) {
  global.busy = true;

  var resolved_line =
      is_struct(format) ? lang_format(line_id, format) : lang_get(line_id);

  var dialog_line = {speaker : speaker, line : resolved_line, voice : voice_id};

  var dialog_closure =
      method({dialog : dialog_line}, function() { return [dialog]; });

  array_push(global.queue, dialog_closure);
}

/// @description: Returns normalized translation for a key from global.lang_data
/// @param {string} key: The translation key (e.g., "ui.newgame")
function lang_get(key) {
  if (!is_struct(global.lang_data)) {
    show_debug_message("Error: global.lang_data is not a struct for key: " +
                       key + ", lang: " + string(global.lang));
    return normalize_text(key);
  }
  if (variable_struct_exists(global.lang_data, key)) {
    var text = variable_struct_get(global.lang_data, key);
    return normalize_text(text); // Normalize "Nová hra" to "Nova hra"
  }
  show_debug_message("Error: Translation key not found: " + key +
                     " in lang: " + global.lang);
  return normalize_text(key);
}

/// @description: Returns normalized translation for a key from global.lang_data
/// and a variable to use for a given key
/// @param {string} key: The key in text to replace
/// @param {string} variable: The variable to swap into the key
function lang_format(key, variable) {
  var text = lang_get(key);

  // Ensure replacements is a struct before using it
  if (is_struct(variable)) {
    var keys = variable_struct_get_names(variable);
    for (var i = 0; i < array_length(keys); i++) {
      var k = keys[i];
      var v = variable_struct_get(variable, k);
      text = string_replace_all(text, "{" + k + "}", string(v));
    }
  }

  return normalize_text(text);
}

/// @description: Removes diacritics from a string (e.g., "Č" -> "C", "á" -> "a") for font support
/// @param {string} str: The input string
function normalize_text(str) {
  if (!is_string(str))
    return str;

  var result = "";
  var len = string_length(str);

  // Mapping of accented characters (by ord value) to unaccented
  var map = {};
  map[$ string(ord("Á"))] = "A";
  map[$ string(ord("á"))] = "a";
  map[$ string(ord("Č"))] = "C";
  map[$ string(ord("č"))] = "c";
  map[$ string(ord("Ď"))] = "D";
  map[$ string(ord("ď"))] = "d";
  map[$ string(ord("É"))] = "E";
  map[$ string(ord("é"))] = "e";
  map[$ string(ord("Ě"))] = "E";
  map[$ string(ord("ě"))] = "e";
  map[$ string(ord("Í"))] = "I";
  map[$ string(ord("í"))] = "i";
  map[$ string(ord("Ň"))] = "N";
  map[$ string(ord("ň"))] = "n";
  map[$ string(ord("Ó"))] = "O";
  map[$ string(ord("ó"))] = "o";
  map[$ string(ord("Ř"))] = "R";
  map[$ string(ord("ř"))] = "r";
  map[$ string(ord("Š"))] = "S";
  map[$ string(ord("š"))] = "s";
  map[$ string(ord("Ť"))] = "T";
  map[$ string(ord("ť"))] = "t";
  map[$ string(ord("Ú"))] = "U";
  map[$ string(ord("ú"))] = "u";
  map[$ string(ord("Ů"))] = "U";
  map[$ string(ord("ů"))] = "u";
  map[$ string(ord("Ý"))] = "Y";
  map[$ string(ord("ý"))] = "y";
  map[$ string(ord("Ž"))] = "Z";
  map[$ string(ord("ž"))] = "z";
  map[$ string(ord("À"))] = "A";
  map[$ string(ord("à"))] = "a";
  map[$ string(ord("Â"))] = "A";
  map[$ string(ord("â"))] = "a";
  map[$ string(ord("Ã"))] = "A";
  map[$ string(ord("ã"))] = "a";
  map[$ string(ord("Ä"))] = "A";
  map[$ string(ord("ä"))] = "a";
  map[$ string(ord("Ć"))] = "C";
  map[$ string(ord("ć"))] = "c";
  map[$ string(ord("Ç"))] = "C";
  map[$ string(ord("ç"))] = "c";
  map[$ string(ord("Đ"))] = "D";
  map[$ string(ord("đ"))] = "d";
  map[$ string(ord("È"))] = "E";
  map[$ string(ord("è"))] = "e";
  map[$ string(ord("Ê"))] = "E";
  map[$ string(ord("ê"))] = "e";
  map[$ string(ord("Ë"))] = "E";
  map[$ string(ord("ë"))] = "e";
  map[$ string(ord("Ì"))] = "I";
  map[$ string(ord("ì"))] = "i";
  map[$ string(ord("Î"))] = "I";
  map[$ string(ord("î"))] = "i";
  map[$ string(ord("Ï"))] = "I";
  map[$ string(ord("ï"))] = "i";
  map[$ string(ord("Ñ"))] = "N";
  map[$ string(ord("ñ"))] = "n";
  map[$ string(ord("Ò"))] = "O";
  map[$ string(ord("ò"))] = "o";
  map[$ string(ord("Ô"))] = "O";
  map[$ string(ord("ô"))] = "o";
  map[$ string(ord("Õ"))] = "O";
  map[$ string(ord("õ"))] = "o";
  map[$ string(ord("Ö"))] = "O";
  map[$ string(ord("ö"))] = "o";
  map[$ string(ord("Ś"))] = "S";
  map[$ string(ord("ś"))] = "s";
  map[$ string(ord("Ş"))] = "S";
  map[$ string(ord("ş"))] = "s";
  map[$ string(ord("Ţ"))] = "T";
  map[$ string(ord("ţ"))] = "t";
  map[$ string(ord("Ù"))] = "U";
  map[$ string(ord("ù"))] = "u";
  map[$ string(ord("Û"))] = "U";
  map[$ string(ord("û"))] = "u";
  map[$ string(ord("Ü"))] = "U";
  map[$ string(ord("ü"))] = "u";
  map[$ string(ord("Ÿ"))] = "Y";
  map[$ string(ord("ÿ"))] = "y";
  map[$ string(ord("Ź"))] = "Z";
  map[$ string(ord("ź"))] = "z";
  map[$ string(ord("Ż"))] = "Z";
  map[$ string(ord("ż"))] = "z";

  for (var i = 1; i <= len; i++) {
    var char = string_char_at(str, i);
    var char_ord = string(ord(char));
    result += variable_struct_exists(map, char_ord) ? map[$ char_ord] : char;
  }

  return result;
}

/// @description: Returns a user-friendly key name for a given action based on current input source.
/// @param {string} action: The logical action name
function get_keyname(action) {
  var source = global.input.source;

  switch (source) {
  case InputSource.Keyboard:
  case InputSource.Mouse:
    switch (action) {
    case "confirm":
      return "Space";
    case "cancel":
      return "Esc";
    case "up":
      return "Up";
    case "down":
      return "Down";
    case "left":
      return "Left";
    case "right":
      return "Right";
    case "help":
      return "F1";
    case "move":
      return "Arrow Keys";
    }
    break;
  case InputSource.Gamepad:
    switch (action) {
    case "confirm":
      return "A Button";
    case "cancel":
      return "B Button";
    case "up":
      return "D-Pad Up";
    case "down":
      return "D-Pad Down";
    case "left":
      return "D-Pad Left";
    case "right":
      return "D-Pad Right";
    case "help":
      return "Select";
    case "move":
      return "D-Pad";
    }
    break;
  }

  // Fallback
  return "???";
}