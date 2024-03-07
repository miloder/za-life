// Global constants for particle size and density
final int PARTICLE_SIZE = 2; // Example size
final float DAMPENING_FACTOR = 0.5; // Dampening factor to reduce overexcited motion
final int TRAIL_LENGTH = 60; // Length of the trail to keep track of

class particle { // or a cell of a colony or an organelle of a cell
  PVector position;
  PVector velocity;
  float density; // Added density property
  int type;
  ArrayList<PVector> trail; // Stores the previous positions to create a trail effect

  // constructor
  particle(PVector start, int t) {
    position = new PVector(start.x, start.y);
    velocity = new PVector(0, 0);
    type = t;
    density = 1.0; // Default density value
    trail = new ArrayList<PVector>(); // Initialize the trail list
  }
  // Method to apply a force to this particle
  void applyForce(PVector force) {
    // Adjust the force by the particle's density
    //force.div(density);
    // Add the force to the particle's velocity
    velocity.add(force);
  }
  // Check for collisions with other particles
  void checkCollisions(ArrayList<particle> particles) {
    for (particle other : particles) {
      if (other != this) {
        float d = PVector.dist(this.position, other.position);
        float collisionDistance = PARTICLE_SIZE; // Assuming particles are circles with diameter PARTICLE_SIZE
        if (d < collisionDistance) {
          // Simple elastic collision response
          PVector collisionVector = PVector.sub(this.position, other.position);
          collisionVector.normalize();
          collisionVector.mult(2 * (this.velocity.dot(collisionVector) - other.velocity.dot(collisionVector)));
          collisionVector.mult(0.5); // Adjust this factor to simulate different elasticity
          this.velocity.sub(collisionVector);
          this.velocity.mult(0.8); // Scale down velocity by 0.8 with each collision
          other.velocity.add(collisionVector);
          other.velocity.mult(0.8); // Scale down velocity by 0.8 with each collision

          // Reposition particles to avoid overlap, assuming equal radii
          float overlap = 0.5 * (collisionDistance - d);
          PVector correctionVector = collisionVector.copy();
          correctionVector.mult(overlap);
          this.position.add(correctionVector);
          other.position.sub(correctionVector);
        }
      }
    }
  }

  // applies forces based on this cell's particles
  void applyInternalForces(cell c) {
    PVector totalForce = new PVector(0, 0);
    PVector acceleration = new PVector(0, 0);
    PVector vector = new PVector(0, 0);
    float dis;
    for (particle p : c.swarm) {
      if (p != this) {
        vector.mult(0);
        vector = p.position.copy();
        vector.sub(position);
        if (vector.x > width * 0.5) {
          vector.x -= width;
        }
        if (vector.x < width * -0.5) {
          vector.x += width;
        }
        if (vector.y > height * 0.5) {
          vector.y -= height;
        }
        if (vector.y < height * -0.5) {
          vector.y += height;
        }
        dis = vector.mag();
        vector.normalize();
        if (dis < c.internalMins[type][p.type]) {
          PVector force = vector.copy();
          force.mult(abs(c.internalForces[type][p.type])*-3*K);
          force.mult(map(dis, 0, c.internalMins[type][p.type], 1, 0));
          totalForce.add(force);
        }
        if (dis < c.internalRadii[type][p.type]) {
          PVector force = vector.copy();
          force.mult(c.internalForces[type][p.type]*K);
          force.mult(map(dis, 0, c.internalRadii[type][p.type], 1, 0));
          totalForce.add(force);
        }
      }
    }
    acceleration = totalForce.copy();
    acceleration.div(density); // Apply density to acceleration
    acceleration.mult(DAMPENING_FACTOR); // Apply dampening to reduce overexcited motion
    velocity.add(acceleration);

    position.add(velocity);
    position.x = (position.x + width)%width;
    position.y = (position.y + height)%height;
    velocity.mult(friction);
  }
  
  // applies forces based on other cell's particles 
  void applyExternalForces(cell c) {
    PVector totalForce = new PVector(0, 0);
    PVector acceleration = new PVector(0, 0);
    PVector vector = new PVector(0, 0);
    float dis;
    for (cell other : swarm) { // for each other cell in the swarm
      if (other != c) {  // don't apply external forces within this cell
        for (particle p : other.swarm) { // for each particle in the other cell
          vector.mult(0);
          vector = p.position.copy();
          vector.sub(position);
          if (vector.x > width * 0.5) {
            vector.x -= width;
          }
          if (vector.x < width * -0.5) {
            vector.x += width;
          }
          if (vector.y > height * 0.5) {
            vector.y -= height;
          }
          if (vector.y < height * -0.5) {
            vector.y += height;
          }
          dis = vector.mag();
          vector.normalize();
          if (dis < c.externalMins[type][p.type]) {
            PVector force = vector.copy();
            force.mult(abs(c.externalForces[type][p.type])*-3*K);
            force.mult(map(dis, 0, c.externalMins[type][p.type], 1, 0));
            totalForce.add(force);
          }
          if (dis < c.externalRadii[type][p.type]) {
            PVector force = vector.copy();
            force.mult(c.externalForces[type][p.type]*K);
            force.mult(map(dis, 0, c.externalRadii[type][p.type], 1, 0));
            totalForce.add(force);
          }
        }
      }
    }
    acceleration = totalForce.copy();
    acceleration.div(density); // Apply density to acceleration
    acceleration.mult(DAMPENING_FACTOR); // Apply dampening to reduce overexcited motion
    velocity.add(acceleration);
    position.add(velocity);
    position.x = (position.x + width)%width;
    position.y = (position.y + height)%height;
    velocity.mult(friction);
  }

  // applies forces based on nearby food particles
  void applyFoodForces(cell c) {
    PVector totalForce = new PVector(0, 0);
    PVector acceleration = new PVector(0, 0);
    PVector vector = new PVector(0, 0);
    float dis;
    int preyType = (type + 1) % numTypes; // Determine the prey type in the food chain
    for (particle p : c.swarm) {  // for all particles in the cell
      if (p.type == preyType) { // Check if the particle is the prey
        vector.mult(0);
        vector = p.position.copy();
        vector.sub(position);
        if (vector.x > width * 0.5) {
          vector.x -= width;
        }
        if (vector.x < width * -0.5) {
          vector.x += width;
        }
        if (vector.y > height * 0.5) {
          vector.y -= height;
        }
        if (vector.y < height * -0.5) {
          vector.y += height;
        }
        dis = vector.mag();
        vector.normalize();
        // Apply force only if the particle is within the hunting range
        if (dis < c.externalRadii[type][p.type]) {
          PVector force = vector.copy();
          force.mult(c.huntBehaviors[type][p.type]);
          force.mult(map(dis, 0, c.externalRadii[type][p.type], 1, 0));
          totalForce.add(force);
        }
      }
    }
    acceleration = totalForce.copy();
    acceleration.div(density); // Apply density to acceleration
    acceleration.mult(DAMPENING_FACTOR); // Apply dampening to reduce overexcited motion
    velocity.add(acceleration);
    position.add(velocity);
    position.x = (position.x + width)%width;
    position.y = (position.y + height)%height;
    velocity.mult(friction);
  }

  // display the particles with HSL color mapping and trail effect
  void display() {
    colorMode(HSB, 360, 100, 100); // Adjusted to match the colorMode in setup()
    float h = map(type % 2 == 0 ? type : numTypes - 1 - type, 0, numTypes-1, 223, 240); // Hue interpolation with inversion for every other type
    float s = map(type % 2 == 0 ? type : numTypes - 1 - type, 0, numTypes-1, 57, 100);  // Saturation interpolation with inversion for every other type
    float l = map(type % 2 == 0 ? type : numTypes - 1 - type, 0, numTypes-1, 72, 100);  // Lightness interpolation with inversion for every other type
    
    // Draw the trail
    for (int i = 0; i < trail.size(); i++) {
      float alpha = map(i, 0, trail.size() - 1, 0, 255); // Gradually reduce opacity
      stroke(h, s, l, alpha);
      strokeWeight(PARTICLE_SIZE);
      point(trail.get(i).x, trail.get(i).y);
    }
    noStroke();
    
    // Draw the particle
    fill(h, s, l);
    circle(position.x, position.y, PARTICLE_SIZE); // Use the global constant for size
    colorMode(RGB, 255); // Reset color mode to default
    
    // Update the trail
    trail.add(0, position.copy()); // Add the current position to the start of the trail
    if (trail.size() > TRAIL_LENGTH) {
      trail.remove(trail.size() - 1); // Remove the oldest position if the trail is too long
    }
  }

  // Debugging method to print force values and distances
  void debugInteractions(cell c) {
    // ... (debugging code remains unchanged) ...
  }

  // Call this method in the main program loop to ensure update logic is running
  void checkUpdateCall() {
    // ... (update check code remains unchanged) ...
  }

  // Method to apply exaggerated forces for testing
  void applyExaggeratedForces(cell c) {
    // ... (exaggerated force application code remains unchanged) ...
  }
}
