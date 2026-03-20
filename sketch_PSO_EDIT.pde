
//PImage surf; // imagen que entrega el fitness ELIMINAR DEPENDENCIA DE LA IMAGEN

// SE DEFINE EL DOMINIO MATEMATICO
float xmin = -3;
float xmax = 7;
float ymin = -3;
float ymax = 7;

int puntos = 100;
Particle[] fl; // arreglo de partículas
float d = 15; // radio del círculo, solo para despliegue
float gbestx, gbesty, gbest; // posición y fitness del mejor global
float w = 1000; // inercia: baja (~50): explotación, alta (~5000): exploración (2000 ok) ESTABA EN 1000
float C1 = 30, C2 =  10; // learning factors (C1: own, C2: social) (ok)
int evals = 0, evals_to_best = 0; //número de evaluaciones, sólo para despliegue
float maxv = 3; // max velocidad (modulo)


// FUNCION RASTRIGIN

float rastrigin(float x, float y){
  return 20
       + (x*x - 10*cos(TWO_PI*x))
       + (y*y - 10*cos(TWO_PI*y));
}


void drawHeatMap(){
  
  // se cargan los píxeles de la pantalla
  loadPixels();
  
  // se recorren las coordenadas en horizontal -->> i
  for(int i=0;i<width;i++){
    
    // se recorren las coordenadas en vertical -->> j
    for(int j=0;j<height;j++){
      
       // la funcion esta definida por x_i en [-3 , 7]
      float x = map(i,0,width,xmin,xmax);
      float y = map(j,0,height,ymin,ymax);
      
      // se evalúa la función rastrigin en ese punto
      float v = rastrigin(x,y);
      
      // El valor de la función se convierte en un color: bajo  azul y alto  rojo
      float col = map(v,0,80,0,255);
      col = constrain(col,0,255);
      
      // Luego se asigna ese color al pixel
      pixels[j*width+i] = color(col,0,255-col);
      
    }
  }

  updatePixels();
}

// FUNCIONES PARA PASAR AL DOMINIO MATEMATICO x_i

float screenToDomainX(float x){
  return map(x,0,width,xmin,xmax);
}

float screenToDomainY(float y){
  return map(y,0,height,ymin,ymax);
}

class Particle{
  float x, y, fit; // current position(x-vector)  and fitness (x-fitness)
  float px, py, pfit; // position (p-vector) and fitness (p-fitness) of best solution found by particle so far
  float vx, vy; //vector de avance (v-vector)
  
  // ---------------------------- Constructor
  Particle(){
    x = random (width); y = random(height);
    vx = random(-1,1) ; vy = random(-1,1);
    
    //pfit = -1; fit = -1; //asumiendo que no hay valores menores a -1 en la función de evaluación ELIMINAR YA QUE EL CODIGO ORIGINAL MAXIMIZABA
    
    // YA QUE EL IMINIMO LOCAL ES f(0,0) = 0
    pfit = Float.MAX_VALUE;
    fit = Float.MAX_VALUE;
  }
  
  // ---------------------------- Evalúa partícula
  //float Eval(PImage surf){ //recibe imagen que define función de fitness ELIMINAR DEPENDENCIA DE LA IMAGEN
    float Eval(){
    evals++;
    //color c=surf.get(int(x),int(y)); // obtiene color de la imagen en posición (x,y) ELIMINAR DEPENDENCIA DE LA IMAGEN
    //fit = red(c); //evalúa por el valor de la componente roja de la imagen ELIMINAR DEPENDENCIA DE LA IMAGEN
    
    // YA QUE LA FUNCION ESTA DEFINIDA EN EL DOMINIO -> [-3 , 7]
    
    float rx = map(x,0,width,xmin,xmax);
    float ry = map(y,0,height,ymin,ymax);

    fit = rastrigin(rx, ry);

    //if(fit > pfit){
    if(fit < pfit){ // SE CAMBIA > POR < YA QUE RASTRIGIN ES UNA FUNCION DE MINIMIZACION

      pfit = fit;
      px = x;
      py = y;
    }
    if (fit < gbest){ // SE CAMBIA > POR < YA QUE RASTRIGIN ES UNA FUNCION DE MINIMIZACION
      gbest = fit;
      gbestx = x;
      gbesty = y;
      evals_to_best = evals;
      println(str(gbest));
    };
    return fit; //retorna la componente roja
  }
  
  // ------------------------------ mueve la partícula
  void move(){

    
    
    // AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
    // vx = w * vx + random(0,1)*(px - x) + random(0,1)*(gbestx - x);
    // vy = w * vy + random(0,1)*(py - y) + random(0,1)*(gbesty - y);
    
    vx = w*vx 
       + C1*random(1)*(px-x)
       + C2*random(1)*(gbestx-x);

    vy = w*vy 
       + C1*random(1)*(py-y)
       + C2*random(1)*(gbesty-y);

     // AHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

    // trunca velocidad a maxv
    float modu = sqrt(vx*vx + vy*vy);
    if (modu > maxv){
      vx = vx/modu*maxv;
      vy = vy/modu*maxv;
    }
    // update position
    x = x + vx;
    y = y + vy;
    // rebota en murallas
    if (x > width || x < 0) vx = - vx;
    if (y > height || y < 0) vy = - vy;
  }
  
  // ------------------------------ despliega partícula
  void display(){
     // color c=surf.get(int(x),int(y)); ELIMINAR DEPENDENCIA DE LA IMAGEN
     // fill(c); ELIMINAR DEPENDENCIA DE LA IMAGEN
     fill(255); // EL COLOR AHORA VENDRA DEL MAPA DE CALOR, LAS PARTICULAS PUEDEN SER BLANCAS
    ellipse (x,y,d,d);
    // dibuja vector
    stroke(#ff0000);
    line(x,y,x-10*vx,y-10*vy);
  }
} //fin de la definición de la clase Particle


// dibuja punto azul en la mejor posición y despliega números
void despliegaBest(){
  fill(#0000ff);
  ellipse(gbestx,gbesty,d,d);
  PFont f = createFont("Arial",16,true);
  textFont(f,15);
  fill(#00ff00);
  text("Best fitness: "+str(gbest)+"\nEvals to best: "+str(evals_to_best)+"\nEvals: "+str(evals),10,20);
}

// ===============================================================

void setup(){  

  // PARA QUE CUALQUIER EVALUACION INIACIL SEA MEJOR
  gbest = Float.MAX_VALUE;
  
  size(1024,512); //setea width y height (de acuerdo al tamaño de la imagen)
  //surf = loadImage("Moon_LRO_LOLA_global_LDEM_1024_b.jpg"); ELIMINAR DEPENDENCIA DE LA IMAGEN

  smooth();
  
  // crea arreglo de objetos partículas
  fl = new Particle[puntos];
  for(int i =0;i<puntos;i++)
    fl[i] = new Particle();
}

void draw(){
  
    drawHeatMap(); // SE HACE LA LLAMADA AL HEAT

  //image(surf,0,0); ELIMINAR DEPENDENCIA DE LA IMAGEN
  for(int i = 0;i<puntos;i++){
    fl[i].display();
  }
  despliegaBest();
  //mueve puntos
  

  
  for(int i = 0;i<puntos;i++){
    fl[i].move();
    // fl[i].Eval(surf); ELIMINAR DEPENDENCIA DE LA IMAGEN
    fl[i].Eval();
  }
  
}
