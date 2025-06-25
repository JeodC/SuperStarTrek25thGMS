/// @obj_controller_input_Create
/// @description: Handles inputs based on mode

// Globals
depth = 50;

global.input = {
  source : InputSource.Keyboard,
  changed : false,
  confirm : false,
  cancel : false,
  up : false,
  down : false,
  left : false,
  right : false,
  mx : 0,
  my : 0,
  programmatic_move : false,
};

global.inputmode = {
  mode : InputMode.UI,
  tmp_old : 0,
  tmp_new : 0,
  type : undefined,
  cursor_x : 0,
  cursor_y : 0,
  max_x : 8,
  max_y : 8,
};

enum InputSource {
  Mouse,
  Keyboard,
  Gamepad
}

// Modes
// None - No input
// UI - Generic mouse/keyboard/gamepad to scroll through and click on ui buttons
// and options sliders Bridge - Mouse/keyboard/gamepad to scroll through
// HoverState and confirm player action Warp - Mouse/keyboard/gamepad to scroll
// and select a sector to warp to on the galaxy map Impulse -
// Mouse/keyboard/gamepad to scroll and select an available cell to move to in
// the current sector Manage - Keyboard/gamepad to increment shields/phaser
// levels
enum InputMode {
  None,
  UI,
  Bridge,
  Warp,
  Impulse,
  Torpedoes,
  Manage
}

gp_buttons = [
  gp_face1,
  gp_face2,
  gp_face3,
  gp_face4,
  gp_shoulderl,
  gp_shoulderlb,
  gp_shoulderr,
  gp_shoulderrb,
  gp_padu,
  gp_padd,
  gp_padl,
  gp_padr,
  gp_stickl,
  gp_stickr,
  gp_start,
  gp_select,
];

delay = 0;
last_mx = 0;
last_my = 0;
keyboard_active = false;
attack_delay = 0;

action = -1;
hover_state = HoverState.None;
last_state = -1;

// Mouse hover regions
hover_regions = [
  // Shields bar
  {
    x1 : 82,
    x2 : 132,
    y1 : 12,
    y2 : 26,
    state : HoverState.Shields
  },
  // Left ship display
  {
    x1 : 0,
    x2 : 60,
    y1 : 70,
    y2 : 98,
    state : HoverState.Shields
  },
  // Right ship display
  {
    x1 : 260,
    x2 : 320,
    y1 : 70,
    y2 : 98,
    state : HoverState.Shields
  },
  // Energy bar
  {
    x1 : 137,
    x2 : 183,
    y1 : 12,
    y2 : 26,
    state : HoverState.Energy
  },
  // Terminal - Damage Report
  {
    x1 : 32,
    x2 : 43,
    y1 : 120,
    y2 : 132,
    state : HoverState.DamageStatus
  },
  // Scotty Report
  {
    x1 : 46,
    x2 : 64,
    y1 : 109,
    y2 : 145,
    state : HoverState.ScottStatus
  },
  // Warp Speed
  {
    x1 : 104,
    x2 : 124,
    y1 : 130,
    y2 : 145,
    state : HoverState.WarpSpeed
  },
  // Impulse Speed
  {
    x1 : 125,
    x2 : 138,
    y1 : 119,
    y2 : 155,
    state : HoverState.ImpulseSpeed
  },
  // Warp Map
  {
    x1 : 138,
    x2 : 180,
    y1 : 155,
    y2 : 194,
    state : HoverState.GalacticMap
  },
  // LRS
  {
    x1 : 145,
    x2 : 172,
    y1 : 130,
    y2 : 150,
    state : HoverState.LongRangeSensors
  },
  // Phasers
  {
    x1 : 180,
    x2 : 195,
    y1 : 127,
    y2 : 150,
    state : HoverState.Phasers
  },
  // Torpedoes
  {
    x1 : 203,
    x2 : 216,
    y1 : 127,
    y2 : 150,
    state : HoverState.Torpedoes
  },
  // Spock
  {
    x1 : 277,
    x2 : 306,
    y1 : 119,
    y2 : 150,
    state : HoverState.MissionStatus
  },
  // Uhura
  {
    x1 : 283,
    x2 : 309,
    y1 : 173,
    y2 : 193,
    state : HoverState.DockingProcedures
  },
  // Options
  {
    x1 : 60,
    x2 : 68,
    y1 : 42,
    y2 : 56,
    state : HoverState.Options
  },
  // Help
  {
    x1 : 250,
	x2 : 257,
	y1 : 42,
	y2 : 48,
	state : HoverState.Help},
];

all_regions = hover_regions;
srs_regions = [];
srs_index = -1;

enum HoverState {
  None,
  Shields,
  Energy,
  DamageStatus,
  ScottStatus,
  WarpSpeed,
  GalacticMap,
  ImpulseSpeed,
  LongRangeSensors,
  Phasers,
  Torpedoes,
  MissionStatus,
  DockingProcedures,
  Options,
  Help,
  Enemy,
}

// Map parameters (sector grid)
map_offset_x = 121;
map_offset_y = 31;
size_cell_x = 10;
size_cell_y = 9;