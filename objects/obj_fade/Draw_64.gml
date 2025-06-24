fade -= fade_incr;

if (fade < 0)
{
    instance_destroy();
}

	draw_set_color(c_black);
	alpha(fade); 
    draw_rectangle(0, 0, room_width * display_get_gui_width(), room_height * display_get_gui_height(), 0);
	draw_set_color(c_black);
    alpha();

function alpha()
{
    if (argument_count == 1)
        draw_set_alpha(argument[0]);
    else
        draw_set_alpha(1);
}