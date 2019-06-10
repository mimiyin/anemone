import processing.sound.*;
import processing.serial.*;

import oscP5.*;
import netP5.*;


float R;
PVector C;
float INTERVAL;
int NUM = 12;
int cn = NUM - 1;

Note[] notes = new Note[NUM];

// Seconds to wait between notes
int ts = 60 * 2;
int cts = 60 * 3;
final int CTS_MIN = int(60 * 0.5);
final int CTS_MAX = cts;
final int CTS_ROR = 5;

// Serial connection
Serial floor, fan;  
boolean sfloor, sfan;
int TH = 2048;

// OSC connection
OscP5 oscP5;

// Rummble
SoundFile rumble;

// Clicking
SoundFile click;
boolean isClick = true;

// Keep track of when last click happened
int lastClickFrame;

// Cues for turning fan on and off
int [] cues = { 0, 10, 15, 18 };
int fc, c, cue;
boolean fanOn;

void setup() {
  size(800, 800);
  // Set-up serial for floor
  try {
    String portName = Serial.list()[5];
    floor = new Serial(this, portName, 9600);
    sfloor = true;
  }
  catch(Exception e) {
    println("No serial connection for floor.");
  }

  // Set up serial for fan
  try {
    String portName = Serial.list()[4];
    fan = new Serial(this, portName, 9600);
    sfan = true;
  }
  catch(Exception e) {
    println("No serial connection for fan.");
  }

  /* create a new instance of oscP5. 
   * 12000 is the port number you are listening for incoming osc messages.
   */
  oscP5 = new OscP5(this, 8080);

  // Set-up keyboard
  R = width/2;
  C = new PVector(width/2, height/2); 
  INTERVAL = TWO_PI/NUM;

  // Create the notes
  for (int n = 0; n < NUM; n++) {
    notes[n] = new Note(this, n);
  }

  // Load click
  click = new SoundFile(this, "click.mp3");

  // Load rumble
  rumble = new SoundFile(this, "rumble.wav");
  rumble.amp(0);
}

void draw() {

  background(255);
  // Increment show framecount
  fc++;

  // Count up note
  // Display note
  for (Note note : notes) {
    note.run();
  }

  // If serial for fan
  if (sfan) {
    if (fc > cue * 1000 * 60) {
      // Toggle fan
      fanOn = !fanOn;
      fan.write(fanOn? 1 : 0);
      c++;
      // Reset cues
      if (c > cues.length) {
        fc = 0;
        c = 0;
      }
      // Next cue
      cue = cues[c];
    }
  }

  //println("Cts: " + cts);
  if (isClick) {
    if ((frameCount - lastClickFrame) > cts) {
      click.play();
      updateCTS(CTS_ROR);
      lastClickFrame = frameCount;
    }
    return;
  }

  // Get data from floor through serial
  getFloorThroughSerial();

  // Update note to play every ts seconds
  int startcn = cn;
  if (frameCount % ts == 0) {
    // Update CTS
    updateCTS(CTS_ROR);

    boolean looking = true;
    while (looking) {
      //println("LOOKING: " + frameCount);
      if (notes[cn].playing) {
        println("PLAYING: " + cn);
        notes[cn].play();        
        looking = false;
      }
      cn--; 
      // Wrap around
      if (cn < 0) cn = NUM-1;

      // If we've gone around once
      // and nothing is on
      if (abs(startcn - cn) < 1) {
        looking = false;
      }
    }
  }
}

void mousePressed() {
  PVector mouse = new PVector(mouseX, mouseY);
  for (Note note : notes) {
    if (note.contains(mouse)) note.toggle();
  }
}

// Get data from floor through OSC
void oscEvent(OscMessage m) {
  /* check if theOscMessage has the address pattern we are looking for. */
  if (m.checkAddrPattern("/floor")) {
    try {
      String values = m.get(c).stringValue();
      setNotes(values);
    }
    catch(Exception e) {
      println("No value at: " + c);
    }
  } 
  //println("### received an osc message. with address pattern "+m.addrPattern());
}

// Get data from floor through serial
void getFloorThroughSerial() {
  if (sfloor && floor.available() > 0) {  // If data is available,
    String values = floor.readStringUntil(10);
    setNotes(values);
  }
}

// Toggle notes based on data
void setNotes(String _vals) {
  String [] vals = _vals.split(",");
  for (int v = 0; v < vals.length; v++) {
    try {
      int val = Integer.parseInt(trim(vals[v]));
      notes[v].toggle(val > TH);
    }
    catch(Exception e) {
      println("No value at: " + v);
    }
  }
}

// Update timespan between clicks
void updateCTS(int change) {
  cts += change;
  cts = constrain(cts, CTS_MIN, CTS_MAX);
  println("NEW CTS: " + cts);

  // Update rumble
  float rumbleVol = map(cts, CTS_MIN, CTS_MAX, 0, 1);
  println("NEW RUMBLE VOL: " + rumbleVol);
  rumble.amp(rumbleVol);
}

// Toggle click
void keyPressed() {
  isClick = !isClick;
  if (isClick) rumble.stop();
  else rumble.loop();
}