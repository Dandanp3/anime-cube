/**
 * JohnnyPlayer.pde — Johnny Joestar
 *
 * Aparência: cubo azul-acinzentado com estrelas (ref: roupa do Johnny)
 * Companion: TuskCompanion ao lado direito
 *
 * Upgrades disponíveis (gerenciados pelo GameManager):
 *   0 = Evoluir Tusk (+1 act, mais dano, troca visual)
 *   1 = Aumentar tempo de stun (+0.2s por upgrade)
 *   2 = Reduzir cooldown do tiro (-0.2s, mínimo 0.5s)
 */
class JohnnyPlayer {

  final float W = 34, H = 34;
  float x, y;

  color bodyColor = color(140, 160, 200);   // azul-acinzentado
  color hatColor  = color(200, 200, 220);   // viseira branca

  int hitFlashTimer = 0;
  final int HIT_FLASH_DUR = 15;

  // Tiro
  ArrayList<NailShot> shots = new ArrayList<NailShot>();
  float shotCooldown      = 0;
  float shotCooldownMax   = 120;   // 2s em frames (60fps)
  final float COOLDOWN_MIN = 30;   // 0.5s mínimo

  // Stun
  float stunDuration = 60;   // 1s base em frames

  // Dano base
  int baseDamage = 1;

  // Nível do Tusk (act muda a cada 3 níveis: 3->act2, 6->act3, 9->act4)
  int tuskLevel = 0;

  // Companion
  TuskCompanion tusk;

  JohnnyPlayer(float sx, float sy) {
    x = sx; y = sy;
    tusk = new TuskCompanion();
    tusk.x = x + 44;
    tusk.y = y;
  }

  void update(ArrayList<Enemy> enemies) {
    x = constrain(mouseX, W / 2, SCREEN_W - W / 2);
    y = constrain(mouseY, H / 2, DEFENSE_LINE_Y - H / 2);

    if (shotCooldown > 0) shotCooldown--;

    // Atualiza tusk
    tusk.update(x, y, enemies, baseDamage);

    // Atualiza tiros
    for (int i = shots.size() - 1; i >= 0; i--) {
      NailShot s = shots.get(i);
      s.update();
      s.checkCollisions(enemies);

      // Act 4: quando sai da tela, resolve ricochets
      if (!s.isActive() && tusk.act == 4) {
        s.resolveAct4Ricochets(enemies);
      }

      if (!s.isActive()) shots.remove(i);
    }

    // Atualiza stun dos inimigos
    for (Enemy e : enemies) e.updateStun();

    if (hitFlashTimer > 0) hitFlashTimer--;
  }

  void draw() {
    // Tusk (atrás do Johnny)
    tusk.draw();

    // Tiros
    for (NailShot s : shots) s.draw();

    // Corpo do Johnny
    color bc = (hitFlashTimer > 0 && hitFlashTimer % 4 < 2) ? color(255) : bodyColor;
    fill(bc);
    rectMode(CENTER);
    rect(x, y, W, H, 4);

    // Viseira / chapéu (faixa branca no topo)
    fill(hatColor);
    rect(x, y - H/2 - 4, W + 4, 7, 2);
    // Detalhe da lua/ferradura
    noFill();
    stroke(210, 190, 50);
    strokeWeight(2);
    arc(x, y + 4, 20, 16, PI, TWO_PI);
    noStroke();

    // Estrelas decorativas no corpo
    fill(200, 200, 255, 120);
    drawStar5(x - 8, y + 6, 4, 2);
    drawStar5(x + 8, y - 4, 3, 1.5);

    // Olhos
    fill(30, 30, 80);
    ellipse(x - 7, y - 4, 6, 6);
    ellipse(x + 7, y - 4, 6, 6);
    fill(180, 200, 255);
    ellipse(x - 6, y - 5, 3, 3);
    ellipse(x + 8, y - 5, 3, 3);

    // Indicador de cooldown (arco ao redor do johny)
    if (shotCooldown > 0) {
      float pct = 1.0 - shotCooldown / shotCooldownMax;
      noFill();
      stroke(255, 220, 60, 160);
      strokeWeight(2.5);
      arc(x, y, W + 14, H + 14, -HALF_PI, -HALF_PI + TWO_PI * pct);
      noStroke();
    }

    rectMode(CORNER);
  }

  void triggerAttack() {
    if (shotCooldown > 0) return;
    shotCooldown = shotCooldownMax;

    // Dispara em direção ao mouse
    float sx = tusk.ultimateActive ? x : tusk.x;  // sai do Tusk se não estiver na ultimate
    shots.add(new NailShot(sx, tusk.y, tusk.act, baseDamage, stunDuration));
  }

  void activateUltimate() {
    tusk.activateUltimate(gm.enemies);
  }

  // Chamado pelo GameManager ao aplicar upgrade
  void upgradeTusk() {
    tuskLevel++;
    baseDamage++;
    // Act evolui a cada 3 níveis: nível 3->act2, 6->act3, 9->act4
    int newAct = 1 + (tuskLevel / 3);
    tusk.act = min(newAct, 4);
  }

  void upgradeStun() {
    stunDuration += 12;   // +0.2s (12 frames)
  }

  void upgradeCooldown() {
    shotCooldownMax = max(COOLDOWN_MIN, shotCooldownMax - 12);
  }

  // Passa a duração de stun para os inimigos via NailShot
  float getStunDuration() { return stunDuration; }

  int getTotalDamage() { return baseDamage; }

  void triggerHitFlash() { hitFlashTimer = HIT_FLASH_DUR; }

  void drawStar5(float cx, float cy, float r1, float r2) {
    float a = -HALF_PI;
    float step = TWO_PI / 5;
    beginShape();
    for (int i = 0; i < 5; i++) {
      vertex(cx + cos(a) * r1, cy + sin(a) * r1);
      a += step / 2;
      vertex(cx + cos(a) * r2, cy + sin(a) * r2);
      a += step / 2;
    }
    endShape(CLOSE);
  }
}
