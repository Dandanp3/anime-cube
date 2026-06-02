/**
 * TrainDoor.pde — Portas de trem do soco nível 5 do Hakari
 *
 * Duas portas cinzas nas laterais do inimigo que se fecham,
 * esmagando e aplicando dano extra massivo.
 */
class TrainDoor {

  float targetX, targetY;    // posição do inimigo alvo
  Enemy target;

  // Portas: esquerda e direita
  float leftX, rightX;       // posições X atuais das portas
  float finalLeftX, finalRightX;  // posições de fechamento (centro do inimigo)

  float doorW = 30, doorH = 52;
  float speed = 14;

  boolean closed   = false;
  boolean done     = false;
  boolean damaged  = false;   // dano já aplicado?
  int     holdTimer = 0;
  final int HOLD_FRAMES = 18; // frames que fica fechada antes de sumir

  int extraDamage = 30;

  TrainDoor(Enemy e) {
    target  = e;
    targetX = e.x;
    targetY = e.y;

    // Portas começam 80px afastadas
    leftX        = e.x - 80;
    rightX       = e.x + 80;
    finalLeftX   = e.x - doorW / 2;
    finalRightX  = e.x + doorW / 2;
  }

  void update() {
    if (done) return;

    // Atualiza posição alvo caso inimigo se mova
    if (target != null && target.isAlive()) {
      targetX = target.x;
      targetY = target.y;
    }

    if (!closed) {
      // Move portas em direção ao centro
      leftX  = lerp(leftX,  targetX - doorW / 2, 0.25);
      rightX = lerp(rightX, targetX + doorW / 2, 0.25);

      float distL = abs(leftX - (targetX - doorW / 2));
      float distR = abs(rightX - (targetX + doorW / 2));

      if (distL < 3 && distR < 3) {
        closed = true;
        // Aplica dano ao fechar
        if (!damaged && target != null && target.isAlive()) {
          damaged = true;
          target.takeDamage(extraDamage);
          spawnImpactParticles(targetX, targetY, color(180, 180, 200));
          spawnImpactParticles(targetX, targetY, color(255, 255, 255));
        }
      }
    } else {
      holdTimer++;
      if (holdTimer >= HOLD_FRAMES) done = true;
    }
  }

  void draw() {
    if (done) return;

    float ty = targetY;

    // Sombra
    fill(0, 0, 0, 60);
    noStroke();
    rectMode(CENTER);
    rect(leftX  + 3, ty + 4, doorW, doorH);
    rect(rightX + 3, ty + 4, doorW, doorH);

    // Porta esquerda
    color doorC = closed ? color(100, 100, 110) : color(140, 140, 155);
    fill(doorC);
    rect(leftX, ty, doorW, doorH, 3);

    // Porta direita
    rect(rightX, ty, doorW, doorH, 3);

    // Detalhes: janelas nas portas
    fill(60, 80, 120, 180);
    rect(leftX,  ty - 10, doorW - 8, 10, 2);
    rect(rightX, ty - 10, doorW - 8, 10, 2);

    // Barra horizontal de metal
    fill(100, 100, 115);
    rect(leftX,  ty + 8, doorW, 4);
    rect(rightX, ty + 8, doorW, 4);

    // Flash branco ao fechar
    if (closed && holdTimer < 4) {
      fill(255, 255, 255, 200 - holdTimer * 50);
      rect(targetX, ty, doorW * 2 + 4, doorH + 4, 3);
    }

    rectMode(CORNER);
  }

  boolean isDone() { return done; }
}
