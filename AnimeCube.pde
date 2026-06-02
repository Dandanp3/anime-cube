/**
 * ANIME CUBE
 * Engine: Processing (Java Mode)
 *
 * ARQUIVOS:
 *   AnimeCube.pde       -> Setup, Draw, Input global, helpers globais
 *   CharacterSelect.pde -> Tela de seleção de personagem
 *   GameManager.pde     -> Waves, vidas, upgrade screen, HUD, boss
 *   Enemy.pde           -> Inimigo normal e Boss
 *   Particle.pde        -> Partículas de impacto, fogo, stun
 *
 *   -- LUFFY --
 *   LuffyPlayer.pde     -> Luffy: movimento, Haki, Gear 2
 *   ArmAttack.pde       -> Braço elástico, barrage
 *
 *   -- JOHNNY --
 *   JohnnyPlayer.pde    -> Johnny + Tusk: tiro, stun, ricochet, ultimate
 *   NailShot.pde        -> Projétil do Johnny (unha giratória)
 *   TuskCompanion.pde   -> Cubo do Tusk ao lado do Johnny + ultimate
 *
 * ESTRUTURA DE PASTAS:
 *   data/luffySounds/gomuSound.mp3
 *   data/luffySounds/hakiSound.mp3
 *   data/johnnySounds/JohnnyUltimate.mp3
 *   data/hakariSounds/ryokiTenkai.mp3
 *   data/hakariSounds/tucaDonka.mp3
 *   music.mp3
 */

import processing.sound.*;

// Constantes globais
final int   SCREEN_W       = 1200;
final int   SCREEN_H       = 800;
final float DEFENSE_LINE_Y = SCREEN_H - 70;
final int   BASE_LIVES     = 5;

// Estado global do app
// -1 = character select, outros gerenciados pelo GameManager
int appState = -1;

// Personagem escolhido
final int CHAR_LUFFY  = 0;
final int CHAR_JOHNNY = 1;
final int CHAR_HAKARI  = 2;
int chosenChar = CHAR_LUFFY;

// Instâncias principais
GameManager     gm;
CharacterSelect charSelect;
LuffyPlayer     luffyPlayer;
JohnnyPlayer    johnnyPlayer;
HakariPlayer    hakariPlayer;

// Referência genérica para o player ativo (interface simulada via duck typing)
// Usamos Object e fazemos cast quando necessário
Object activePlayer;

// Sons globais
SoundFile bgMusic;
SoundManager soundManager;

// Partículas
ArrayList<Particle> particles;

void setup() {
  size(1200, 800);
  frameRate(60);
  noStroke();
  textFont(createFont("Courier New Bold", 20));
  noCursor();

  particles    = new ArrayList<Particle>();
  soundManager  = new SoundManager(this);
  charSelect = new CharacterSelect();
  gm         = new GameManager();

  // Música de fundo
  try {
    bgMusic = new SoundFile(this, "music.mp3");
    bgMusic.loop();
    bgMusic.amp(0.5);
  } catch (Exception e) {
    println("[AUDIO] music.mp3 nao encontrado.");
    bgMusic = null;
  }
}

void draw() {
  background(15, 15, 25);
  drawGrid();

  if (appState == -1) {
    // Tela de seleção de personagem
    charSelect.draw();
  } else {
    drawDefenseLine();
    gm.update();
    gm.draw();
    updateParticles();

    if (gm.state == GameManager.STATE_PLAYING ||
        gm.state == GameManager.STATE_UPGRADE) {
      drawCursor();
    }
  }
}

void mousePressed() {
  if (mouseButton != LEFT) return;

  if (appState == -1) {
    int chosen = charSelect.getClickedChar(mouseX, mouseY);
    if (chosen >= 0) {
      chosenChar = chosen;
      initPlayer(chosen);
      appState = 0;
      gm.startGame();
    }
    return;
  }

  switch (gm.state) {
    case GameManager.STATE_PLAYING:
      if (chosenChar == CHAR_LUFFY)  luffyPlayer.triggerAttack();
      if (chosenChar == CHAR_JOHNNY) johnnyPlayer.triggerAttack();
      if (chosenChar == CHAR_HAKARI)  hakariPlayer.triggerAttack();
      break;
    case GameManager.STATE_UPGRADE:
      gm.handleUpgradeClick(mouseX, mouseY);
      break;
    case GameManager.STATE_GAMEOVER:
      appState = -1;
      gm.state = GameManager.STATE_TITLE;
      break;
  }
}

void mouseReleased() {
  if (mouseButton == LEFT && chosenChar == CHAR_LUFFY && luffyPlayer != null) {
    luffyPlayer.stopBarrage();
  }
  if (mouseButton == LEFT && chosenChar == CHAR_HAKARI && hakariPlayer != null) {
    // no barrage release needed for Hakari
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    appState = -1;
    gm.state = GameManager.STATE_TITLE;
    return;
  }
  if (key == 'm' || key == 'M') {
    toggleMusic();
    return;
  }

  if (gm.state != GameManager.STATE_PLAYING) return;

  if (chosenChar == CHAR_LUFFY) {
    if (key == 'j' || key == 'J') luffyPlayer.activateHaki();
    if (key == 'g' || key == 'G') luffyPlayer.activateGear2();
  }
  if (chosenChar == CHAR_JOHNNY) {
    if (key == 'g' || key == 'G') johnnyPlayer.activateUltimate();
  }
  // Hakari has no key activation (domain triggers via fervor bar)
}

// Inicializa o player do personagem escolhido
void initPlayer(int charId) {
  float cx = SCREEN_W / 2.0;
  float cy = SCREEN_H / 2.0;
  luffyPlayer  = null;
  johnnyPlayer = null;
  hakariPlayer = null;
  if (charId == CHAR_LUFFY) {
    luffyPlayer = new LuffyPlayer(cx, cy);
  } else if (charId == CHAR_JOHNNY) {
    johnnyPlayer = new JohnnyPlayer(cx, cy);
  } else if (charId == CHAR_HAKARI) {
    hakariPlayer = new HakariPlayer(cx, cy);
  }
}

void toggleMusic() {
  if (bgMusic == null) return;
  if (bgMusic.isPlaying()) bgMusic.stop();
  else                     bgMusic.loop();
}

// Fade out da música (usado pela ultimate do Johnny)
void fadeMusicOut(float targetAmp) {
  if (bgMusic == null) return;
  bgMusic.amp(targetAmp);
}

// Restaura volume da música
void fadeMusicIn() {
  if (bgMusic == null) return;
  bgMusic.amp(0.5);
  if (!bgMusic.isPlaying()) bgMusic.loop();
}

// Helpers de desenho globais
void drawGrid() {
  stroke(30, 30, 50);
  strokeWeight(1);
  for (int x = 0; x < SCREEN_W; x += 40) line(x, 0, x, SCREEN_H);
  for (int y = 0; y < SCREEN_H; y += 40) line(0, y, SCREEN_W, y);
  noStroke();
}

void drawDefenseLine() {
  for (int i = 4; i > 0; i--) {
    stroke(200, 0, 0, 40 * i);
    strokeWeight(i * 3);
    line(0, DEFENSE_LINE_Y, SCREEN_W, DEFENSE_LINE_Y);
  }
  stroke(255, 50, 50);
  strokeWeight(2);
  line(0, DEFENSE_LINE_Y, SCREEN_W, DEFENSE_LINE_Y);
  noStroke();

  for (int i = 0; i < gm.lives; i++) {
    fill(220, 30, 30);
    ellipse(20 + i * 26, DEFENSE_LINE_Y + 18, 16, 16);
  }
  for (int i = gm.lives; i < BASE_LIVES; i++) {
    noFill();
    stroke(100, 30, 30);
    strokeWeight(1.5);
    ellipse(20 + i * 26, DEFENSE_LINE_Y + 18, 16, 16);
    noStroke();
  }
}

void drawCursor() {
  stroke(255, 255, 255, 160);
  strokeWeight(1);
  int cs = 8;
  line(mouseX - cs, mouseY, mouseX + cs, mouseY);
  line(mouseX, mouseY - cs, mouseX, mouseY + cs);
  noFill();
  stroke(255, 255, 255, 80);
  ellipse(mouseX, mouseY, 18, 18);
  noStroke();
}

// Helpers de partículas
void spawnImpactParticles(float x, float y, color c) {
  for (int i = 0; i < 8; i++) particles.add(new Particle(x, y, c, false));
}

void spawnFireParticles(float x, float y) {
  for (int i = 0; i < 5; i++) particles.add(new Particle(x, y, color(255, 120, 20), true));
}

void spawnStunParticles(float x, float y) {
  // Estrelinhas amarelas de stun
  for (int i = 0; i < 5; i++) particles.add(new Particle(x, y, color(255, 230, 0), false));
}

void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.draw();
    if (p.isDead()) particles.remove(i);
  }
}
