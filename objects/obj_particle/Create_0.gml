// Number of particles per explosion
particles_count = 120;

// Create the particles array local to this instance
particles = array_create(particles_count);

for (var i = 0; i < particles_count; i++) {
  particles[i] = Particles();
}

// Explosion lifetime timer (steps)
explosion_timer = 0;

function particle_update() {
  for (var i = 0; i < array_length(particles); i++) {
    var p = particles[i];
    if (p.alive) {
      p.cx += p.vx / p.mass * 2.0;
      p.cy += p.vy / p.mass * 1.5;
      p.r -= 0.1;
      if (p.r < 0.1)
        p.alive = false;
    }
  }
}

function particle_draw() {
  gpu_set_blendmode(bm_add);
  for (var i = 0; i < array_length(particles); i++) {
    var p = particles[i];
    if (p.alive) {
      var fraction = p.r_i / 6.0;
      var col_index =
          clamp(floor(p.r * fraction), 0, array_length(global.p_colors) - 1);
      draw_set_color(global.p_colors[col_index]);
      draw_point(p.cx, p.cy);
    }
  }
  gpu_set_blendmode(bm_normal);
}