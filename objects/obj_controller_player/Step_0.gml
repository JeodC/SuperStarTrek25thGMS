// @obj_controller_player_Step
/// @description: Handles game state

// If showing briefing and got input move on to Intro
if (global.game.state == State.Briefing && input_any()) {
	global.game.state = State.Intro;
	global.inputmode.mode = InputMode.Bridge;
}

// Initialize game and queue intro text
if (global.game.state == State.Intro) {
    global.game.state = State.Playing;
    global.busy = true;
    global.queue = [];
    global.index = 0;
    dialog_introspeech();
    dialog_enemy_check();
	get_sector_data();
    dialog_helptext();
}

// If loaded set up states -- check for enemies and refresh local sector arrays for obj_player
if (global.game.state == State.Loading) {
	if (global.loaded_state != undefined) {
		apply_player_state(global.loaded_state);
		global.loaded_state = undefined;
	}
	global.game.state = State.Playing;
	dialog_enemy_check();
	get_sector_data();
}

// Ensure ambient sound plays
if (global.inputmode.mode == InputMode.Bridge && !audio_is_playing(mus_bridge_ambient)) {
	audio_play_sound(mus_bridge_ambient, 1, true);
}

// Handle the resolve queue -- this exists in obj_player so the queue only runs during gameplay
if (global.busy) {
	handle_queue();
}

// If we have no shields or energy we immediately lose
if (global.ent.shields < 2 && global.ent.energy < 2 && !global.busy) {
	global.ent.condition = Condition.Stranded;
	global.busy = true;
	array_resize(global.queue, global.index);
	array_push(global.queue, function() {
		dialog_condition();
		return undefined;
	});
	return undefined;
}

/// @description: Returns a struct of local player state for saving.
function get_player_state() {
	return {
		display: display,
		end_turn: end_turn,
		anim_lrs_state: anim_lrs_state,
		anim_siren_state: anim_siren_state,

		contactedbase: contactedbase,
		askedforlrs: askedforlrs,
		firstenemyspotted: firstenemyspotted,
		impulsehelp: impulsehelp,

		speech_damage: speech_damage,
		speech_phaserfire: speech_phaserfire,
		speech_phaserhit: speech_phaserhit,
		speech_phaserwarn: speech_phaserwarn,
		speech_suggestedlrs: speech_suggestedlrs,
		speech_torparm: speech_torparm,

		torp_angle: torp_angle,
		torp_cx: torp_cx,
		torp_cy: torp_cy
	};
}