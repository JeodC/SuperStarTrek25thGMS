particle_update();

explosion_timer -= 1;
if (explosion_timer <= 0) {
  instance_destroy();
}