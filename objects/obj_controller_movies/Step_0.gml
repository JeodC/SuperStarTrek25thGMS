// Always busy while movie object exists
global.busy = true;

// Input to skip movie
if (input_any()) {
  global.busy = false;

  if (global.ent.condition == Condition.Destroyed ||
      global.ent.condition == Condition.Stranded ||
      global.ent.condition == Condition.NoTime) {
    global.game.state = State.Lose;
    end_movie();
    reset_game();
    game_restart();
    return;
  }

  if (global.game.state == State.Movie) {
    global.game.state = State.Briefing;
    end_movie();
    room_goto(rm_game);
    return;
  }

  if (sprite_index == spr_anim_warp && global.game.state == State.Playing) {
    end_movie();
    return;
  }

  if (global.game.state == State.Win) {
    end_movie();
    global.game.state = State.Credits;
    room_goto(rm_endgame);
    return;
  }
}

// Warp animation finished (no loop, ends when audio stops)
if (sprite_index == spr_anim_warp && !audio_is_playing(mus_warp) && global.game.state == State.Playing) {
  end_movie();
  return;
}

// Intro/sector movement movie finished (by animation frame)
var movie_done = (sprite_index == spr_anim_move && image_index >= image_number - 1 && global.ent.condition != Condition.Stranded && global.ent.condition != Condition.NoTime);
if (movie_done) {
  global.busy = false;

  if (global.ent.condition == Condition.Destroyed || global.ent.condition == Condition.Stranded) {
    global.game.state = State.Lose;
  } 
  else if (global.game.state == State.Movie) {
    global.game.state = State.Briefing;
  } 
  else if (global.game.state == State.Win) {
    global.game.state = State.Credits;
  }

  if (global.game.state != State.Win && global.game.state != State.Credits) {
    end_movie();
    room_goto(rm_game);
    return;
  }
}

// Handle loss or win screen countdown or input skip
if (global.game.state == State.Lose) {
  timer--;

  if ((timer <= 280 && input_any()) || timer <= 0) {
    reset_game();
    game_restart();
  }
}

// Destroyed animation looping at final frame
if (sprite_index == spr_anim_destroyed && image_index >= image_number - 1) {
  image_index = 68; // Hold final frame
}

// -- Credits logic
if (room == rm_endgame && global.game.state == State.Credits && !credits_initialized) {
  update_movie_animation();
} else if (room == rm_endgame && sprite_index == spr_anim_warp && credits_initialized) {
  image_index = 106;
}

// Helper: End Movie
function end_movie() {
  audio_stop_all();
  reset_player_state();
  instance_destroy();
}

// Helper: Reset game input/display after movie
function reset_player_state() {
  if (instance_exists(obj_controller_player)) {
    global.busy = true;
    obj_controller_player.display = Reports.Default;
    global.inputmode.mode = InputMode.Bridge;
    advancetime(1); // Time advances by one day when we change sectors
    array_push(
        global.queue, function() {
          repair_random_systems(); // Repair random systems
          dialog_enemy_check();    // Check for enemies
        });
  }
}

if (credits_initialized) {
  add_credit_line();
  add_stats_lines();
  check_credits_finished();
  handle_credits_input();
  scroll_credits();
  check_stats_settled();
}

/// @description Initialize credits (music and variables)
function roll_credits() {
  if (!credits_initialized) {
    audio_play_sound(mus_credits, 0, false);
    credits_lines = []; // Reset array
    credits_index = 1;  // Start at 1
    ctimer = 0;         // Add first line immediately
    credits_initialized = true;
  }
}

/// @description Update movie animation state
function update_movie_animation() {
  if (sprite_index == spr_anim_move && image_index >= image_number - 1) {
    sprite_index = spr_anim_warp;
    image_index = 0;
    image_speed = 0.5;
  } else if (sprite_index == spr_anim_warp && image_index > 106) {
    image_index = 106;
    roll_credits();
  } else if (sprite_index == spr_bg_stars) {
    roll_credits();
  }
}

/// @description Add a new credit line with dynamic timer and spacing
function add_credit_line() {
  ctimer--;
  if (ctimer <= 0) {
    var key = "credits." + string(credits_index);
    if (is_struct(global.lang_data) &&
        variable_struct_exists(global.lang_data, key)) {
      var text = lang_get(key);

      var wrap = 230;
      var spacing = 8;

      // Calculate height of this line's text
      var line_height = string_height_ext(text, spacing, wrap);

      // Use next_credit_y to place the new line *below* all previous
      // lines
      var y_pos = next_credit_y;

      // Add new line
      array_push(credits_lines, {text : text, y : y_pos});

      // Update next_credit_y for next line (stack lines downward)
      next_credit_y += line_height;

      // Set timer for next line depending on its length
      var next_key = "credits." + string(credits_index + 1);
      if (is_struct(global.lang_data) &&
          variable_struct_exists(global.lang_data, next_key)) {
        var next_text = lang_get(next_key);
        var next_text_len = string_length(next_text);

        var base_timer = 10;   // Base duration (in frames) before showing the next credit line
        var min_timer = 100;   // Minimum allowed duration for the timer (prevents it from being too short)
        var name_timer = 14;   // Short timer for lines considered "names" (usually short lines)
        var max_timer = 80;    // Maximum allowed duration for the timer (prevents it from being too long)
        var length_factor = 2; // Multiplier applied to the length of the next line to increase timer duration proportionally
        var name_threshold = 20; // Maximum length (in characters) for a line to be considered a "name" (short line)

        if (next_text_len <= name_threshold) {
          ctimer = name_timer;
        } 
        else {
          ctimer = clamp(base_timer + (next_text_len * length_factor), min_timer, max_timer);
        }
      } 
      else {
        ctimer = 160;
      }

      credits_index++;
    }
    else {
      ctimer = -1;
    }
  }
}

/// @description Add game stats after credits
function add_stats_lines() {
  var num_lines = array_length(credits_lines);
  var last_index = num_lines - 1;

  if (variable_global_exists("score")) {
    if (!stats_added && ctimer == -1 && num_lines > 0 &&
        credits_lines[last_index].y < room_height - 60) {
      var days = global.game.t0 + (global.game.maxdays - global.game.date);
      var stat_texts = [
        lang_get("stats.header"),
        lang_format("stats.shipsdestroyed",
                    {totalenemies : global.game.initenemies}),
        lang_format("stats.daysleft", {daysleft : days}),
        lang_format("stats.difficulty", {difficulty : global.game.difficulty}),
        lang_format("stats.score", {score : global.score})
      ];
      var spacing = 15;
      // Initialize final Y positions for stats (e.g., centered in room)
      var stats_final_y = [
        room_height / 2 - 2 * spacing, // Header
        room_height / 2 - 1 * spacing, // Ships destroyed
        room_height / 2,               // Days left
        room_height / 2 + 1 * spacing, // Difficulty
        room_height / 2 + 2 * spacing  // Score
      ];
      for (var i = 0; i < array_length(stat_texts); i++) {
        array_push(credits_lines, {
          text : stat_texts[i],
          y : room_height + i * spacing,
          final_y : stats_final_y[i]
        });
      }
      stats_added = true;
    }
  }
}

/// @description Check if credits are finished
function check_credits_finished() {
  var num_lines = array_length(credits_lines);
  var last_index = num_lines - 1;

  if (!credits_finished && ctimer == -1 && num_lines > 0 &&
      credits_lines[last_index].y < -30) {
    credits_finished = true;
  }
}

/// @description Handle input to exit credits
function handle_credits_input() {
  if (!credits_finished && input_any()) {
    audio_stop_all();
    audio_play_sound(mus_title, 0, false);
    global.game.state = State.Title;
    cleanup_buttons();
    global.inputmode.mode = InputMode.UI;
    obj_controller_ui.from_credits = true;
    room_goto(rm_title);
  } else if (credits_finished && input_any()) {
    audio_stop_all();
    audio_play_sound(mus_title, 0, false);
    global.game.state = State.Title;
    cleanup_buttons();
    global.inputmode.mode = InputMode.UI;
    obj_controller_ui.from_credits = true;
    room_goto(rm_title);
    reset_game();
  }
}

/// @description Scroll credits and stats
function scroll_credits() {
  var num_lines = array_length(credits_lines);
  for (var i = num_lines - 1; i >= 0; i--) {
    var line = credits_lines[i];
    if (!variable_struct_exists(line, "final_y")) {
      line.y -= credits_speed;
    } else {
      if (line.y > line.final_y) {
        line.y -= credits_speed;
        if (line.y < line.final_y)
          line.y = line.final_y;
      }
    }
    if (line.y < credits_y_end && !variable_struct_exists(line, "final_y")) {
      array_delete(credits_lines, i, 1);
    } else {
      credits_lines[i] = line;
    }
  }
}

/// @description Check if stats are settled
function check_stats_settled() {
  if (ctimer == -1 && stats_added) {
    var all_stats_settled = true;
    for (var i = 0; i < array_length(credits_lines); i++) {
      if (variable_struct_exists(credits_lines[i], "final_y") &&
          credits_lines[i].y != credits_lines[i].final_y) {
        all_stats_settled = false;
        break;
      }
    }
    if (all_stats_settled && array_length(credits_lines) == 5) {
      credits_end_timer--;
      if (credits_end_timer <= 0) {
        credits_finished = true;
      }
    }
  }
}