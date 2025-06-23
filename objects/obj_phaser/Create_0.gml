// Create Event for obj_phaser

// Map parameters — grid offset and cell size
offset_x = 121;
offset_y = 31;
cell_w = 10;
cell_h = 9;

// Initialize phaser start/end coordinates (1-based cell coords)
x1 = 0;
y1 = 0;
x2 = 0;
y2 = 0;

// Initialize screen pixel coords (these will be recalculated each step if dynamic)
sx = 0;
sy = 0;
ex = 0;
ey = 0;

// Initialize phaser colors
type = 1
color1 = c_red;
color2 = c_orange;

// Animation timer and duration
timer = 0;
duration = 360;
