class cell{  // or colony of cells
  // Constants for cell configuration
  final float INTERNAL_FORCE_MIN = 0.1;
  final float INTERNAL_FORCE_MAX = 0.5;
  final float EXTERNAL_FORCE_MIN = -0.5;
  final float EXTERNAL_FORCE_MAX = 0.5;
  final float INTERNAL_MIN_DISTANCE = 40;
  final float INTERNAL_MAX_DISTANCE = 70;
  final float EXTERNAL_MIN_DISTANCE = 40;
  final float EXTERNAL_MAX_DISTANCE = 70;
  final float RADIUS_MULTIPLIER = 2;
  final float MAX_RADIUS = 300;
  final float POSITION_OFFSET_MIN = -50;
  final float POSITION_OFFSET_MAX = 50;
  final float DENSITY_MUTATION_MIN = -0.05;
  final float DENSITY_MUTATION_MAX = 0.05;
  final float DENSITY_MIN = 0.1;
  final float DENSITY_MAX = 2.0;
  final float FORCE_MUTATION_MIN = -0.1;
  final float FORCE_MUTATION_MAX = 0.1;
  final float MIN_DISTANCE_MUTATION_MIN = -5;
  final float MIN_DISTANCE_MUTATION_MAX = 5;
  final float RADIUS_MUTATION_MIN = -10;
  final float RADIUS_MUTATION_MAX = 10;
  final float POSITION_MUTATION_MIN = -5;
  final float POSITION_MUTATION_MAX = 5;
  final float TYPE_CHANGE_CHANCE = 0; // Percentage chance to change type
  final float HUNT_FORCE = 5.0; // Force applied when hunting prey
  final float FLEE_FORCE = -5.0; // Force applied when fleeing from predator
  
  ArrayList<particle> swarm; // shouldn't have used the name swarm again
  float internalForces[][];
  float externalForces[][];
  float internalMins[][];
  float externalMins[][];
  float internalRadii[][];
  float externalRadii[][];
  PVector positions[];  // probably better as an arraylist
  int numParticles = 100;
  int energy = startingEnergy;
  int radius; // avg distance from center
  PVector center = new PVector(0,0); // center of the cell
  float density = 5.0; // Particle density parameter affecting internal forces and cohesion
  float huntBehaviors[][]; // Genome for hunting behavior
  float fleeBehaviors[][]; // Genome for fleeing behavior
  
  cell(float x, float y){
    internalForces = new float[numTypes][numTypes];
    externalForces = new float[numTypes][numTypes];
    internalMins = new float[numTypes][numTypes];
    externalMins = new float[numTypes][numTypes];
    internalRadii = new float[numTypes][numTypes];
    externalRadii = new float[numTypes][numTypes];
    huntBehaviors = new float[numTypes][numTypes];
    fleeBehaviors = new float[numTypes][numTypes];
    // Positions are the initial relative positions of all of the particles.
    // This is critical to cells starting in a 'good' configuration.
    positions = new PVector[numParticles];
    swarm = new ArrayList<particle>();
    generateNew(x,y);
  }
  
  // generate the parameters for a new cell
  // note: all of the random ranges could be tweaked
  void generateNew(float x, float y){
    for(int i = 0; i < numTypes; i++){
      for(int j= 0; j < numTypes; j++){
        internalForces[i][j] = random(INTERNAL_FORCE_MIN, INTERNAL_FORCE_MAX) * density; // internal forces are initially attractive, but can mutate
        internalMins[i][j] = random(INTERNAL_MIN_DISTANCE, INTERNAL_MAX_DISTANCE);
        internalRadii[i][j] = random(internalMins[i][j]*RADIUS_MULTIPLIER, MAX_RADIUS); // minimum 'primary' force range must be twice repulsive range
        externalForces[i][j] = random(EXTERNAL_FORCE_MIN, EXTERNAL_FORCE_MAX); // external forces could be attractive or repulsive
        externalMins[i][j] = random(EXTERNAL_MIN_DISTANCE, EXTERNAL_MAX_DISTANCE);
        externalRadii[i][j] = random(externalMins[i][j]*RADIUS_MULTIPLIER, MAX_RADIUS);
        // Initialize hunting and fleeing behaviors in the genome
        huntBehaviors[i][j] = (i == (j + 1) % numTypes) ? HUNT_FORCE : 0; // Set hunting force if j is prey of i
        fleeBehaviors[i][j] = (i == (j - 1 + numTypes) % numTypes) ? FLEE_FORCE : 0; // Set fleeing force if j is predator of i
      }
    }
    for(int  i = 0; i < numParticles; i++){
      positions[i] = new PVector(x+random(POSITION_OFFSET_MIN, POSITION_OFFSET_MAX), y+random(POSITION_OFFSET_MIN, POSITION_OFFSET_MAX));
      swarm.add(new particle(positions[i], 1+(int)random(numTypes-1))); // type 0 is food
    }
  }
  
  // Used to copy the values from a parent cell to a daughter cell.
  // (I don't trust deep copy when data structures get complex :)
  void copyCell(cell c){
    density = c.density;
    for(int i = 0; i < numTypes; i++){
      for(int j= 0; j < numTypes; j++){
        internalForces[i][j] = c.internalForces[i][j];
        internalMins[i][j] = c.internalMins[i][j];
        internalRadii[i][j] = c.internalRadii[i][j];
        externalForces[i][j] = c.externalForces[i][j];
        externalMins[i][j] = c.externalMins[i][j];
        externalRadii[i][j] = c.externalRadii[i][j];
        huntBehaviors[i][j] = c.huntBehaviors[i][j]; // Copy hunting behavior
        fleeBehaviors[i][j] = c.fleeBehaviors[i][j]; // Copy fleeing behavior
      }
    }
    float x = random(width);
    float y = random(height);
    for(int  i = 0; i < numParticles; i++){
      positions[i] = new PVector(x+c.positions[i].x,y+c.positions[i].y);
      particle p = swarm.get(i);
      particle temp = new particle(p.position,p.type); // create a new particle from the parent
      swarm.add(temp); // add to the new cell
    }
  }
  
  // When a new cell is created from a 'parent' cell the new cell's values are mutated
  // This mutates all values a 'little' bit. Mutating a few values by a larger amount could work better
  void mutateCell(){
    density += random(DENSITY_MUTATION_MIN, DENSITY_MUTATION_MAX); // Mutate the density slightly
    density = constrain(density, DENSITY_MIN, DENSITY_MAX); // Ensure density stays within reasonable bounds
    for(int i = 0; i < numTypes; i++){
      for(int j= 0; j < numTypes; j++){  
        internalForces[i][j] += random(FORCE_MUTATION_MIN, FORCE_MUTATION_MAX);
        internalMins[i][j] += random(MIN_DISTANCE_MUTATION_MIN, MIN_DISTANCE_MUTATION_MAX);
        internalRadii[i][j] += random(RADIUS_MUTATION_MIN, RADIUS_MUTATION_MAX);
        externalForces[i][j] += random(FORCE_MUTATION_MIN, FORCE_MUTATION_MAX);
        externalMins[i][j] += random(MIN_DISTANCE_MUTATION_MIN, MIN_DISTANCE_MUTATION_MAX);
        externalRadii[i][j] += random(RADIUS_MUTATION_MIN, RADIUS_MUTATION_MAX);
        // Mutate hunting and fleeing behaviors
        huntBehaviors[i][j] += (i == (j + 1) % numTypes) ? random(FORCE_MUTATION_MIN, FORCE_MUTATION_MAX) : 0;
        fleeBehaviors[i][j] += (i == (j - 1 + numTypes) % numTypes) ? random(FORCE_MUTATION_MIN, FORCE_MUTATION_MAX) : 0;
      }
    }
    for(int  i = 0; i < numParticles; i++){
      positions[i] = new PVector(positions[i].x+random(POSITION_MUTATION_MIN, POSITION_MUTATION_MAX), positions[i].y+random(POSITION_MUTATION_MIN, POSITION_MUTATION_MAX));
      if(random(100)< TYPE_CHANGE_CHANCE){  // 10% of the time a particle changes type
        particle p = swarm.get(i);
        p.type = 1+(int)random(numTypes-1);
      }
    } // Could also mutate the number of particles in the cell
  }
  
  // update a cell by applying each type of forces to each particle in the cell
  void update(){
    for(int i = 0; i < swarm.size(); i++){ // for each particle in this cell
      particle p = swarm.get(i);
      p.applyInternalForces(this);
      p.applyExternalForces(this);
      p.applyFoodForces(this);
      // Check for eating and chasing or fleeing
      int preyType = (p.type + 1) % numTypes;
      int predatorType = (p.type - 1 + numTypes) % numTypes;
      for(particle other : swarm){
        float distance = PVector.dist(p.position, other.position);
        if(other.type == preyType && distance < foodRange){
          PVector chaseForce = PVector.sub(other.position, p.position);
          chaseForce.normalize();
          chaseForce.mult(huntBehaviors[p.type][other.type]);
          p.applyForce(chaseForce); // Apply hunting behavior force
          other.type = p.type; // Convert the prey to the eater's type
        } else if (other.type == predatorType && distance < foodRange) {
          PVector fleeForce = PVector.sub(p.position, other.position);
          fleeForce.normalize();
          fleeForce.mult(fleeBehaviors[p.type][other.type]);
          p.applyForce(fleeForce); // Apply fleeing behavior force
        }
      }
    }
    energy -= 1.0; // cells lose one energy/timestep - should be a variable. Or dependent on forces generated
  }
  
  void display(){
    // Code to draw lines between the particles in a cell
    if(drawLines){
      particle p1, p2;
     stroke(0,0,30);
     for(int  i = 0; i < numParticles-1; i++){
       p1 = swarm.get(i);
       p2 = swarm.get(i+1);
       line(p1.position.x,p1.position.y,p2.position.x,p2.position.y);
     }
    }
    noStroke();
    for(particle p: swarm){
      p.display();
    }
  }
}
