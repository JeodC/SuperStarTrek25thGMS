var col = (floor(timer / 4) mod 2 == 0) ? color1 : color2;

gpu_set_blendmode(bm_add);
draw_set_color(col);
draw_line(sx, sy, ex, ey);
gpu_set_blendmode(bm_normal);