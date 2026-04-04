// ===================== PARÁMETROS GENERALES =====================

// Dominio matemático
float xmin = -3;
float xmax = 7;
float ymin = -3;
float ymax = 7;

// Tamaño del enjambre
int puntos = 100;
Particle[] fl;

// Visualización
float d = 10;          // radio de partícula
int areaPlot = 600;    // zona donde se dibuja el mapa

// Mejor global
float gbestx, gbesty, gbest;

// Parámetros PSO
float w = 0.7;         // inercia
float C1 = 1.8;        // factor cognitivo
float C2 = 1.8;        // factor social
float maxv = 12;       // velocidad máxima en pixeles

// Contadores
int evals = 0;
int evals_to_best = 0;

// Iteraciones
int iteracion = 0;
int maxIteraciones = 300;

// Historial para gráficos
float[] historialBest = new float[maxIteraciones];
float[] historialAvg  = new float[maxIteraciones];


// ===================== FUNCIÓN RASTRIGIN =====================
float rastrigin(float x, float y) {
  return 20
       + (x*x - 10*cos(TWO_PI*x))
       + (y*y - 10*cos(TWO_PI*y));
}


// ===================== CLASE PARTÍCULA =====================
class Particle {
  float x, y;          // posición actual en pantalla
  float vx, vy;        // velocidad en pantalla
  float fit;           // fitness actual

  float px, py;        // mejor posición personal
  float pfit;          // mejor fitness personal

  Particle() {
    x = random(areaPlot);
    y = random(areaPlot);

    vx = random(-2, 2);
    vy = random(-2, 2);

    fit = Float.MAX_VALUE;
    pfit = Float.MAX_VALUE;
    px = x;
    py = y;
  }

  float Eval() {
    evals++;

    // Convertir de pantalla a dominio matemático
    float rx = map(x, 0, areaPlot, xmin, xmax);
    float ry = map(y, 0, areaPlot, ymin, ymax);

    fit = rastrigin(rx, ry);

    // actualizar mejor personal
    if (fit < pfit) {
      pfit = fit;
      px = x;
      py = y;
    }

    // actualizar mejor global
    if (fit < gbest) {
      gbest = fit;
      gbestx = x;
      gbesty = y;
      evals_to_best = evals;
    }

    return fit;
  }

  void move() {
    vx = w * vx
       + C1 * random(1) * (px - x)
       + C2 * random(1) * (gbestx - x);

    vy = w * vy
       + C1 * random(1) * (py - y)
       + C2 * random(1) * (gbesty - y);

    // limitar velocidad
    float modu = sqrt(vx*vx + vy*vy);
    if (modu > maxv) {
      vx = vx / modu * maxv;
      vy = vy / modu * maxv;
    }

    // actualizar posición
    x = x + vx;
    y = y + vy;

    // rebote en bordes del área del mapa
    if (x > areaPlot) {
      x = areaPlot;
      vx = -vx;
    }
    if (x < 0) {
      x = 0;
      vx = -vx;
    }
    if (y > areaPlot) {
      y = areaPlot;
      vy = -vy;
    }
    if (y < 0) {
      y = 0;
      vy = -vy;
    }
  }

  void display() {
    fill(255);
    noStroke();
    ellipse(x, y, d, d);

    // vector de velocidad
    stroke(255, 0, 0);
    line(x, y, x - 4*vx, y - 4*vy);
  }
}


// ===================== PROMEDIO DEL ENJAMBRE =====================
float calcularPromedioPSO() {
  float suma = 0;
  for (int i = 0; i < puntos; i++) {
    suma += fl[i].fit;
  }
  return suma / puntos;
}


// ===================== HEATMAP =====================
void drawHeatMap() {
  loadPixels();

  for (int i = 0; i < areaPlot; i++) {
    for (int j = 0; j < areaPlot; j++) {
      float rx = map(i, 0, areaPlot, xmin, xmax);
      float ry = map(j, 0, areaPlot, ymin, ymax);

      float v = rastrigin(rx, ry);

      float col = map(v, 0, 80, 0, 255);
      col = constrain(col, 0, 255);

      pixels[j * width + i] = color(col, 0, 255 - col);
    }
  }

  updatePixels();
}


// ===================== GRÁFICO MEJOR FITNESS =====================
void drawBestFitnessGraph(int x0, int y0, int wGraph, int hGraph) {
  fill(20);
  stroke(255);
  rect(x0, y0, wGraph, hGraph);

  float maxVal = 0;
  for (int i = 0; i < iteracion; i++) {
    if (historialBest[i] > maxVal) maxVal = historialBest[i];
  }
  if (maxVal == 0) maxVal = 1;

  // ejes
  stroke(180);
  line(x0 + 40, y0 + hGraph - 30, x0 + wGraph - 10, y0 + hGraph - 30);
  line(x0 + 40, y0 + 10, x0 + 40, y0 + hGraph - 30);

  // curva
  stroke(0, 255, 0);
  noFill();
  beginShape();
  for (int i = 0; i < iteracion; i++) {
    float px = map(i, 0, maxIteraciones - 1, x0 + 40, x0 + wGraph - 10);
    float py = map(historialBest[i], 0, maxVal, y0 + hGraph - 30, y0 + 10);
    vertex(px, py);
  }
  endShape();

  fill(255);
  text("Mejor fitness vs iteracion", x0 + 10, y0 - 10);
  text("0", x0 + 28, y0 + hGraph - 10);
  text(nf(maxVal, 1, 2), x0 + 5, y0 + 20);
}


// ===================== GRÁFICO FITNESS PROMEDIO =====================
void drawAverageFitnessGraph(int x0, int y0, int wGraph, int hGraph) {
  fill(20);
  stroke(255);
  rect(x0, y0, wGraph, hGraph);

  float maxVal = 0;
  for (int i = 0; i < iteracion; i++) {
    if (historialAvg[i] > maxVal) maxVal = historialAvg[i];
  }
  if (maxVal == 0) maxVal = 1;

  // ejes
  stroke(180);
  line(x0 + 40, y0 + hGraph - 30, x0 + wGraph - 10, y0 + hGraph - 30);
  line(x0 + 40, y0 + 10, x0 + 40, y0 + hGraph - 30);

  // curva
  stroke(255, 140, 0);
  noFill();
  beginShape();
  for (int i = 0; i < iteracion; i++) {
    float px = map(i, 0, maxIteraciones - 1, x0 + 40, x0 + wGraph - 10);
    float py = map(historialAvg[i], 0, maxVal, y0 + hGraph - 30, y0 + 10);
    vertex(px, py);
  }
  endShape();

  fill(255);
  text("Promedio fitness vs iteracion", x0 + 10, y0 - 10);
  text("0", x0 + 28, y0 + hGraph - 10);
  text(nf(maxVal, 1, 2), x0 + 5, y0 + 20);
}


// ===================== MEJOR GLOBAL EN PANTALLA =====================
void despliegaBest() {
  fill(0, 255, 0);
  stroke(255);
  ellipse(gbestx, gbesty, 14, 14);

  fill(255);
  textSize(14);
  text("Mejor Fitness: " + nf(gbest, 1, 4), 20, 20);
  text("Evaluaciones: " + evals, 20, 40);
  text("Iteracion: " + iteracion, 20, 60);
}


// ===================== SETUP =====================
void setup() {
  size(1200, 700);
  smooth();

  gbest = Float.MAX_VALUE;

  fl = new Particle[puntos];
  for (int i = 0; i < puntos; i++) {
    fl[i] = new Particle();
    fl[i].Eval();   // evaluación inicial
  }

  historialBest[0] = gbest;
  historialAvg[0] = calcularPromedioPSO();
  iteracion = 1;
}


// ===================== DRAW =====================
void draw() {
  background(0);

  drawHeatMap();

  // mostrar partículas
  for (int i = 0; i < puntos; i++) {
    fl[i].display();
  }

  despliegaBest();

  drawBestFitnessGraph(650, 80, 500, 220);
  drawAverageFitnessGraph(650, 380, 500, 220);

  // avanzar iteraciones
  if (iteracion < maxIteraciones) {
    for (int i = 0; i < puntos; i++) {
      fl[i].move();
      fl[i].Eval();
    }

    historialBest[iteracion] = gbest;
    historialAvg[iteracion] = calcularPromedioPSO();
    iteracion++;
  }
}
