// @obj_controller_player_Create
/// @description: Handles game state

if (global.game.state == State.Briefing) {
	audio_play_sound(snd_ui_briefing, 0, false);
}

// Local vars
display = Reports.Default;
end_turn = false;
anim_lrs_state = {};
anim_siren_state = {};

// Conditionals
contactedbase = false;
askedforlrs = 0;
firstenemyspotted = false;
impulsehelp = false;

// One-time dialog flags
speech_damage = false;
speech_phaserfire = false;
speech_phaserhit = false;
speech_phaserwarn = false;
speech_suggestedlrs = false;
speech_torparm = false;

// Torpedoes data
torp_angle = 0;
torp_cx = -1;
torp_cy = -1;

// Local sector data
local_objects = [];
local_enemies = [];
local_stars = [];
local_bases = [];
attack_buffer = [];
attack_indexes = [];

enum Reports {
    Damage,
    Mission,
    Scan,
	Impulse,
	Warp,
	Torpedoes,
	Help,
	Default
}

enum Condition {
	Green,
	Yellow,
	Red,
	Stranded,
	Destroyed,
	NoTime,
	Win
}