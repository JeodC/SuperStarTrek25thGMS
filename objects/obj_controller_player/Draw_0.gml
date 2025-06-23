// @obj_controller_player_Draw
/// @description: Handles game state

// Only draw if the current game has not ended
if ((global.game.state == State.Playing) && global.inputmode.mode != InputMode.UI) {
	var sector = global.galaxy[global.ent.sx][global.ent.sy];
	
	// Draw the screen contents
	draw_ship_console(display);
	
	// If we're in red alert draw the red border and animate the siren
	if (sector.enemynum > 0) {
		draw_redalert();
		draw_animation(spr_fg_siren, 0, 0, 0.05, 0, anim_siren_state);
	}

	// Pick what to draw
    switch (display) {
		case Reports.Default:
			if (global.ent.condition != Condition.Win) {
				draw_sector_contents();
			}
			draw_hover_text();
			break;
		case Reports.Warp:
			draw_galaxy_map();
			break;
		case Reports.Impulse:
			draw_sector_contents();
			draw_impulse_grid();
			break;
		case Reports.Torpedoes:
			draw_sector_contents();
			draw_torpedo_reticle();
			break;
		case Reports.Help:
			draw_sprite(spr_bg_help, 0, 0, 0);
			break;
		default:
			break;
	}
	
	// If the bridge is showing draw the energy bars
	if (global.inputmode.mode != InputMode.Warp) {
		draw_energy_bars();
		
		// Draw any additional decorations
		draw_animation(spr_fg_lrs, 0, 0, 0.1, 0, anim_lrs_state);
	}
	
	// If we're adjusting the shield or phaser levels display the hud
	if (!global.busy && global.inputmode.mode == InputMode.Manage) {
	    draw_level_hud();
	    draw_numbers();
	}
}