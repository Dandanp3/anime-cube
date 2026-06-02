/**
 * CharacterSelect.pde
 * Tela de seleção entre Luffy e Johnny Joestar.
 * Cada card mostra o cubo do personagem + companion se houver.
 */
class CharacterSelect {

  final float CARD_W = 260, CARD_H = 380;
  final float GAP    = 60;
  float cardLX, cardJX, cardY;

  float cardHX;  // Hakari card X

  CharacterSelect() {
    float totalW = CARD_W * 3 + GAP * 2;
    cardLX = SCREEN_W / 2.0 - totalW / 2.0;
    cardJX = cardLX + CARD_W + GAP;
    cardHX = cardJX + CARD_W + GAP;
    cardY  = SCREEN_H / 2.0 - CARD_H / 2.0 - 20;
  }

  void draw() {
    // Título
    fill(255, 220, 50);
    textSize(36);
    textAlign(CENTER, CENTER);
    text("ANIME CUBE", SCREEN_W / 2.0, 70);

    fill(180, 180, 180);
    textSize(14);
    text("Escolha seu personagem", SCREEN_W / 2.0, 110);

    boolean hoverL = isHover(cardLX);
    boolean hoverJ = isHover(cardJX);

    boolean hoverH = isHoverCard(cardHX);
    drawLuffyCard(cardLX, cardY, hoverL);
    drawJohnnyCard(cardJX, cardY, hoverJ);
    drawHakariCard(cardHX, cardY, hoverH);

    fill(120, 120, 120);
    textSize(11);
    text("[R] reiniciar  |  [M] mute", SCREEN_W / 2.0, SCREEN_H - 20);
    textAlign(LEFT, BASELINE);
  }

  void drawLuffyCard(float cx, float cy, boolean hover) {
    drawCardBase(cx, cy, hover, color(180, 30, 30));

    // Cubo do Luffy (vermelho)
    float mx = cx + CARD_W / 2.0;
    rectMode(CENTER);
    fill(220, 30, 30);
    rect(mx, cy + 110, 54, 54, 6);
    // Chapéu de palha
    fill(210, 170, 30);
    rect(mx, cy + 110 - 27 - 4, 62, 9, 2);
    // Olhos
    fill(255);
    ellipse(mx - 9, cy + 105, 8, 8);
    ellipse(mx + 9, cy + 105, 8, 8);
    fill(0);
    ellipse(mx - 9, cy + 107, 4, 4);
    ellipse(mx + 9, cy + 107, 4, 4);

    // Braço decorativo
    fill(255, 204, 153);
    rect(mx, cy + 80, 12, 30, 4);

    drawCardLabel(cx, cy, "LUFFY", "Gomu Gomu no Mi", "M1: Soco  J: Haki  G: Gear 2");
    rectMode(CORNER);
  }

  void drawJohnnyCard(float cx, float cy, boolean hover) {
    drawCardBase(cx, cy, hover, color(60, 80, 160));

    float mx = cx + CARD_W / 2.0;
    rectMode(CENTER);

    // Cubo do Johnny (azul-acinzentado com estrelas)
    fill(140, 160, 200);
    rect(mx, cy + 110, 54, 54, 6);
    // Detalhe: ferradura no peito
    noFill();
    stroke(210, 190, 50);
    strokeWeight(2.5);
    arc(mx, cy + 115, 22, 18, PI, TWO_PI);
    noStroke();
    // Olhos
    fill(255);
    ellipse(mx - 9, cy + 105, 8, 8);
    ellipse(mx + 9, cy + 105, 8, 8);
    fill(30, 30, 80);
    ellipse(mx - 9, cy + 107, 4, 4);
    ellipse(mx + 9, cy + 107, 4, 4);

    // Tusk Act 1 ao lado (cubinho rosa pequeno)
    drawTuskAct1(mx + 44, cy + 120);

    drawCardLabel(cx, cy, "JOHNNY", "Spin / Tusk", "M1: Nail Shot  G: Tusk Ult");
    rectMode(CORNER);
    noStroke();
  }

  // Desenha o Tusk Act 1 como cubinho rosa com detalhes
  void drawTuskAct1(float tx, float ty) {
    rectMode(CENTER);
    // Corpo rosa
    fill(230, 130, 160);
    rect(tx, ty, 24, 24, 4);
    // Estrela amarela no centro
    fill(255, 220, 0);
    drawStar(tx, ty, 5, 8, 5);
    // Olhinhos azuis
    fill(60, 100, 220);
    ellipse(tx - 4, ty - 3, 4, 4);
    ellipse(tx + 4, ty - 3, 4, 4);
    rectMode(CORNER);
  }

  void drawCardBase(float cx, float cy, boolean hover, color accent) {
    // Sombra
    fill(0, 0, 0, 80);
    rectMode(CORNER);
    rect(cx + 4, cy + 4, CARD_W, CARD_H, 14);
    // Fundo
    fill(hover ? color(50, 50, 72) : color(28, 28, 45));
    stroke(hover ? accent : color(70, 70, 100));
    strokeWeight(hover ? 3 : 1.5);
    rect(cx, cy, CARD_W, CARD_H, 12);
    noStroke();
    // Faixa de cor no topo
    fill(red(accent), green(accent), blue(accent), 80);
    rect(cx, cy, CARD_W, 8, 12);
  }

  void drawCardLabel(float cx, float cy, String name, String sub, String controls) {
    float mx = cx + CARD_W / 2.0;
    fill(255, 220, 50);
    textSize(20);
    textAlign(CENTER, CENTER);
    text(name, mx, cy + 190);

    fill(200, 200, 220);
    textSize(13);
    text(sub, mx, cy + 215);

    fill(140, 140, 160);
    textSize(10);
    text(controls, mx, cy + 238);

    // Botão
    fill(isHoverBtn(cx) ? color(255, 220, 50) : color(60, 60, 90));
    rectMode(CORNER);
    rect(cx + 30, cy + CARD_H - 60, CARD_W - 60, 36, 8);
    fill(isHoverBtn(cx) ? color(20, 20, 20) : color(200, 200, 220));
    textSize(14);
    text("JOGAR", cx + CARD_W / 2.0, cy + CARD_H - 42);
  }

  boolean isHover(float cx) {
    return mouseX > cx && mouseX < cx + CARD_W &&
           mouseY > cardY && mouseY < cardY + CARD_H;
  }

  boolean isHoverCard(float cx) { return isHover(cx); }

  boolean isHoverBtn(float cx) {
    return mouseX > cx + 30 && mouseX < cx + CARD_W - 30 &&
           mouseY > cardY + CARD_H - 60 && mouseY < cardY + CARD_H - 24;
  }

  // Retorna CHAR_LUFFY, CHAR_JOHNNY, CHAR_HAKARI ou -1
  int getClickedChar(int mx, int my) {
    if (mx > cardLX && mx < cardLX + CARD_W && my > cardY && my < cardY + CARD_H) return CHAR_LUFFY;
    if (mx > cardJX && mx < cardJX + CARD_W && my > cardY && my < cardY + CARD_H) return CHAR_JOHNNY;
    if (mx > cardHX && mx < cardHX + CARD_W && my > cardY && my < cardY + CARD_H) return CHAR_HAKARI;
    return -1;
  }


  void drawHakariCard(float cx, float cy, boolean hover) {
    drawCardBase(cx, cy, hover, color(40, 200, 80));

    float mx = cx + CARD_W / 2.0;
    rectMode(CENTER);

    // Jaqueta preta
    fill(25, 25, 30);
    rect(mx, cy + 110, 54, 54, 6);
    // Capuz
    fill(40, 40, 50);
    triangle(mx - 27, cy + 83, mx + 27, cy + 83, mx, cy + 72);
    // Calça marrom
    fill(120, 80, 40);
    rect(mx, cy + 125, 54, 22, 2);
    // Cabelo loiro
    fill(230, 210, 120);
    rect(mx, cy + 83, 48, 9, 3);
    rect(mx + 8, cy + 76, 12, 8, 2);
    // Olhos
    fill(50, 40, 30);
    ellipse(mx - 9, cy + 107, 5, 5);
    ellipse(mx + 9, cy + 107, 5, 5);
    // Botão
    fill(150, 130, 100);
    ellipse(mx, cy + 116, 5, 5);
    // Aura verde decorativa
    noFill();
    for (int i = 2; i > 0; i--) {
      stroke(50, 255, 100, 50 * i);
      strokeWeight(i * 2);
      ellipse(mx, cy + 110, 64 + i * 8, 64 + i * 8);
    }
    noStroke();

    drawCardLabel(cx, cy, "HAKARI", "Idle Death Gamble", "M1: Combo  Fervor: 777");
    rectMode(CORNER);
  }

  // Desenha uma estrela simples com N pontas
  void drawStar(float x, float y, int npts, float r1, float r2) {
    float angle = -HALF_PI;
    float step  = TWO_PI / npts;
    beginShape();
    for (int i = 0; i < npts; i++) {
      vertex(x + cos(angle) * r1, y + sin(angle) * r1);
      angle += step / 2;
      vertex(x + cos(angle) * r2, y + sin(angle) * r2);
      angle += step / 2;
    }
    endShape(CLOSE);
  }
}
