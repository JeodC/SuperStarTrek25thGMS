///@description: Struct for default Game values
function Game() {
  return {
    difficulty : 1, // Active session difficulty
    maxenergy : 3000,
    maxtorpedoes : 10,
    enemypower : 0,
    maxstars : 7,
    totalbases : 0,
    totalenemies : 0,
    initenemies : 0,
    maxdays : 0,
    date : 0,
    t0 : 0,
    score : 0,
    state : State.Title
  };
}

///@description: Struct for individual Sector contents
function Sector() {
  return {
    enemynum : -1,
    basenum : -1,
    starnum : -1,
    star_positions : [],
    available_cells : [],
    seen : false,
  };
}

///@description: Struct for single Enemy ship
function EnemyShip() {
  return {
      sx : 0, 
      sy : 0,
      lx : 0, 
      ly : 0, 
      energy : 0, 
      maxenergy : 0, 
      dir : 0
  };
}

///@description: Struct for single Starbase
function Starbase() {
  return {
    sx : 0,
    sy : 0,
    lx : 0,
    ly : 0,
    // energy: 0, // This seems unused?
  };
}

///@description: Struct for Particles effects data
function Particles() {
  return {
    cx : 0,
    cy : 0,
    vx : 0,
    vy : 0,
    mass : 0,
    r : 0,
    r_i : 0,
    alive : false
  };
}

///@description: Struct for default Enterprise ship state
function Ship() {
  var ship = {energy : global.game.maxenergy,
              torpedoes : global.game.maxtorpedoes,
              shields : 0,
              phasers : 0,
              condition : Condition.Green,
              isdocked : false,
              generaldamage : 0,
              system : {
                warp : 100,
                srs : 100,
                lrs : 100,
                phasers : 100,
                torpedoes : 100,
                navigation : 100,
                shields : 100
              },
              sx : -1,
              sy : -1,
              prev_sx : -1,
              prev_sy : -1,
              lx : 0,
              ly : 0,
              dir : 0,
              animating_impulse : false,
              current_x : 0,
              current_y : 0,
              path_idx : 0,

              /// @description: Moves the player along a path when new local
              /// coordinate is chosen
              impulse_move : function(path_array){
                  if (path_array == undefined ||
                      array_length(path_array) < 2) return false;

  self.animating_impulse = true;
  self.move_speed = 0.1;

  self.path = path_array; // array of [x,y] cells
  self.path_idx = 1;      // next step in path
  self.current_x = self.lx;
  self.current_y = self.ly;

  var target_cell = self.path[self.path_idx];
  self.target_x = target_cell[0];
  self.target_y = target_cell[1];

  var dx = self.target_x - self.current_x;
  var dy = self.target_y - self.current_y;
  self.dir = calculate_direction(dx, dy);

  return true;
}
,

    /// @description: Smoothly updates the direction and cell position while
    /// moving with impulse
    update_impulse_animation : function() {
  if (!self.animating_impulse)
    return false;

  var dx = self.target_x - self.current_x;
  var dy = self.target_y - self.current_y;
  var dist = sqrt(dx * dx + dy * dy);

  if (dist < self.move_speed) {
    // Snap to target
    self.current_x = self.target_x;
    self.current_y = self.target_y;
    self.lx = self.target_x;
    self.ly = self.target_y;

    self.path_idx++;

    if (self.path_idx >= array_length(self.path)) {
      self.animating_impulse = false;
      return true; // done moving
    } else {
      var next_cell = self.path[self.path_idx];
      self.target_x = next_cell[0];
      self.target_y = next_cell[1];

      var ndx = self.target_x - self.current_x;
      var ndy = self.target_y - self.current_y;
      self.dir = calculate_direction(ndx, ndy);
    }
  } else {
    // Continue movement towards target
    var nx = dx / dist;
    var ny = dy / dist;
    self.current_x += nx * self.move_speed;
    self.current_y += ny * self.move_speed;
  }

  return false;
}
}
;

return ship;
}