// obj_explosion - Create Event
// Assumes `lx` and `ly` are set BEFORE this runs

map_offset_x = 121;
map_offset_y = 31;
size_cell_x = 10;
size_cell_y = 9;

// Convert logical cell position to pixel/screen position
x = map_offset_x + lx * size_cell_x + size_cell_x / 2;
y = map_offset_y + ly * size_cell_y + size_cell_y / 2;

sprite_index = spr_grid_explosion
image_speed = 0.7