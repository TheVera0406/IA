// ===== PARÁMETROS =====
int tamPoblacion = 2000;
float probCruzamiento = 0.8;
float probMutacion = 0.4;

Individuo[] poblacion;

float xmin = -5.12;
float xmax = 5.12;
float ymin = -5.12;
float ymax = 5.12;

float gbest;
float gbestx, gbesty;
int evals = 0;

int d = 6; 

// ===== CLASE INDIVIDUO =====
class Individuo {
  float x, y;
  float fitness;

  Individuo() {
    x = random(width);
    y = random(height);
  }

  void evaluar() {
    float rx = map(x, 0, width, xmin, xmax);
    float ry = map(y, 0, height, ymin, ymax);

    fitness = rastrigin(rx, ry);

    if (fitness < gbest) {
      gbest = fitness;
      gbestx = x;
      gbesty = y;
    }
    evals++;
  }

  void display() {
    fill(255);
    noStroke();
    ellipse(x, y, d, d);
  }
}

// ===== FUNCIÓN RASTRIGIN =====
float rastrigin(float x, float y) {
  return 20 + (x*x - 10*cos(TWO_PI*x)) + (y*y - 10*cos(TWO_PI*y));
}

// ===== SETUP =====
void setup(){  
  size(600, 600); // Tamaño cuadrado para mejor visualización
  gbest = Float.MAX_VALUE;
  poblacion = new Individuo[tamPoblacion];
  
  for(int i = 0; i < tamPoblacion; i++){
    poblacion[i] = new Individuo();
    poblacion[i].evaluar();
  }
}

// ===== SELECCIÓN (TORNEO) =====
Individuo seleccionar() {
  Individuo a = poblacion[int(random(tamPoblacion))];
  Individuo b = poblacion[int(random(tamPoblacion))];
  return (a.fitness < b.fitness) ? a : b;
}

// ===== CRUZAMIENTO (INTERMEDIO) =====
Individuo cruzar(Individuo p1, Individuo p2) {
  Individuo hijo = new Individuo();
  // El hijo es un promedio ponderado de los padres para mayor suavidad
  float alpha = random(0, 1);
  hijo.x = lerp(p1.x, p2.x, alpha);
  hijo.y = lerp(p1.y, p2.y, alpha);
  return hijo;
}

// ===== MUTACIÓN (GAUSSIANA) =====
void mutar(Individuo ind) {
  if (random(1) < probMutacion) {
    // El valor 15 controla el radio de exploración cerca del punto original
    ind.x += randomGaussian() * 15; 
    ind.y += randomGaussian() * 15;
    
    // Mantener dentro de los bordes
    ind.x = constrain(ind.x, 0, width);
    ind.y = constrain(ind.y, 0, height);
  }
}

// ===== NUEVA GENERACIÓN =====
void nuevaGeneracion() {
  Individuo[] nueva = new Individuo[tamPoblacion];

  // 1. ELITISMO: Mantener al mejor actual siempre vivo
  nueva[0] = new Individuo();
  nueva[0].x = gbestx;
  nueva[0].y = gbesty;
  nueva[0].evaluar();

  for (int i = 1; i < tamPoblacion; i++) {
    Individuo p1 = seleccionar();
    Individuo p2 = seleccionar();

    Individuo hijo;
    if (random(1) < probCruzamiento) {
      hijo = cruzar(p1, p2);
    } else {
      hijo = new Individuo();
      hijo.x = p1.x;
      hijo.y = p1.y;
    }

    mutar(hijo);
    hijo.evaluar();
    nueva[i] = hijo;
  }
  poblacion = nueva;
}

// ===== HEATMAP (DIBUJO) =====
void drawHeatMap() {
  loadPixels();
  for (int i = 0; i < width; i++) {
    for (int j = 0; j < height; j++) {
      float rx = map(i, 0, width, xmin, xmax);
      float ry = map(j, 0, height, ymin, ymax);
      float val = rastrigin(rx, ry);
      float c = map(val, 0, 80, 0, 255);
      pixels[j*width + i] = color(c, 50, 255-c);
    }
  }
  updatePixels();
}

// ===== LOOP PRINCIPAL =====
void draw(){
  drawHeatMap();

  for(int i = 0; i < tamPoblacion; i++){
    poblacion[i].display();
  }

  // Dibujar el mejor
  fill(0, 255, 0); 
  stroke(255);
  ellipse(gbestx, gbesty, 12, 12);

  // Info
  fill(255);
  text("Mejor Fitness: " + nf(gbest, 1, 4), 20, 20);
  text("Evaluaciones: " + evals, 20, 40);

  nuevaGeneracion();
}
