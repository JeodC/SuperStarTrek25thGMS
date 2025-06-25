sx = offset_x + x1 * cell_w + cell_w / 2;
sy = offset_y + y1 * cell_h + cell_h / 2;
ex = offset_x + x2 * cell_w + cell_w / 2;
ey = offset_y + y2 * cell_h + cell_h / 2;

// Phaser color type (1 = red/orange, 2 = light/dark green)
switch (type) {
case 1:
  color1 = c_red;
  color2 = c_orange;
  break;
case 2:
  color1 = make_color_rgb(100, 255, 100); // light green
  color2 = make_color_rgb(0, 128, 0);     // dark green
  break;
default:
  color1 = c_white;
  color2 = c_gray;
}

// Update timer
timer++;
if (timer >= duration) {
  instance_destroy();
}
