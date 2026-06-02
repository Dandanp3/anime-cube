/**
 * HakariPlayer.pde — Kinji Hakari (Jujutsu Kaisen)
 *
 * Aparência: cubo preto (jaqueta) com calça marrom e cabelo loiro
 *
 * Mecânicas:
 *   M1        → combo 3 socos (dir, esq, dir+knockback)
 *   Fervor    → barra que carrega ao acertar socos
 *   Jackpot   → slot machine 7-7-7, 20s de imortalidade + barrage
 *   Upgrades  → Probability Shift, Fever Rate, Dano/Combo
 */
class HakariPlayer {

  final float W = 34, H = 34;
  float x, y;

  // Visual
  color bodyColor   = color(25, 25, 30);     // jaqueta preta
  color pantsColor  = color(120, 80, 40);    // calça marrom
  color hairColor   = color(230, 210, 120);  // loiro

  int hitFlashTimer = 0;
  final int HIT_FLASH_DUR = 15;

  // Combo
  int   comboStage     = 0;       // 0=pronto, 1=soco1 ativo, 2=soco2, 3=soco3
  int   comboResetTimer = 0;      // frames até resetar combo se não clicar
  final int COMBO_WINDOW = 35;    // frames de janela entre socos
  int   attackCooldown = 0;
  int   attackCooldownMax = 14;   // frames entre socos do combo

  // Socos ativos
  ArrayList<PunchHit> punches = new ArrayList<PunchHit>();

  // Portas de trem ativas
  ArrayList<TrainDoor> trainDoors = new ArrayList<TrainDoor>();

  // Dano
  int   baseDamage  = 2;
  int   damageLevel = 0;   // 0-5, nível 5 desbloqueia train doors

  // Fervor (0.0 a 1.0)
  float fervor         = 0.0;
  float fervorPerHit   = 0.08;   // base: 8% por soco
  float fervorRate     = 1.0;    // multiplicador (Fever Rate upgrade)

  // Jackpot
  boolean jackpotActive  = false;
  float   jackpotTimer   = 0;
  final float JACKPOT_DURATION = 1200;  // 20s * 60

  // Probabilidade base do jackpot (0.0-1.0)
  float jackpotChance = 0.3;   // 30% base

  // Slot machine
  boolean slotActive     = false;
  boolean slotSpinning   = false;
  int     slotTimer      = 0;
  final int SLOT_SPIN_FRAMES = 180;  // 3s girando
  float[] slotValues     = {0, 0, 0};   // valores exibidos
  int[]   slotFinal      = {0, 0, 0};   // valores finais
  boolean slotIsJackpot  = false;
  int     slotStopTimer  = 0;  // para parar os rolos em sequência
  boolean[] slotStopped  = {false, false, false};

  // Fade branco de ativação
  float fadeWhite = 0;

  // Estado da expansão de domínio
  boolean domainActive   = false;  // jogo pausado durante slot
  boolean ryokiPlayed    = false;

  // Sons (carregados via soundManager)
  // soundManager.hakariRyoki, soundManager.hakariJackpot

  // Aura jackpot (partículas verdes)
  int auraTimer = 0;

  HakariPlayer(float sx, float sy) {
    x = sx;
    y = sy;
  }

  void update(ArrayList<Enemy> enemies) {
    x = constrain(mouseX, W / 2, SCREEN_W - W / 2);
    y = constrain(mouseY, H / 2, DEFENSE_LINE_Y - H / 2);

    if (hitFlashTimer   > 0) hitFlashTimer--;
    if (attackCooldown  > 0) attackCooldown--;
    if (comboResetTimer > 0) {
      comboResetTimer--;
      if (comboResetTimer == 0) comboStage = 0;
    }

    // Atualiza socos
    for (int i = punches.size() - 1; i >= 0; i--) {
      PunchHit p = punches.get(i);
      p.ownerX = x;
      p.ownerY = y;
      p.update();

      boolean trainDoorsOn = (damageLevel >= 5);
      boolean knockbackOn  = !jackpotActive;  // jackpot: sem knockback

      ArrayList<Enemy> hits = p.checkCollisions(enemies,
        getTotalDamage(), knockbackOn, trainDoorsOn);

      for (Enemy e : hits) {
        addFervor();
      }

      if (!p.isActive()) punches.remove(i);
    }

    // Atualiza portas de trem
    for (int i = trainDoors.size() - 1; i >= 0; i--) {
      TrainDoor td = trainDoors.get(i);
      td.update();
      if (td.isDone()) trainDoors.remove(i);
    }

    // Jackpot ativo: barrage automático + aura
    if (jackpotActive) {
      jackpotTimer--;
      auraTimer++;
      if (auraTimer % 4 == 0)
        spawnFireParticles_green(x + random(-20, 20), y + random(-20, 20));

      if (attackCooldown == 0) {
        fireBarrage(enemies);
        attackCooldown = 4;  // rapidíssimo no jackpot
      }

      if (jackpotTimer <= 0) endJackpot();
    }

    // Slot girando (jogo pausado, só atualiza slot)
    if (slotActive) updateSlot();

    // Fade branco
    if (fadeWhite > 0) fadeWhite -= 8;
  }

  // Disparo de barrage no jackpot (automático a cada frame de cooldown)
  void fireBarrage(ArrayList<Enemy> enemies) {
    if (punches.size() > 0) return;
    // Alterna L/R rapidamente
    int stg = (frameCount % 2 == 0) ? 1 : 2;
    PunchHit p = new PunchHit(x, y, stg);
    p.lifetime = 5;
    punches.add(p);

    ArrayList<Enemy> hits = p.checkCollisions(enemies, getTotalDamage(), false, false);
    for (Enemy e : hits) addFervor();
  }

  // Clique M1 pelo jogador
  void triggerAttack() {
    if (domainActive) return;
    if (jackpotActive) return;   // barrage é automático no jackpot
    if (attackCooldown > 0) return;

    comboStage++;
    if (comboStage > 3) comboStage = 1;

    punches.add(new PunchHit(x, y, comboStage));
    attackCooldown  = attackCooldownMax;
    comboResetTimer = COMBO_WINDOW;

    // Efeito sonoro no impacto
    if (comboStage == 3) {
      soundManager.play(soundManager.gomuSound);  // reutiliza som de impacto
    }
  }

  // Adiciona fervor e verifica ativação da expansão
  void addFervor() {
    if (domainActive || jackpotActive) return;
    fervor += fervorPerHit * fervorRate;
    if (fervor >= 1.0) {
      fervor = 1.0;
      activateDomain();
    }
  }

  // Ativa a Expansão de Domínio
  void activateDomain() {
    domainActive  = true;
    slotActive    = true;
    slotSpinning  = true;
    slotTimer     = 0;
    slotStopped[0] = slotStopped[1] = slotStopped[2] = false;
    slotStopTimer = 0;
    fadeWhite     = 255;

    // Sorteia resultado
    slotIsJackpot = (random(1.0) < jackpotChance);
    if (slotIsJackpot) {
      slotFinal[0] = slotFinal[1] = slotFinal[2] = 7;
    } else {
      // Garante que NÃO sejam todos iguais
      do {
        for (int i = 0; i < 3; i++) slotFinal[i] = (int) random(1, 10);
      } while (slotFinal[0] == slotFinal[1] && slotFinal[1] == slotFinal[2]);
    }

    soundManager.play(soundManager.hakariRyoki);
  }

  void updateSlot() {
    slotTimer++;

    // Valores giram rápido
    if (slotSpinning) {
      for (int i = 0; i < 3; i++) {
        if (!slotStopped[i]) slotValues[i] = (int) random(0, 10);
      }
    }

    // Para rolos em sequência após SLOT_SPIN_FRAMES
    if (slotTimer > SLOT_SPIN_FRAMES) {
      slotStopTimer++;
      // Para rolo 0 após 0 frames, rolo 1 após 20, rolo 2 após 40
      if (slotStopTimer >= 0  && !slotStopped[0]) { slotStopped[0] = true; slotValues[0] = slotFinal[0]; }
      if (slotStopTimer >= 20 && !slotStopped[1]) { slotStopped[1] = true; slotValues[1] = slotFinal[1]; }
      if (slotStopTimer >= 40 && !slotStopped[2]) { slotStopped[2] = true; slotValues[2] = slotFinal[2]; }
    }

    // Todos parados
    if (slotStopped[0] && slotStopped[1] && slotStopped[2]) {
      // Aguarda 60 frames mostrando resultado, depois resolve
      if (slotStopTimer >= 100) {
        slotActive   = false;
        slotSpinning = false;
        domainActive = false;
        fervor       = 0;

        if (slotIsJackpot) startJackpot();
      }
    }
  }

  void startJackpot() {
    jackpotActive = true;
    jackpotTimer  = JACKPOT_DURATION;
    auraTimer     = 0;
    comboStage    = 0;

    // Para música e toca tucadonka
    fadeMusicOut(0.0);
    soundManager.play(soundManager.hakariJackpot);
  }

  void endJackpot() {
    jackpotActive = false;
    jackpotTimer  = 0;
    soundManager.stop(soundManager.hakariJackpot);
    fadeMusicIn();
  }

  void spawnTrainDoors(Enemy e) {
    trainDoors.add(new TrainDoor(e));
  }

  // Partículas verdes do jackpot
  void spawnFireParticles_green(float px, float py) {
    for (int i = 0; i < 3; i++)
      particles.add(new Particle(px, py, color(50, 255, 100), true));
  }

  void draw() {
    // Portas de trem (atrás do hakari)
    for (TrainDoor td : trainDoors) td.draw();

    // Socos
    for (PunchHit p : punches) p.draw();

    // Corpo do Hakari
    color bc = (hitFlashTimer > 0 && hitFlashTimer % 4 < 2) ? color(255) : bodyColor;

    rectMode(CENTER);

    // Calça (parte de baixo)
    fill(pantsColor);
    rect(x, y + H / 2 - 4, W, H / 2, 2);

    // Jaqueta (corpo principal)
    fill(bc);
    rect(x, y - 2, W, H - 4, 4);

    // Capuz (triângulo no topo)
    fill(lerpColor(bodyColor, color(40, 40, 50), 0.5));
    triangle(x - W/2, y - H/2 + 2,
             x + W/2, y - H/2 + 2,
             x,       y - H/2 - 8);

    // Cabelo loiro
    fill(hairColor);
    rect(x, y - H/2 - 6, W - 6, 8, 3);
    // Topete
    rect(x + 4, y - H/2 - 12, 10, 8, 3);

    // Olhos
    fill(50, 40, 30);
    ellipse(x - 7, y - 5, 5, 5);
    ellipse(x + 7, y - 5, 5, 5);
    fill(200, 180, 140);
    ellipse(x - 6, y - 6, 2.5, 2.5);
    ellipse(x + 8, y - 6, 2.5, 2.5);

    // Botão da jaqueta
    fill(150, 130, 100);
    ellipse(x, y + 2, 5, 5);

    // Aura verde do jackpot
    if (jackpotActive) {
      noFill();
      for (int i = 4; i > 0; i--) {
        float pulse = sin(frameCount * 0.15) * 3;
        stroke(50, 255, 100, 45 * i);
        strokeWeight(i * 2.5);
        ellipse(x, y, W + 18 + i * 6 + pulse, H + 18 + i * 6 + pulse);
      }
      noStroke();
    }

    rectMode(CORNER);

    // Fade branco da ativação
    if (fadeWhite > 0) {
      fill(255, 255, 255, min(fadeWhite, 255));
      rect(0, 0, SCREEN_W, SCREEN_H);
    }
  }

  // HUD: barra de fervor + slot machine + jackpot timer
  void drawHUD() {
    float bx = 14;
    float by = SCREEN_H - 150;

    // Barra de Fervor
    fill(40, 40, 40, 200);
    rectMode(CORNER);
    rect(bx, by, 160, 22, 4);

    color fervorColor = jackpotActive ? color(50, 255, 100) :
                        (fervor >= 1.0 ? color(255, 220, 0) : color(200, 80, 255));
    fill(fervorColor);
    rect(bx, by, 160 * min(fervor, 1.0), 22, 4);

    fill(255); textSize(10); textAlign(LEFT, CENTER);
    text("FERVOR  " + (int)(fervor * 100) + "%", bx + 5, by + 11);
    noStroke();

    by += 28;

    // Jackpot timer
    if (jackpotActive) {
      fill(30, 60, 30, 200);
      rect(bx, by, 160, 22, 4);
      float pct = jackpotTimer / JACKPOT_DURATION;
      fill(50, 255, 100);
      rect(bx, by, 160 * pct, 22, 4);
      fill(0); textSize(10); textAlign(LEFT, CENTER);
      text("JACKPOT  " + nf(jackpotTimer / 60.0, 1, 1) + "s", bx + 5, by + 11);
    }

    // Probabilidade
    by += 28;
    fill(140, 100, 200); textSize(10); textAlign(LEFT, CENTER);
    text("777 chance: " + (int)(jackpotChance * 100) + "%", bx, by + 11);
    text("CD dmg Nv: " + damageLevel + "/5", bx, by + 24);

    // Slot machine (centralizada na tela, jogo pausado)
    if (slotActive) drawSlotMachine();

    textAlign(LEFT, BASELINE);
    rectMode(CORNER);
    noStroke();
  }

  void drawSlotMachine() {
    float cx = SCREEN_W / 2.0;
    float cy = SCREEN_H / 2.0;

    // Fundo escuro
    fill(0, 0, 0, 210);
    rectMode(CORNER);
    rect(0, 0, SCREEN_W, SCREEN_H);

    // Painel do slot
    fill(30, 20, 40);
    rectMode(CENTER);
    rect(cx, cy, 420, 200, 16);
    fill(60, 40, 80);
    rect(cx, cy, 416, 196, 14);

    // Título
    fill(255, 220, 0); textSize(22); textAlign(CENTER, CENTER);
    text("IDLE DEATH GAMBLE", cx, cy - 70);

    // 3 rolos
    float slotW = 80, slotH = 100;
    float spacing = 110;
    for (int i = 0; i < 3; i++) {
      float sx = cx - spacing + i * spacing;

      // Fundo do rolo
      fill(15, 10, 25);
      rect(sx, cy, slotW, slotH, 8);

      // Linha de seleção
      stroke(255, 220, 0, 160);
      strokeWeight(2);
      line(sx - slotW/2 + 4, cy - 2, sx + slotW/2 - 4, cy - 2);
      line(sx - slotW/2 + 4, cy + 22, sx + slotW/2 - 4, cy + 22);
      noStroke();

      // Número
      boolean is7 = slotStopped[i] && slotFinal[i] == 7;
      color numColor = is7 ? color(255, 220, 0) : color(200, 200, 220);
      if (!slotStopped[i]) numColor = color(180, 180, 200, 180);

      fill(numColor);
      textSize(is7 ? 52 : 44);
      text((int) slotValues[i], sx, cy + 14);

      // Brilho no 7
      if (is7) {
        noFill();
        for (int j = 3; j > 0; j--) {
          stroke(255, 220, 0, 40 * j);
          strokeWeight(j * 2);
          rect(sx, cy, slotW - 4, slotH - 4, 8);
        }
        noStroke();
      }
    }

    // Resultado
    if (slotStopped[0] && slotStopped[1] && slotStopped[2]) {
      if (slotIsJackpot) {
        fill(255, 220, 0); textSize(28);
        text("JACKPOT!!!  7 7 7", cx, cy + 80);
      } else {
        fill(180, 100, 200); textSize(20);
        text("Tente novamente...", cx, cy + 80);
      }
    } else {
      fill(160, 140, 180); textSize(14);
      text("rolando...", cx, cy + 80);
    }

    rectMode(CORNER); noStroke();
    textAlign(LEFT, BASELINE);
  }

  int getTotalDamage() {
    int dmg = baseDamage + damageLevel;
    if (jackpotActive) dmg = (int)(dmg * 2.5);
    return max(1, dmg);
  }

  void triggerHitFlash() { hitFlashTimer = HIT_FLASH_DUR; }
  boolean isDomainActive() { return domainActive; }
}
