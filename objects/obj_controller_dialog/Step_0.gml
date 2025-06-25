/// @obj_controller_dialog_Step
/// @description: Handles text processing and display

if (show_text) {
  var len = array_length(text_handle);

  if (len == 0) {
    reset_dialog();
  } else if (text_index < len) {
    var current = text_handle[text_index];

    // Skip auto-advance during movie
    if (instance_exists(obj_controller_movies)) {
      return;
    }

    // Initialize voice and timer only if not yet set for this line
    if (voice_attempted != text_index) {
      voice_handle = play_voice(current);
      voice_attempted = text_index;
      if (voice_handle != -1) {
        no_voice_timer = 0;
        skip_cooldown = 0.15;
      } else {
        no_voice_timer = 0;
      }
    }

    // Advance if voice finished
    if (voice_handle != -1 && !audio_is_playing(voice_handle)) {
      advance_text();
    }

    // Advance dialog after a delay for no-voice dialogs
    if (voice_handle == -1) {
      var text_length = 0;
      if (is_struct(current) && variable_struct_exists(current, "line") &&
          is_string(current.line)) {
        text_length = string_length(current.line);
      }
      var base_time = 1.0;
      var per_char_time = 0.05;
      var dynamic_no_voice_duration = base_time + (text_length * per_char_time);

      no_voice_timer += delta_time / 1000000;

      if (no_voice_timer >= dynamic_no_voice_duration) {
        advance_text();
      }
    }

    // Allow manual dialog skip only if movie is not playing
    if (!instance_exists(obj_controller_movies)) {
      handle_skip(len);
    }

    if (text_index >= len) {
      reset_dialog();
    }
  }
}

/// @description: Plays voice clip associated with the current dialog line if
/// available and audio mode allows it.
/// @param {struct} current_line: The current dialog line struct expected to
/// have a "voice" field (audio resource).
function play_voice(current_line) {
  if (is_struct(current_line) &&
      variable_struct_exists(current_line, "voice") &&
      audio_exists(current_line.voice) && global.audio_mode != 2) {
    return audio_play_sound(current_line.voice, 0, false);
  }
  return -1;
}

/// @description: Advances the dialog index to the next line, resets voice
/// handle and timers. Sets a small delay to prevent immediate re-skipping.
function advance_text() {
  voice_handle = -1;
  voice_attempted = -1;
  no_voice_timer = 0; // Initialize for next dialog
  text_index++;
  skip_cooldown = 0.15;
}

/// @description: Handles player input to manually advance dialog.
/// Stops any playing voice clip, advances text, and starts the voice clip for
/// the new line if available.
/// @param {real} len: Total number of lines in the current dialog.
function handle_skip(len) {
  if (skip_cooldown > 0) {
    skip_cooldown -= delta_time / 1000000;
  } else if (global.input.confirm) {
    if (voice_handle != -1) {
      audio_stop_sound(voice_handle);
      voice_handle = -1;
    }
    no_voice_timer = 0;
    advance_text();
    if (text_index < len) {
      var next_line = text_handle[text_index];
      voice_handle = play_voice(next_line);
      if (voice_handle != -1) {
        skip_cooldown = 0.15;
      }
    }
    global.input.confirm = false;
  }
}

/// @description: Resets dialog state variables to default.
/// Called when dialog finishes or there is no dialog text.
function reset_dialog() {
  show_text = false;
  text_index = 0;
  voice_handle = -1;
  no_voice_timer = 0;
  skip_cooldown = 0;
}