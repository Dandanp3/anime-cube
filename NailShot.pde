/**
 * NailShot.pde — Projétil do Johnny (unha giratória)
 *
 * Tipos de comportamento por Act do Tusk:
 *   Act 1: voa em linha reta, stuna 1 inimigo, para
 *   Act 2: stuna + ricocheteia 1 vez no inimigo mais próximo
 *   Act 3: stuna + ricocheteia 2 vezes
 *   Act 4: atravessa TODOS em linha reta + ricocheteia 2x nos mais próximos não atingidos
 */
class NailShot {

  float x, y;
  float vx, vy;
  float speed = 9.0;

  int   tuskAct;   // 1, 2, 3 ou 4
  int   damage;

  boolean active = true;
  float stunFrames = 60;  // set by JohnnyPlayer

  // Ricochet control
  int   ricochetsLeft;
  ArrayList<Enemy> hitEnemies = new ArrayList<Enemy>();

  // Rotação visual
  float angle = 0;

  // Cor: amarelada (unhas do Johnny)
  color shotColor = color(255, 220, 60);

  NailShot(float sx, float sy, int act, int dmg, float stunF) {
    x = sx; y = sy;
    tuskAct = act;
    damage     = dmg;
    stunFrames = stunF;

    // Tiro sempre sobe verticalmente (direção fixa para cima)
    vx = 0;
    vy = -speed;

    // Número de ricochets por act
    if (act == 1) ricochetsLeft = 0;
    if (act == 2) ricochetsLeft = 1;
    if (act == 3) ricochetsLeft = 2;
    if (act == 4) ricochetsLeft = 2;  // depois do pierce
  }

  void update() {
    if (!active) return;
    x += vx;
    y += vy;
    angle += 0.3;

    // Sai da tela
    if (x < -20 || x > SCREEN_W + 20 || y < -20 || y > SCREEN_H + 20) {
      active = false;
    }
  }

  void draw() {
    if (!active) return;

    pushMatrix();
    translate(x, y);
    rotate(angle);

    // Glow amarelo
    for (int i = 3; i > 0; i--) {
      fill(255, 220, 60, 30 * i);
      noStroke();
      ellipse(0, 0, 14 + i * 4, 14 + i * 4);
    }

    // Corpo da unha (losango)
    fill(shotColor);
    noStroke();
    beginShape();
    vertex(0, -9);
    vertex(5, 0);
    vertex(0, 9);
    vertex(-5, 0);
    endShape(CLOSE);

    // Brilho central
    fill(255, 255, 200, 200);
    ellipse(0, 0, 4, 4);

    popMatrix();
  }

  /**
   * Testa colisão com todos os inimigos.
   * Aplica dano, stun e ricochet conforme o act.
   * Retorna true se o projétil deve ser destruído (act 1, 2, 3 após hit).
   */
  boolean checkCollisions(ArrayList<Enemy> enemies) {
    if (!active) return false;

    for (int i = 0; i < enemies.size(); i++) {
      Enemy e = enemies.get(i);
      if (!e.isAlive()) continue;
      if (hasHit(e))    continue;

      // Hitbox: verifica só sobreposição no eixo X (tiro vertical, pierce reto)
      // Act 4 usa AABB estreito; acts 1/2/3 usam colisão circular normal
      boolean hit;
      if (tuskAct == 4) {
        float shotR = 6;
        hit = abs(x - e.x) < (e.SIZE / 2 + shotR) &&
              abs(y - e.y) < (e.SIZE / 2 + shotR);
      } else {
        float d = dist(x, y, e.x, e.y);
        hit = d < e.SIZE / 2 + 6;
      }
      if (hit) {
        hitEnemies.add(e);
        boolean killed = e.takeDamage(damage);
        if (!killed) e.applyStun(stunFrames);

        spawnStunParticles(e.x, e.y);
        spawnImpactParticles(e.x, e.y, color(255, 220, 60));

        if (tuskAct == 4) {
          // Act 4: continua voando (pierce) — não para aqui
          // ricochet é resolvido após sair da tela ou em outro método
          continue;
        }

        // Acts 1/2/3: para no primeiro hit, depois ricocheteia
        if (ricochetsLeft > 0) {
          doRicochet(enemies);
        } else {
          active = false;
        }
        return false;
      }
    }
    return false;
  }

  /** Ricocheteia para o inimigo vivo mais próximo não já atingido */
  void doRicochet(ArrayList<Enemy> enemies) {
    Enemy target = findClosestUnhit(enemies);
    if (target == null) { active = false; return; }

    ricochetsLeft--;
    float d = dist(x, y, target.x, target.y);
    if (d < 1) d = 1;
    vx = (target.x - x) / d * speed;
    vy = (target.y - y) / d * speed;
  }

  /** Act 4: resolve ricochets para inimigos fora da linha de tiro */
  void resolveAct4Ricochets(ArrayList<Enemy> enemies) {
    for (int r = 0; r < 2; r++) {
      if (ricochetsLeft <= 0) break;
      Enemy target = findClosestUnhit(enemies);
      if (target == null) break;
      ricochetsLeft--;
      hitEnemies.add(target);
      boolean killed = target.takeDamage(damage);
      if (!killed) target.applyStun();
      spawnStunParticles(target.x, target.y);
      spawnImpactParticles(target.x, target.y, color(255, 220, 60));
    }
    active = false;
  }

  Enemy findClosestUnhit(ArrayList<Enemy> enemies) {
    Enemy best = null;
    float bestD = 9999;
    for (Enemy e : enemies) {
      if (!e.isAlive()) continue;
      if (hasHit(e))    continue;
      float d = dist(x, y, e.x, e.y);
      if (d < bestD) { bestD = d; best = e; }
    }
    return best;
  }

  boolean hasHit(Enemy e) {
    for (int i = 0; i < hitEnemies.size(); i++)
      if (hitEnemies.get(i) == e) return true;
    return false;
  }

  boolean isActive() { return active; }
}
