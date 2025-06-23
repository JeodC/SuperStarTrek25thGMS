/// @description obj_torpedo Create Event - Initialize torpedo properties

// Movement properties (set by action_torpedo)
direction = 0;
speed = 3;
grid_x = 0;
old_grid_x = 0;
old_grid_y = 0;
grid_y = 0;
grid_target_x = 0;
grid_target_y = 0;
distance_traveled = 0; // Distance traveled in grid units

// Visual properties
sprite_index = spr_grid_torpedo;

audio_play_sound(snd_torpedo, 0, false);

first_step = true;
destroy_reason = "";

show_debug_message("Player launched a torpedo!");