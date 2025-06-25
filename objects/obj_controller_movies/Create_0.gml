credits_initialized = false;
credits_lines = [];  // Reset array
credits_index = 1;   // Start at 1
ctimer = 0;          // Add first line immediately
tx = 160;            // Center x position
credits_speed = 0.3; // Scroll speed (pixels per frame)
next_credit_y = room_height + 50;
credits_y_end = -50;      // Y position to remove lines (off top)
credits_end_timer = 60;   // Frames to wait after last credit
credits_finished = false; // Track completion
stats_added = false;      // Track whether stats have been added

/// @description: Get difficulty string for display
function get_diff_text(diff_num) {
  switch (diff_num) {
  case 1:
    return lang_get("opt.diff1");
  case 2:
    return lang_get("opt.diff2");
  case 3:
    return lang_get("opt.diff3");
  case 4:
    return lang_get("opt.diff4");
  default:
    return "Unknown";
  }
}

/// @description: Initialize animation and audio based on game state
function init_animation_by_state() {
  switch (global.game.state) {
  case State.Movie:
    audio_play_sound(mus_briefing_movie, 0, false);
    sprite_index = spr_anim_move;
    image_speed = 1;
    break;

  case State.Win:
    audio_play_sound(mus_title, 0, false);
    sprite_index = spr_anim_move;
    image_speed = 0.5;
    break;

  case State.Credits:
    sprite_index = spr_bg_stars;
    ctimer = 10; // Faster credits timer
    break;

  default:
    // Optional: set defaults or do nothing
    break;
  }
}

/// @description: Initialize animation and audio based on ship condition
function init_animation_by_condition() {
  switch (global.ent.condition) {
    case Condition.Destroyed:
      sprite_index = spr_anim_destroyed;
      image_speed = 1;
      break;

    case Condition.Stranded:
    case Condition.NoTime:
      audio_stop_all();
      audio_play_sound(mus_bridge_ambient, 0, false);
      sprite_index = spr_anim_move;
      image_index = 86; // Confirm this frame is correct
      image_speed = 0;
      break;

    default:
      break;
  }
}

/// @description: Handle warp mode initialization and effects
function handle_warp_mode() {
  if (global.inputmode.mode == InputMode.Warp) {
    global.inputmode.mode = InputMode.None;
    show_debug_message("Player warped to sector [" + string(global.ent.sx) +
                       "," + string(global.ent.sy) + "].");

    if (global.ent.condition != Condition.NoTime &&
        global.ent.condition != Condition.Stranded) {
      audio_play_sound(mus_warp, 0, false);
    }

    sprite_index = spr_anim_warp;
    image_speed = 1;
  }
}

/// @description: Main initialization function for obj_movies
function init_movie() {
  global.busy = true;
  timer = 300; // Duration for movie or animation

  diff = get_diff_text(global.game.difficulty);

  init_animation_by_state();

  init_animation_by_condition();

  handle_warp_mode();
}

init_movie();