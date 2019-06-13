class Note {
  SoundFile note;
  float a;
  int ts;
  float starta, enda;
  PVector start, end;
  boolean isVoice, playing;


  Note(PApplet p, int index) {
    // Load sounds
    note = new SoundFile(p, "voice.wav");
    note.rate(0.5 + (0.5*(float)(index + 1)/((float)NUM)));
    float pan = map(a, 0, TWO_PI, 1, -1);

    // Silence the notes
    note.amp(0.5);

    // Calculate start, end points of section
    a = TWO_PI*((float)index/(float)NUM);
    starta = a;
    enda = a + INTERVAL;
    start = new PVector(cos(starta) * R, sin(starta) * R);
    end = new PVector(cos(enda) * R, sin(enda) * R);
  }

  void display() {
    pushMatrix();
    translate(C.x, C.y);
    //rotate(PI/12);
    stroke(0);
    fill(playing ? 0 : 255);
    beginShape();
    vertex(0, 0);
    vertex(start.x, start.y);
    vertex(end.x, end.y);
    endShape();
    popMatrix();
  }
  
  void toggle() {
    playing = !playing;
    // Restart counter
    if (!playing) {
      ts = 0;
    }
    
    // Update CTS
    updateCTS(-10);
  }

  void toggle(boolean turnOn) {
    if (playing != turnOn) toggle();
  }
  
  void play() {
    note.play();
  }

  // Check to see if note is being turned on
  boolean contains(PVector p) {
    PVector C2p = PVector.sub(p, C);
    float ap = C2p.heading();
    ap = ap > 0 ? ap : (PI-abs(ap)) + PI;
    float pr = C2p.mag();

    return pr < R && ap> starta && ap < enda;
  }

  void run() {
    if (playing) ts++;
    display();
  }
}
