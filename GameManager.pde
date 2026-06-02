/**
 * GameManager.pde
 * Gerencia waves, vidas, upgrades e HUD.
 * Suporta upgrades de Luffy (Dano/Haki/Gear2) e Johnny (Tusk/Stun/Cooldown).
 */
class GameManager {

  static final int STATE_TITLE    = 0;
  static final int STATE_PLAYING  = 1;
  static final int STATE_UPGRADE  = 2;
  static final int STATE_GAMEOVER = 3;

  int state = STATE_TITLE;

  int currentWave = 0;
  int score       = 0;
  int lives       = BASE_LIVES;

  ArrayList<Enemy> enemies = new ArrayList<Enemy>();

  // Spawn
  int   enemiesToSpawn = 0;
  int   spawnTimer     = 0;
  int   spawnInterval  = 75;
  boolean bossSpawned  = false;
  boolean bossPending  = false;

  // Escalonamento
  final int BASE_ENEMIES  = 5;
  final int ENEMIES_SCALE = 3;
  final int BASE_HP       = 2;
  final int HP_SCALE      = 2;
  float baseSpeed() { return 1.0 + (currentWave - 1) * 0.15; }

  // Upgrade screen
  int[]   upgradeOptions = new int[3];
  boolean upgradeChosen  = false;
  float[] cardX = new float[3];
  float[] cardY = new float[3];
  final float CARD_W = 210, CARD_H = 290;

  // Boss warning
  int bossWarningTimer = 0;

  void startGame() {
    state       = STATE_PLAYING;
    currentWave = 0;
    score       = 0;
    lives       = BASE_LIVES;
    enemies.clear();
    resetPlayerStats();
    startNextWave();
  }

  void reset() { startGame(); }

  void resetPlayerStats() {
    if (chosenChar == CHAR_LUFFY && luffyPlayer != null) {
      luffyPlayer.baseDamage    = 1;
      luffyPlayer.hakiUnlocked  = false;
      luffyPlayer.hakiActive    = false;
      luffyPlayer.hakiDuration  = 600;
      luffyPlayer.hakiCooldown  = 0;
      luffyPlayer.gear2Unlocked = false;
      luffyPlayer.gear2Active   = false;
      luffyPlayer.gear2Duration = 600;
      luffyPlayer.gear2Cooldown = 0;
    }
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) {
      hakariPlayer.baseDamage   = 2;
      hakariPlayer.damageLevel  = 0;
      hakariPlayer.fervor       = 0;
      hakariPlayer.jackpotChance = 0.3;
      hakariPlayer.fervorRate   = 1.0;
    }
    if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) {
      johnnyPlayer.baseDamage     = 10;
      johnnyPlayer.shotCooldownMax = 90;
      johnnyPlayer.stunDuration   = 60;
      johnnyPlayer.tuskLevel      = 0;
      johnnyPlayer.tusk.act       = 1;
    }
  }

  void update() {
    if (state == STATE_PLAYING)  updatePlaying();
    if (state == STATE_UPGRADE)  updateUpgrade();
  }

  void updateUpgrade() {
    if (chosenChar == CHAR_LUFFY  && luffyPlayer  != null) luffyPlayer.update();
    if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) johnnyPlayer.update(enemies);
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) hakariPlayer.update(enemies);
  }

  void updatePlaying() {
    if (chosenChar == CHAR_LUFFY  && luffyPlayer  != null) luffyPlayer.update();
    if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) johnnyPlayer.update(enemies);
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) hakariPlayer.update(enemies);

    // Pausar update de inimigos durante expansao de dominio
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null && hakariPlayer.isDomainActive()) return;

    // Spawn
    if (enemiesToSpawn > 0) {
      spawnTimer++;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        spawnNormalEnemy();
        enemiesToSpawn--;
      }
    }

    // Boss
    if (bossPending && !bossSpawned && enemiesToSpawn == 0 && enemies.isEmpty()) {
      spawnBoss();
      bossSpawned   = true;
      bossPending   = false;
      bossWarningTimer = 120;
    }
    if (bossWarningTimer > 0) bossWarningTimer--;

    // Atualiza inimigos
    float px = (chosenChar == CHAR_LUFFY  && luffyPlayer  != null) ? luffyPlayer.x
             : (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) ? johnnyPlayer.x
             : (chosenChar == CHAR_HAKARI && hakariPlayer != null) ? hakariPlayer.x
             : SCREEN_W / 2.0;

    for (int i = enemies.size() - 1; i >= 0; i--) {
      Enemy e = enemies.get(i);
      e.update(px);

      if (e.crossedLine()) {
        enemies.remove(i);
        lives -= e.isBoss ? 2 : 1;
        if (chosenChar == CHAR_LUFFY  && luffyPlayer  != null) luffyPlayer.triggerHitFlash();
        if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) johnnyPlayer.triggerHitFlash();
        if (chosenChar == CHAR_HAKARI && hakariPlayer != null) hakariPlayer.triggerHitFlash();
        spawnImpactParticles(e.x, DEFENSE_LINE_Y, color(255, 50, 50));
        if (lives <= 0) { state = STATE_GAMEOVER; return; }
        continue;
      }

      // Colisão Luffy
      if (chosenChar == CHAR_LUFFY && luffyPlayer != null) {
        ArmAttack arm = luffyPlayer.getAttack();
        if (arm != null && arm.isActive()) {
          if (arm.checkHit(e)) {
            boolean killed = e.takeDamage(luffyPlayer.getTotalDamage());
            if (killed) { score += e.isBoss ? 100 * currentWave : 10 * currentWave; enemies.remove(i); continue; }
          }
        }
      }

      // Remove inimigos mortos pelo Johnny (NailShot mata via takeDamage mas não remove da lista)
      if (!e.isAlive()) {
        score += e.isBoss ? 100 * currentWave : 10 * currentWave;
        enemies.remove(i);
        continue;
      }
    }

    // Fim de wave
    if (enemiesToSpawn == 0 && !bossPending && enemies.isEmpty()) {
      upgradeChosen = false;
      sortUpgradeOptions();
      state = STATE_UPGRADE;
    }
  }

  void draw() {
    switch (state) {
      case STATE_TITLE:    drawTitle();    break;
      case STATE_PLAYING:  drawPlaying();  break;
      case STATE_UPGRADE:  drawUpgrade();  break;
      case STATE_GAMEOVER: drawGameOver(); break;
    }
  }

  void drawPlaying() {
    for (Enemy e : enemies) e.draw();
    if (chosenChar == CHAR_LUFFY  && luffyPlayer  != null) luffyPlayer.draw();
    if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) johnnyPlayer.draw();
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) hakariPlayer.draw();
    drawHUD();
    drawPowerHUD();
    if (bossWarningTimer > 0) {
      fill(200, 0, 0, map(bossWarningTimer, 0, 120, 0, 255));
      textSize(52); textAlign(CENTER, CENTER);
      text("!! BOSS !!", SCREEN_W/2.0, SCREEN_H/2.0 - 60);
      textAlign(LEFT, BASELINE);
    }
  }

  void drawHUD() {
    fill(255, 220, 50);  textSize(16); textAlign(RIGHT, TOP);
    text("WAVE  " + currentWave, SCREEN_W - 14, 12);
    fill(200, 200, 200); textSize(14);
    text("SCORE  " + score, SCREEN_W - 14, 34);
    fill(140, 140, 180); textSize(11);
    text("spawn:" + enemiesToSpawn + " ativos:" + enemies.size(), SCREEN_W - 14, 54);
    textAlign(LEFT, BASELINE);
  }

  void drawPowerHUD() {
    if (chosenChar == CHAR_LUFFY && luffyPlayer != null) drawLuffyHUD();
    if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) drawJohnnyHUD();
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) hakariPlayer.drawHUD();
  }

  void drawLuffyHUD() {
    float bx = 14, by = SCREEN_H - 130;
    LuffyPlayer p = luffyPlayer;

    if (p.hakiUnlocked) {
      fill(40, 40, 40, 180); rectMode(CORNER); rect(bx, by, 140, 24, 4);
      if (p.hakiActive) {
        fill(20, 20, 20); rect(bx, by, 140 * (p.hakiTimer / p.hakiDuration), 24, 4);
        fill(180, 180, 255); textSize(11); textAlign(LEFT, CENTER);
        text("HAKI  " + nf(p.hakiTimer/60.0, 1, 1) + "s", bx + 5, by + 12);
      } else if (p.hakiCooldown > 0) {
        fill(60, 60, 80); rect(bx, by, 140 * (1.0 - p.hakiCooldown / p.HAKI_COOLDOWN_FRAMES), 24, 4);
        fill(120, 120, 150); textSize(11); textAlign(LEFT, CENTER);
        text("[J] CD " + nf(p.hakiCooldown/60.0, 1, 1) + "s", bx + 5, by + 12);
      } else {
        fill(100, 255, 180); textSize(11); textAlign(LEFT, CENTER);
        text("[J] HAKI PRONTO", bx + 5, by + 12);
      }
    }

    by += 30;
    if (p.gear2Unlocked) {
      fill(60, 20, 20, 180); rectMode(CORNER); rect(bx, by, 140, 24, 4);
      if (p.gear2Active) {
        fill(180, 40, 40); rect(bx, by, 140 * (p.gear2Timer / p.gear2Duration), 24, 4);
        fill(255, 160, 160); textSize(11); textAlign(LEFT, CENTER);
        text("GEAR2  " + nf(p.gear2Timer/60.0, 1, 1) + "s", bx + 5, by + 12);
      } else if (p.gear2Cooldown > 0) {
        fill(80, 40, 40); rect(bx, by, 140 * (1.0 - p.gear2Cooldown / p.GEAR2_COOLDOWN_FRAMES), 24, 4);
        fill(150, 80, 80); textSize(11); textAlign(LEFT, CENTER);
        text("[G] CD " + nf(p.gear2Cooldown/60.0, 1, 1) + "s", bx + 5, by + 12);
      } else {
        fill(255, 120, 120); textSize(11); textAlign(LEFT, CENTER);
        text("[G] GEAR2 PRONTO", bx + 5, by + 12);
      }
    }
    textAlign(LEFT, BASELINE); rectMode(CORNER); noStroke();
  }

  void drawJohnnyHUD() {
    float bx = 14, by = SCREEN_H - 130;
    JohnnyPlayer p = johnnyPlayer;

    // Act do Tusk
    fill(220, 140, 180); textSize(12); textAlign(LEFT, CENTER);
    text("TUSK ACT " + p.tusk.act, bx, by);
    by += 20;

    // Cooldown do tiro (arco já desenhado no player, mas tb mostramos aqui)
    fill(40, 40, 60, 180); rectMode(CORNER); rect(bx, by, 140, 20, 4);
    if (p.shotCooldown > 0) {
      float pct = 1.0 - p.shotCooldown / p.shotCooldownMax;
      fill(255, 200, 60); rect(bx, by, 140 * pct, 20, 4);
      fill(30, 30, 30); textSize(10); textAlign(LEFT, CENTER);
      text("TIRO CD " + nf(p.shotCooldown/60.0, 1, 1) + "s", bx + 5, by + 10);
    } else {
      fill(100, 255, 180); textSize(10); textAlign(LEFT, CENTER);
      text("TIRO PRONTO", bx + 5, by + 10);
    }
    by += 26;

    // Ultimate (Act 4 apenas)
    if (p.tusk.act == 4) {
      fill(40, 30, 20, 180); rectMode(CORNER); rect(bx, by, 140, 20, 4);
      if (p.tusk.isUltimateActive()) {
        float pct = p.tusk.ultimateTimer / p.tusk.ultimateDur;
        fill(220, 160, 0); rect(bx, by, 140 * pct, 20, 4);
        fill(255, 220, 100); textSize(10); textAlign(LEFT, CENTER);
        text("VONTADE GYRO!", bx + 5, by + 10);
      } else if (p.tusk.ultimateCooldown > 0) {
        float pct = 1.0 - p.tusk.ultimateCooldown / p.tusk.ULT_COOLDOWN;
        fill(80, 60, 20); rect(bx, by, 140 * pct, 20, 4);
        fill(150, 130, 60); textSize(10); textAlign(LEFT, CENTER);
        text("[G] ULT CD " + nf(p.tusk.ultimateCooldown/60.0, 1, 0) + "s", bx + 5, by + 10);
      } else {
        fill(255, 200, 0); textSize(10); textAlign(LEFT, CENTER);
        text("[G] VONTADE DE GYRO!", bx + 5, by + 10);
      }
    }
    textAlign(LEFT, BASELINE); rectMode(CORNER); noStroke();
  }

  // UPGRADE SCREEN
  void drawUpgrade() {
    fill(0, 0, 0, 200); rect(0, 0, SCREEN_W, SCREEN_H);
    fill(255, 220, 50); textSize(30); textAlign(CENTER, CENTER);
    text("WAVE " + currentWave + " COMPLETA!", SCREEN_W/2.0, 80);
    fill(200, 200, 200); textSize(15);
    text("Escolha um upgrade:", SCREEN_W/2.0, 118);

    float startX = SCREEN_W/2.0 - (3 * CARD_W + 2 * 20) / 2.0;
    for (int i = 0; i < 3; i++) {
      cardX[i] = startX + i * (CARD_W + 20);
      cardY[i] = SCREEN_H/2.0 - CARD_H/2.0 - 10;
      drawUpgradeCard(i, cardX[i], cardY[i]);
    }

    if (chosenChar == CHAR_LUFFY  && luffyPlayer  != null) luffyPlayer.draw();
    if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) johnnyPlayer.draw();
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) hakariPlayer.draw();

    fill(140, 140, 140); textSize(12);
    text("Clique num card para escolher", SCREEN_W/2.0, SCREEN_H - 40);
    textAlign(LEFT, BASELINE);
  }

  void drawUpgradeCard(int idx, float cx, float cy) {
    int uType = upgradeOptions[idx];
    boolean hover = mouseX > cx && mouseX < cx + CARD_W &&
                    mouseY > cy && mouseY < cy + CARD_H;

    fill(hover ? color(60, 60, 80) : color(35, 35, 55));
    stroke(hover ? color(255,220,50) : color(80,80,120));
    strokeWeight(hover ? 2.5 : 1.5);
    rectMode(CORNER); rect(cx, cy, CARD_W, CARD_H, 12); noStroke();

    drawUpgradeIcon(uType, cx + CARD_W/2.0, cy + 90);

    fill(255, 220, 50); textSize(14); textAlign(CENTER, CENTER);
    text(upgradeName(uType), cx + CARD_W/2.0, cy + 165);
    fill(190, 190, 210); textSize(11);
    text(upgradeDesc(uType),  cx + CARD_W/2.0, cy + 190);
    text(upgradeDesc2(uType), cx + CARD_W/2.0, cy + 207);
    fill(100, 200, 130); textSize(10);
    text(upgradeStatus(uType), cx + CARD_W/2.0, cy + 240);
    textAlign(LEFT, BASELINE);
  }

  void drawUpgradeIcon(int uType, float ix, float iy) {
    rectMode(CENTER);
    if (chosenChar == CHAR_HAKARI) {
      switch(uType) {
        case 0:  // Probability - 3 rolos com 7
          fill(30, 20, 40); rect(ix, iy, 80, 50, 6);
          fill(255, 220, 0); textSize(26); textAlign(CENTER, CENTER);
          text("7 7 7", ix, iy + 8); break;
        case 1:  // Fever Rate - barra verde
          fill(40, 40, 40); rect(ix, iy, 70, 18, 4);
          fill(50, 255, 100); rect(ix - 10, iy, 50, 18, 4);
          fill(255); textSize(10); text("FERVOR", ix, iy + 1); break;
        case 2:  // Dano - punho com aura verde
          fill(25, 25, 30); rect(ix, iy, 40, 40, 5);
          noFill();
          for (int i = 2; i > 0; i--) { stroke(50,255,100, 60*i); strokeWeight(i*2); ellipse(ix,iy,55+i*6,55+i*6); }
          noStroke(); break;
      }
      rectMode(CORNER); noStroke(); textAlign(LEFT,BASELINE); return;
    }
    if (chosenChar == CHAR_LUFFY) {
      switch (uType) {
        case 0: fill(255, 204, 153); rect(ix, iy, 44, 44, 6);
                fill(240, 160, 90);  rect(ix, iy - 22, 48, 14, 4); break;
        case 1: fill(20, 20, 20);    rect(ix, iy, 44, 44, 6);
                noFill();
                for (int i = 3; i > 0; i--) { stroke(80,80,200, 60*i); strokeWeight(i*2); ellipse(ix,iy,60+i*8,60+i*8); }
                noStroke(); break;
        case 2: fill(255, 90, 100); rect(ix, iy, 44, 44, 6);
                fill(255, 160, 0, 180);
                triangle(ix-10, iy-22, ix, iy-44, ix+10, iy-22); break;
      }
    } else {
      // Johnny upgrades
      switch (uType) {
        case 0: // Tusk
          fill(220, 120, 160); rect(ix, iy, 40, 40, 6);
          fill(255, 210, 0); ellipse(ix, iy, 14, 14); break;
        case 1: // Stun
          fill(255, 230, 0); ellipse(ix - 12, iy, 12, 12);
          ellipse(ix + 12, iy, 12, 12);
          fill(80, 80, 80); rect(ix, iy + 10, 34, 24, 4); break;
        case 2: // Cooldown
          noFill(); stroke(255, 200, 60); strokeWeight(3);
          arc(ix, iy, 44, 44, -HALF_PI, PI);
          stroke(100, 100, 100); strokeWeight(2);
          arc(ix, iy, 44, 44, PI, -HALF_PI + TWO_PI);
          noStroke(); fill(255, 200, 60); ellipse(ix, iy, 8, 8); break;
      }
    }
    rectMode(CORNER); noStroke();
  }

  String upgradeName(int t) {
    if (chosenChar == CHAR_HAKARI) {
      switch(t) {
        case 0: return "PROBABILITY SHIFT";
        case 1: return "FEVER RATE";
        case 2: return hakariPlayer != null && hakariPlayer.damageLevel >= 5 ? "DANO MAX" : "DANO / COMBO";
      }
    }
    if (chosenChar == CHAR_LUFFY) {
      switch(t) {
        case 0: return "AUMENTO DE DANO";
        case 1: return luffyPlayer != null && luffyPlayer.hakiUnlocked ? "HAKI +" : "DESBLOQUEAR HAKI";
        case 2: return luffyPlayer != null && luffyPlayer.gear2Unlocked ? "GEAR 2 +" : "DESBLOQUEAR GEAR 2";
      }
    } else {
      switch(t) {
        case 0: return johnnyPlayer != null && johnnyPlayer.tusk.act >= 4 && johnnyPlayer.tuskLevel >= 9 ? "TUSK MAX" : "EVOLUIR TUSK";
        case 1: return "STUN APRIMORADO";
        case 2: return "TIRO MAIS RAPIDO";
      }
    }
    return "?";
  }

  String upgradeDesc(int t) {
    if (chosenChar == CHAR_HAKARI) {
      switch(t) {
        case 0: return "+10% chance de 777";
        case 1: return "+20% vel. de fervor";
        case 2: return hakariPlayer != null && hakariPlayer.damageLevel >= 5
                        ? "Dano maximo atingido" : "+1 dano  (Nv5=Portas)";
      }
    }
    if (chosenChar == CHAR_LUFFY) {
      switch(t) {
        case 0: return "+1 de dano base por soco";
        case 1: return luffyPlayer != null && luffyPlayer.hakiUnlocked ? "+1.5s de duracao" : "Ativa com [J]";
        case 2: return luffyPlayer != null && luffyPlayer.gear2Unlocked ? "+1.5s de duracao" : "Ativa com [G]";
      }
    } else {
      switch(t) {
        case 0: {
          if (johnnyPlayer == null) return "";
          int nextAct = 1 + ((johnnyPlayer.tuskLevel + 1) / 3);
          boolean maxed = johnnyPlayer.tusk.act >= 4 && johnnyPlayer.tuskLevel >= 9;
          return maxed ? "Tusk ja no maximo" : ("Nivel " + (johnnyPlayer.tuskLevel+1) + " | +dano" + (nextAct > johnnyPlayer.tusk.act ? " | ACT " + min(nextAct,4) + "!" : ""));
        }
        case 1: return "+0.2s de stun";
        case 2: return "-0.2s de cooldown";
      }
    }
    return "";
  }

  String upgradeDesc2(int t) {
    if (chosenChar == CHAR_HAKARI) {
      if (hakariPlayer == null) return "";
      switch(t) {
        case 0: return "Chance atual: " + (int)(hakariPlayer.jackpotChance*100) + "%";
        case 1: return "Rate atual: x" + nf(hakariPlayer.fervorRate, 1, 1);
        case 2: return "Nv: " + hakariPlayer.damageLevel + "/5";
      }
    }
    if (chosenChar == CHAR_LUFFY) {
      switch(t) {
        case 0: return "";
        case 1: return luffyPlayer != null && luffyPlayer.hakiUnlocked ? "" : "Bracos pretos  +50% dmg";
        case 2: return luffyPlayer != null && luffyPlayer.gear2Unlocked ? "" : "Socos rapidos, barrage";
      }
    } else {
      switch(t) {
        case 0: return johnnyPlayer != null ? "Act atual: " + johnnyPlayer.tusk.act : "";
        case 1: return johnnyPlayer != null ? "Stun: " + nf(johnnyPlayer.stunDuration/60.0, 1, 1) + "s" : "";
        case 2: return johnnyPlayer != null ? "CD: " + nf(johnnyPlayer.shotCooldownMax/60.0, 1, 1) + "s" : "";
      }
    }
    return "";
  }

  String upgradeStatus(int t) {
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) {
      switch(t) {
        case 0: return "Chance: " + (int)(hakariPlayer.jackpotChance*100) + "%";
        case 1: return "Rate: x" + nf(hakariPlayer.fervorRate,1,1);
        case 2: return "Dano: " + hakariPlayer.baseDamage + "  Nv: " + hakariPlayer.damageLevel;
      }
    }
    if (chosenChar == CHAR_LUFFY && luffyPlayer != null) {
      switch(t) {
        case 0: return "Dano: " + luffyPlayer.baseDamage;
        case 1: return luffyPlayer.hakiUnlocked ? "Dur: " + nf(luffyPlayer.hakiDuration/60.0,1,1)+"s" : "BLOQUEADO";
        case 2: return luffyPlayer.gear2Unlocked ? "Dur: " + nf(luffyPlayer.gear2Duration/60.0,1,1)+"s" : "BLOQUEADO";
      }
    } else if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) {
      switch(t) {
        case 0: {
          if (johnnyPlayer.tuskLevel >= 9) return "Act 4 | Nivel MAX";
          int lvl = johnnyPlayer.tuskLevel;
          int nextActAt = ((lvl / 3) + 1) * 3;
          return "Act " + johnnyPlayer.tusk.act + " | Nv " + lvl + " (" + (nextActAt - lvl) + " p/ Act " + min(johnnyPlayer.tusk.act+1,4) + ")";
        }
        case 1: return "Stun: " + nf(johnnyPlayer.stunDuration/60.0,1,1) + "s";
        case 2: return "CD: " + nf(johnnyPlayer.shotCooldownMax/60.0,1,1) + "s";
      }
    }
    return "";
  }

  void handleUpgradeClick(int mx, int my) {
    if (upgradeChosen) return;
    for (int i = 0; i < 3; i++) {
      if (mx > cardX[i] && mx < cardX[i] + CARD_W &&
          my > cardY[i] && my < cardY[i] + CARD_H) {
        applyUpgrade(upgradeOptions[i]);
        upgradeChosen = true;
        startNextWave();
        state = STATE_PLAYING;
        return;
      }
    }
  }

  void applyUpgrade(int uType) {
    if (chosenChar == CHAR_HAKARI && hakariPlayer != null) {
      switch(uType) {
        case 0: hakariPlayer.jackpotChance = min(0.9, hakariPlayer.jackpotChance + 0.10); break;
        case 1: hakariPlayer.fervorRate   += 0.20; break;
        case 2:
          if (hakariPlayer.damageLevel < 5) {
            hakariPlayer.damageLevel++;
            hakariPlayer.baseDamage++;
          }
          break;
      }
      return;
    }
    if (chosenChar == CHAR_LUFFY && luffyPlayer != null) {
      switch(uType) {
        case 0: luffyPlayer.baseDamage++; break;
        case 1: if (!luffyPlayer.hakiUnlocked) luffyPlayer.hakiUnlocked = true;
                else luffyPlayer.hakiDuration += luffyPlayer.HAKI_LEVEL_BONUS; break;
        case 2: if (!luffyPlayer.gear2Unlocked) luffyPlayer.gear2Unlocked = true;
                else luffyPlayer.gear2Duration += luffyPlayer.GEAR2_LEVEL_BONUS; break;
      }
    } else if (chosenChar == CHAR_JOHNNY && johnnyPlayer != null) {
      switch(uType) {
        case 0: johnnyPlayer.upgradeTusk();    break;
        case 1: johnnyPlayer.upgradeStun();    break;
        case 2: johnnyPlayer.upgradeCooldown(); break;
      }
    }
  }

  void sortUpgradeOptions() {
    ArrayList<Integer> pool = new ArrayList<Integer>();
    pool.add(0); pool.add(1); pool.add(2);
    for (int i = 0; i < 3; i++) {
      int pick = (int) random(pool.size());
      upgradeOptions[i] = pool.get(pick);
      pool.remove(pick);
    }
  }

  void drawTitle() {
    // A tela de título agora é a CharacterSelect
    // Este método não é chamado com o novo fluxo (appState == -1)
  }

  void drawGameOver() {
    fill(0, 0, 0, 190); rect(0, 0, SCREEN_W, SCREEN_H);
    fill(220, 30, 30); textSize(52); textAlign(CENTER, CENTER);
    text("GAME OVER", SCREEN_W/2.0, SCREEN_H/2.0 - 70);
    fill(255, 220, 50); textSize(22);
    text("Wave " + currentWave + "  |  Score: " + score, SCREEN_W/2.0, SCREEN_H/2.0 - 10);
    fill(200, 200, 200); textSize(15);
    text("Clique para voltar ao menu  |  [R] reiniciar", SCREEN_W/2.0, SCREEN_H/2.0 + 40);
    textAlign(LEFT, BASELINE);
  }

  void startNextWave() {
    currentWave++;
    enemiesToSpawn = BASE_ENEMIES + (currentWave - 1) * ENEMIES_SCALE;
    spawnTimer     = 0;
    bossSpawned    = false;
    bossPending    = currentWave >= 5;
    enemies.clear();
  }

  void spawnNormalEnemy() {
    float sx    = random(30, SCREEN_W - 30);
    int   hp    = BASE_HP + (currentWave - 1) * HP_SCALE;
    float spd   = baseSpeed();
    float track = map(currentWave, 1, 15, 0.003, 0.014);
    enemies.add(new Enemy(sx, hp, spd, track, false));
  }

  void spawnBoss() {
    int   hp  = (BASE_HP + (currentWave - 1) * HP_SCALE) * 12;
    float spd = baseSpeed() * 0.45;
    enemies.add(new Enemy(SCREEN_W / 2.0, hp, spd, 0.006, true));
  }
}
