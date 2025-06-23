var col = (floor(timer / 4) mod 2 == 0) ? color1 : color2;

gpu_set_blendmode(bm_add);
draw_set_color(col);
draw_line_width(sx, sy, ex, ey, 1.2); // Thickness of 2 pixels
gpu_set_blendmode(bm_normal);