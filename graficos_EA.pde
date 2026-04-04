// ===================== PARÁMETROS GENERALES =====================
int tamPoblacion = 100;
float probCruzamiento = 0.8;
float probMutacion = 0.15;

float xmin = -3;
float xmax = 7;
float ymin = -3;
float ymax = 7;

Individuo[] poblacion;

float gbest;
float gbestx, gbesty;
int evals = 0;

int d = 6;

// área donde se dibuja el mapa de calor
int areaPlot = 600;

// control de generaciones
int generacion = 0;
int maxGeneraciones = 300;

// historial para gráficos
float[] historialBest = new float[maxGeneraciones];
float[] historialAvg = new float[maxGeneraciones];

// ===================== CLASE INDIVIDUO =====================
class Individuo {
  float x, y;       // coordenadas en pantalla
  float fitness;    // fitness evaluado en dominio matemático

  Individuo() {
    x = random(areaPlot);
    y = random(areaPlot);
    fitness = Float.MAX_VALUE;
  }

  void evaluar() {
    float rx = map(x, 0, areaPlot, xmin, xmax);
    float ry = map(y, 0, areaPlot, ymin, ymax);

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

// ===================== FUNCIÓN RASTRIGIN =====================
float rastrigin(float x, float y) {
  return 20
       + (x*x - 10*cos(TWO_PI*x))
       + (y*y - 10*cos(TWO_PI*y));
}

// ===================== FITNESS PROMEDIO =====================
float calcularPromedioEA() {
  float suma = 0;
  for (int i = 0; i < tamPoblacion; i++) {
    suma += poblacion[i].fitness;
  }
  return suma / tamPoblacion;
}

// ===================== SETUP =====================
void setup() {
  size(1200, 700);
  smooth();

  gbest = Float.MAX_VALUE;
  poblacion = new Individuo[tamPoblacion];

  for (int i = 0; i < tamPoblacion; i++) {
    poblacion[i] = new Individuo();
    poblacion[i].evaluar();
  }

  historialBest[0] = gbest;
  historialAvg[0] = calcularPromedioEA();
  generacion = 1;
}

// ===================== SELECCIÓN POR TORNEO =====================
Individuo seleccionar() {
  Individuo a = poblacion[int(random(tamPoblacion))];
  Individuo b = poblacion[int(random(tamPoblacion))];
  return (a.fitness < b.fitness) ? a : b;
}

// ===================== CRUZAMIENTO INTERMEDIO =====================
Individuo cruzar(Individuo p1, Individuo p2) {
  Individuo hijo = new Individuo();

  float alpha = random(0, 1);
  hijo.x = lerp(p1.x, p2.x, alpha);
  hijo.y = lerp(p1.y, p2.y, alpha);

  return hijo;
}

// ===================== MUTACIÓN GAUSSIANA =====================
void mutar(Individuo ind) {
  if (random(1) < probMutacion) {
    ind.x += randomGaussian() * 15;
    ind.y += randomGaussian() * 15;

    ind.x = constrain(ind.x, 0, areaPlot);
    ind.y = constrain(ind.y, 0, areaPlot);
  }
}

// ===================== NUEVA GENERACIÓN =====================
void nuevaGeneracion() {
  Individuo[] nueva = new Individuo[tamPoblacion];

  // ELITISMO: mantener al mejor actual
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

// ===================== HEATMAP =====================
void drawHeatMap() {
  loadPixels();

  for (int i = 0; i < areaPlot; i++) {
    for (int j = 0; j < areaPlot; j++) {
      float rx = map(i, 0, areaPlot, xmin, xmax);
      float ry = map(j, 0, areaPlot, ymin, ymax);

      float val = rastrigin(rx, ry);
      float c = map(val, 0, 80, 0, 255);
      c = constrain(c, 0, 255);

      pixels[j * width + i] = color(c, 50, 255 - c);
    }
  }

  updatePixels();
}

// ===================== GRÁFICO MEJOR FITNESS =====================
void drawBestFitnessGraph(int x0, int y0, int w, int h) {
  fill(20);
  stroke(255);
  rect(x0, y0, w, h);

  float maxVal = 0;
  for (int i = 0; i < generacion; i++) {
    if (historialBest[i] > maxVal) maxVal = historialBest[i];
  }
  if (maxVal == 0) maxVal = 1;

  stroke(180);
  line(x0 + 40, y0 + h - 30, x0 + w - 10, y0 + h - 30); // eje X
  line(x0 + 40, y0 + 10, x0 + 40, y0 + h - 30);         // eje Y

  stroke(0, 255, 0);
  noFill();
  beginShape();
  for (int i = 0; i < generacion; i++) {
    float px = map(i, 0, maxGeneraciones - 1, x0 + 40, x0 + w - 10);
    float py = map(historialBest[i], 0, maxVal, y0 + h - 30, y0 + 10);
    vertex(px, py);
  }
  endShape();

  fill(255);
  text("Mejor fitness vs generacion", x0 + 10, y0 - 10);
  text("0", x0 + 30, y0 + h - 10);
  text(nf(maxVal, 1, 2), x0 + 5, y0 + 20);
}

// ===================== GRÁFICO FITNESS PROMEDIO =====================
void drawAverageFitnessGraph(int x0, int y0, int w, int h) {
  fill(20);
  stroke(255);
  rect(x0, y0, w, h);

  float maxVal = 0;
  for (int i = 0; i < generacion; i++) {
    if (historialAvg[i] > maxVal) maxVal = historialAvg[i];
  }
  if (maxVal == 0) maxVal = 1;

  stroke(180);
  line(x0 + 40, y0 + h - 30, x0 + w - 10, y0 + h - 30); // eje X
  line(x0 + 40, y0 + 10, x0 + 40, y0 + h - 30);         // eje Y

  stroke(255, 140, 0);
  noFill();
  beginShape();
  for (int i = 0; i < generacion; i++) {
    float px = map(i, 0, maxGeneraciones - 1, x0 + 40, x0 + w - 10);
    float py = map(historialAvg[i], 0, maxVal, y0 + h - 30, y0 + 10);
    vertex(px, py);
  }
  endShape();

  fill(255);
  text("Promedio fitness vs generacion", x0 + 10, y0 - 10);
  text("0", x0 + 30, y0 + h - 10);
  text(nf(maxVal, 1, 2), x0 + 5, y0 + 20);
}

// ===================== LOOP PRINCIPAL =====================
void draw() {
  background(0);

  drawHeatMap();

  // dibujar población
  for (int i = 0; i < tamPoblacion; i++) {
    poblacion[i].display();
  }

  // dibujar mejor global
  fill(0, 255, 0);
  stroke(255);
  ellipse(gbestx, gbesty, 12, 12);

  // texto informativo
  fill(255);
  textSize(14);
  text("Mejor Fitness: " + nf(gbest, 1, 4), 20, 20);
  text("Evaluaciones: " + evals, 20, 40);
  text("Generacion: " + generacion, 20, 60);

  // gráficos
  drawBestFitnessGraph(650, 80, 500, 220);
  drawAverageFitnessGraph(650, 380, 500, 220);

  // avanzar generaciones
  if (generacion < maxGeneraciones) {
    nuevaGeneracion();
    historialBest[generacion] = gbest;
    historialAvg[generacion] = calcularPromedioEA();
    generacion++;
  }
}
