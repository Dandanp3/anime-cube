/**
 * SoundManager.pde
 * Carrega e expõe todos os sons do jogo.
 * Inicializado no setup() do sketch principal.
 */
class SoundManager {

  SoundFile gomuSound;
  SoundFile hakiSound;
  SoundFile johnnyUltimate;
  SoundFile hakariRyoki;
  SoundFile hakariJackpot;

  SoundManager(PApplet app) {
    gomuSound       = load(app, "data/luffySounds/gomuSound.mp3");
    hakiSound       = load(app, "data/luffySounds/hakiSound.mp3");
    johnnyUltimate  = load(app, "data/johnnySounds/JohnnyUltimate.mp3");
    hakariRyoki     = load(app, "data/hakariSounds/ryokiTenkai.mp3");
    hakariJackpot   = load(app, "data/hakariSounds/tucaDonka.mp3");
  }

  SoundFile load(PApplet app, String path) {
    try {
      return new SoundFile(app, path);
    } catch (Exception e) {
      println("[AUDIO] Nao encontrado: " + path);
      return null;
    }
  }

  void play(SoundFile sf) {
    if (sf == null) return;
    try { sf.stop(); sf.play(); } catch (Exception e) {}
  }

  void loop(SoundFile sf) {
    if (sf == null) return;
    try { sf.loop(); } catch (Exception e) {}
  }

  void stop(SoundFile sf) {
    if (sf == null) return;
    try { sf.stop(); } catch (Exception e) {}
  }

  // Retorna a duração em segundos do áudio da ultimate (fallback: 30s)
  float ultimateDuration() {
    if (johnnyUltimate == null) return 30.0;
    try { return johnnyUltimate.duration(); } catch (Exception e) { return 30.0; }
  }
}
