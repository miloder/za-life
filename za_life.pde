// An evolutionary version of Particle Life.
// By Terence Soule of Programming Chaos https://www.youtube.com/channel/UC2rO9hEjJkjqzktvtj0ggNQ
// Sets of particles (cells) share forces and share food.
// They can die of starvation or collect enough food to reproduce/
int numTypes = 7;  // 0 is food, plus 5 more, type 1 'eats' food the others just generate forces
float friction = 0.95;
int minPopulation = 20;
// int numFood = 0; // starting amount of food - Removed to maintain constant particle count
int foodRange = 1; // distance to collect food
int foodEnergy = 10; // energy from food
int reproductionEnergy = 1000; 
int startingEnergy = 400;
float gravitationStrength = 5; // Earth gravity strength
boolean gravitationInverted = false;
boolean mouseWasPressed = false; // Tracks the previous state of the mouse button
float K = 0.2;
ArrayList<cell> swarm;
ArrayList<particle> food;
boolean display = true; // whether or not to display, d toggles, used to evolve faster
boolean drawLines = false; // whether or not to draw lines connecting a cell's particles, l to toggle

float new_width = width / 1000.0;
float new_height = height / 1000.0;

void setup() {
  //size(800, 1000);
  fullScreen();
  colorMode(HSB, 360, 100, 100);
  noStroke();
  swarm = new ArrayList<cell>();
  for (int i = 0; i < minPopulation; i++) {
    swarm.add(new cell(random(new_width), random(new_height)));
  }
  food = new ArrayList<particle>();
  // Removed food initialization loop to maintain constant particle count
  noStroke();
}

void draw() {
  background(0);
  for (cell c : swarm) { // update and display each cell
    c.update();
    if(display){
      c.display();
    }
  }
  // Removed dead cell removal loop to maintain constant particle count
  eat();  // cells collect nearby food
  // Removed replace function call to maintain constant particle count
  // Removed reproduce function call to maintain constant particle count
  
  // Apply gravitational pull away from the mouse to each particle
  applyMouseGravitation();
  
  if(display){
    for (particle p : food) {
       p.display();
    }
  }
  // Removed food addition loop to maintain constant particle count
  //println(frameRate); // to see how changes effect efficiency
}

void applyMouseGravitation() {
  PVector mousePos = new PVector(mouseX, mouseY);

  for (particle p : food) {
    PVector dir = PVector.sub(p.position, mousePos); // Direction from mouse to particle
    dir.normalize(); // Normalize to get direction only
    dir.mult(gravitationStrength); // Apply gravity strength with possible inversion
    p.position.add(dir); // Move particle in the direction away from or towards the mouse
  }

  for (cell c : swarm) {
    for (particle p : c.swarm) {
      PVector dir = PVector.sub(p.position, mousePos); // Direction from mouse to particle
      dir.normalize(); // Normalize to get direction only
      dir.mult(gravitationStrength); // Apply gravity strength with possible inversion
      p.position.add(dir); // Move particle in the direction away from or towards the mouse
    }
  }
}

// Removed convertToFood function to maintain constant particle count

// Removed reproduce function to maintain constant particle count

// Removed replace function to maintain constant particle count

void eat() {
  float dis;
  PVector vector = new PVector(0, 0);
  for (cell c : swarm) {  // for every cell
    for (particle p : c.swarm) {  // for every particle in every cell
      if (p.type == 1) { // 1 is the eating type of paricle
        for (int i = food.size()-1; i >= 0; i--) {  // for every food particle - yes this gets slow
          particle f = food.get(i);
          vector.mult(0);
          vector = f.position.copy();
          vector.sub(p.position); 
          if (vector.x > width * 0.5) { vector.x -= width; }
          if (vector.x < width * -0.5) { vector.x += width; }
          if (vector.y > height * 0.5) { vector.y -= height; }
          if (vector.y < height * -0.5) { vector.y += height; }
          dis = vector.mag();
          if(dis < foodRange){
            c.energy += foodEnergy; // gain 100 energy for eating food 
            // Removed food removal to maintain constant particle count
          }
        }
      }
    }
  }
}

void keyPressed(){
  if(key == 'd'){
    display = !display;
  } else if(key == 'l'){
    drawLines = !drawLines;
  } else if (key == 'z' || key == 'Z') {
    gravitationStrength = abs(gravitationStrength); // Normal gravity
  } else if (key == 'x' || key == 'X') {
    gravitationStrength = -abs(gravitationStrength); // Inverted gravity
  } else if (key == 'c' || key == 'C') {
    gravitationStrength = 0; // No gravity
  } else if (key == '-' && gravitationStrength > 0) {
    gravitationStrength = max(0, gravitationStrength - 0.5); // Decrease gravity strength
  } else if (key == '=') {
    gravitationStrength += 0.5; // Increase gravity strength
  }
}
