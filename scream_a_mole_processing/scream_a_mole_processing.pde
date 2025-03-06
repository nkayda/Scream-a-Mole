// HIGHEST SCORE
int HighScore = 20;   // Highest achieved score, manually input??????????

import processing.serial.*;
Serial myPort;
import ddf.minim.*;

byte[] inBuffer = new byte[255];

// Time variables     (NOTE: There should be no max time, as it varies with the volume thing)
long ArduinoMillis;
long SecondsSinceStart; // The number of seconds since the game started, could be used as a challenge??? beat the game sooner / at harder difficulty???????????????
String MinutesString;  // A string used to show the number of minutes since start
String SecondsString;  // A string used to show the number of seconds since start

int gameState = 1;

//Sounds
Minim minim;
AudioSample ActiveNote;
AudioSample BadSound;

//Images
PImage[] startScreen = new PImage[2];
PImage[] endScreen = new PImage[2];
PImage[] gamePlay = new PImage[3];
int aniFrame = 1;
int aniCurrFramerate;
PImage gamePlayImg;

//Gameplay Variables
int lastActiveSensor = 1; // Which sensor was last chosen, used for playing correct note sound
int volumeMatched = 0; // Whether the user "sang" at the required volume
int sliderValue = 0; // The raw position of the slider
int Interval = 10; // Includes Countdown, the amount of time between events
long SavedTime; // A saved millis() value, used for regulating countdowns
int Countdown = -1;
int SliderTimer = -1; // Timer for how long the player has to set the slider value
int VolumeTimer = -1; // Timer for how long the player has to reach the required volume
int Speed = 2; // Between 0 and 5, this value regulates the pace of the game and is controlled by slider and volume countdowns
boolean sliderDebounce = false; // Boolean to prevent code from firing multiple times
boolean soundDebounce = false; // Boolean to prevent code from firing multiple times

// Score
int HighMisses = 10;  // Number of misses on the highest score
int MaxScore = 30;    // Number of buttons that light up through the whole game
int Score = 0;        // Player's score which increases as the game progresses
int Misses = 0;       // Number of buttons the player misses

// Slider (Variable names are misleading, sorry)
int MaxVolume = 100;          // The max slider value
int MinVolume = 0;            // The min slider value
int Volume = 0;               // The mapped position of the slider between 0 and 100
int RequiredVolume;      // How loud the user should be. This should be set randomly, at specific intervals.
int AccuracyRange = 10;       // The range from the required volume that the user should stay within (Larger = harder, smaller = easier).
boolean WithinRange = false;  // A boolean that shows whether the player is within the range of the required volume.

// Colours
color red = color(200, 25, 25);
color green = color(25, 200, 25);
color yellow = color(255, 225, 50);

// Random initial values to prevent error
String[] source1 = {"a", "b", "c"};
String[] source2 = {"a", "b", "c"};
String[] source3 = {"a", "b", "c"};
String[] source4 = {"a", "b", "c"};
String[] source5 = {"a", "b", "c"};
String[] source6 = {"a", "b", "c"};
String[] source7 = {"a", "b", "c"};
String[] source8 = {"a", "b", "c"};


void setup() {
  fullScreen();
  //size(1366, 768);
  textSize(64);
  noStroke();
  frameRate(60);

  // Get port
  printArray(Serial.list());
  myPort = new Serial(this, Serial.list()[3], 9600);


  // Load images
  startScreen[0] = loadImage("StartScreen1.jpg");
  startScreen[0].resize(width, height);

  startScreen[1] = loadImage("StartScreen2.jpg");
  startScreen[1].resize(width, height);

  endScreen[0] = loadImage("end.png");
  endScreen[0].resize(width, height);

  gamePlay[0] = loadImage("default.jpg");
  gamePlay[0].resize(width, height);

  gamePlay[1] = loadImage("success.jpg");
  gamePlay[1].resize(width, height);

  gamePlay[2] = loadImage("fail.jpg");
  gamePlay[2].resize(width, height);

  endScreen[0] = loadImage("EndScreen1.jpg");
  endScreen[0].resize(width, height);

  endScreen[1] = loadImage("EndScreen2.jpg");
  endScreen[1].resize(width, height);

  gamePlayImg = gamePlay[0];

  minim = new Minim(this);
  ActiveNote = minim.loadSample("Note"+lastActiveSensor+".mp3");
  BadSound = minim.loadSample("BadSound.wav");

  gameState = 1;
}



void draw() {

  if (0 < myPort.available()) {

    //println("available port");

    println(" ");

    myPort.readBytesUntil('&', inBuffer);

    if (inBuffer != null) {

      String myString = new String(inBuffer);

      String[] p = splitTokens(myString, "&");
      if (p.length < 2) return;  //exit this function if packet is broken
      //println("p: ");
      //printArray(p);
      //println(p[0]);

      source1 = splitTokens(p[0], "a");

      //println("source1: "); // slider value
      //printArray(source1);
      //println(int(source1[1]));

      source2 = splitTokens(p[0], "b");
      //println("source2: ");
      //printArray(source2);
      //println(int(source2[1])); // random volume

      source3 = splitTokens(p[0], "c");
      //println("source3: ");
      //printArray(source3);
      //println(int(source3[1])); // random volume

      source4 = splitTokens(p[0], "d");
      //println("source4: ");
      //printArray(source4);

      source5 = splitTokens(p[0], "e");
      //println("source5: ");
      //printArray(source5);

      source6 = splitTokens(p[0], "f");
      //println("source6: ");
      //printArray(source6);

      source7 = splitTokens(p[0], "g");
      //println("source7: ");
      //printArray(source7);

      source8 = splitTokens(p[0], "h");
      //println("source8: ");
      //printArray(source8);

      // Get last active sensor for playing the right note
      lastActiveSensor = int(source7[1])+1;

      //PLAY HIT OR MISS SOUND
      if (Score != int(source4[1])) {
        //Player got, play right note
        ActiveNote = minim.loadSample("Note"+lastActiveSensor+".mp3");
        ActiveNote.trigger();
        aniCurrFramerate = 20;
        gamePlayImg = gamePlay[1];
      }

      if (Misses != int(source5[1])) {
        //Player missed, play bad note
        ActiveNote = minim.loadSample("Note"+lastActiveSensor+".mp3");
        BadSound.trigger();
        aniCurrFramerate = 20;
        gamePlayImg = gamePlay[2];
      }


      sliderValue = int(source1[1]);
      RequiredVolume = int(source2[1]);
      ArduinoMillis = int(source3[1]);
      Score = int(source4[1]);
      Misses = int(source5[1]);
      gameState = int(source6[1]);
      volumeMatched = int(source8[1]);

      sliderValue = int(map(sliderValue, 0, 1023, 0, 100));
      Volume = sliderValue;
    }
  }

  if (gameState == 1) {
    //println("1");
    animate(startScreen);
    
  } else if (gameState == 3) {
    //println("3");
    
    // ERROR CATCH
    if (Score+Misses < MaxScore) {
      gameState = 2;
    } else {
      animate(endScreen);
      
      //END TEXT
      fill(255);
      textAlign(CENTER);
      //text("   At least you tried...", width/2, (height/10)*3.75);
      
      if (Score < HighScore) {
        text("   At least you tried...", width/2, (height/10)*3.75);
        text("High Score: "+ HighScore  +"/"+ MaxScore, width/2, (height/10)*6.75);
      } else {
        text("Mozart? Is that you?", width/2, (height/10)*3.75);
        fill(red);
        text("NEW HIGH SCORE!", width/2, (height/10)*2.25);
        fill(255);
        text("Old High Score: "+ HighScore  +"/"+ MaxScore, width/2, (height/10)*6.75);
      }
      
      text("Score: "+ Score  +"/"+ MaxScore, width/2, (height/10)*5.25);
      textAlign(LEFT);
    }
    
  } else if (gameState == 2) {

    // println("2");

    if (aniCurrFramerate > 0) {
      aniCurrFramerate--;
    }
    if (aniCurrFramerate == 0) {
      gamePlayImg = gamePlay[0];
    }

    SecondsSinceStart = ArduinoMillis/1000;
    MinutesString = nf(int(SecondsSinceStart)/60, 2);
    SecondsString = nf(int(SecondsSinceStart % 60), 2);

    if (SecondsSinceStart%Interval == Interval/2 && !sliderDebounce) {
      countdownSet();
      sliderDebounce = true;
      soundDebounce = true;
    }

    //background(0);
    image(gamePlayImg, 0, 0);

    fill(255);
    // Note: 2 pixels are removed at the end of each background rect, as rounding leaves a slight gap

    //// HighScore
    //rect(width*1/2.25, (height/10)*1.5, width/2-2, height/10);
    //drawHighScore();
    //text("HI-SCORE:", width/10, (height/10)*2.25);

    // Score
    rect(width*1/2.25, (height/10)*1.5, width/2-2, height/10);
    drawScore();
    text("SCORE:", width/10, (height/10)*2.25);

    // Slider
    rect(width*1/2.25, (height/10)*3, width/2-2, height/10);
    drawSlider();
    text("AMPLIFIER:", width/10, (height/10)*3.75);
    sliderCountdown();

    // Volume
    rect(width*1/2.25, (height/10)*4.5, width/2-2, height/10);
    drawVolume();
    text("VOLUME:", width/10, (height/10)*5.25);
    volumeCountdown();

    // Time
    text("TIME:     "+MinutesString  +":"+ SecondsString, width*1/2.25, (height/10)*8.25);
    text("SPEED:", width*1/2.25, (height/10)*6.75);

    // Speed
    drawSpeed();

    if (SliderTimer == 0 && sliderDebounce && SecondsSinceStart > 5) {
      sliderDebounce = false;

      if (WithinRange) {
        if (Speed > 0) {
          Speed--;
        }
      } else {
        if (Speed < 5) {
          Speed++;
        }
      }
    }

    if (SliderTimer == 5 && soundDebounce && SecondsSinceStart > 5) {
      soundDebounce = false;
      // Depending on if slider is in range, speed up or slow down game pace
      if (volumeMatched == 1) {
        if (Speed > 0) {
          Speed--;
        }
      } else {
        if (Speed < 5) {
          Speed++;
        }
      }
    }

    //Set game state
    if (Score+Misses >= MaxScore-25) {
      gameState = 3;
    }
  }
}

void drawSpeed() {
  rect(width*1/2.125 + width*1/8, (height/10)*6, (width/2)/8, height/10);
  rect(width*1/2.125 + (width*1.5)/8 + (width*1)/100, (height/10)*6, (width/2)/8, height/10);
  rect(width*1/2.125 + (width*2)/8 + (width*2)/100, (height/10)*6, (width/2)/8, height/10);
  rect(width*1/2.125 + (width*2.5)/8 + (width*3)/100, (height/10)*6, (width/2)/8, height/10);
  rect(width*1/2.125 + (width*3)/8 + (width*4)/100, (height/10)*6, (width/2)/8, height/10);


  if (Speed == 1) {
    fill(green);
    rect(width*1/2.125 + width*1/8, (height/10)*6, (width/2)/8, height/10);
  } else if (Speed == 2) {
    fill(yellow);
    rect(width*1/2.125 + width*1/8, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*1.5)/8 + (width*1)/100, (height/10)*6, (width/2)/8, height/10);
  } else if (Speed == 3) {
    fill(red);
    rect(width*1/2.125 + width*1/8, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*1.5)/8 + (width*1)/100, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*2)/8 + (width*2)/100, (height/10)*6, (width/2)/8, height/10);
  } else if (Speed == 4) {
    fill(red);
    rect(width*1/2.125 + width*1/8, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*1.5)/8 + (width*1)/100, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*2)/8 + (width*2)/100, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*2.5)/8 + (width*3)/100, (height/10)*6, (width/2)/8, height/10);
  } else if (Speed == 5) {
    fill(red);
    rect(width*1/2.125 + width*1/8, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*1.5)/8 + (width*1)/100, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*2)/8 + (width*2)/100, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*2.5)/8 + (width*3)/100, (height/10)*6, (width/2)/8, height/10);
    rect(width*1/2.125 + (width*3)/8 + (width*4)/100, (height/10)*6, (width/2)/8, height/10);
  }

  fill(255);
}

void drawHighScore() {

  fill(50, 150, 200);
  rect(width*1/2.25, (height/10)*1.5, (width/2)*HighScore/MaxScore, height/10);

  fill(33, 100, 150);
  rect(width*1/2.25 + (width/2)*HighScore/MaxScore, (height/10)*1.5, (width/2)*HighMisses/MaxScore, height/10);

  fill(0);
  textAlign(CENTER);
  text(HighScore  +"/"+ MaxScore, width*8.25/12, (height/10)*2.25);
  textAlign(LEFT);

  fill(255);
}

void drawScore() {
  fill(green);
  rect(width*1/2.25, (height/10)*1.5, (width/2)*Score/MaxScore, height/10);

  fill(red);
  rect(width*1/2.25 + (width/2)*Score/MaxScore, (height/10)*1.5, (width/2)*Misses/MaxScore, height/10);

  fill(0);
  textAlign(CENTER);
  text(Score  +"/"+ MaxScore, width*8.25/12, (height/10)*2.25);
  textAlign(LEFT);

  fill(255);
}

void drawSlider() {

  // Required Volume Bar
  fill(yellow);
  rect(width*1/2.25 + ((width/2) * (RequiredVolume - AccuracyRange*1.125))/MaxVolume, (height/10)*3, (width/2)*AccuracyRange*2.25/MaxVolume, height/10);

  if (Volume > RequiredVolume - AccuracyRange && Volume < RequiredVolume + AccuracyRange) {
    WithinRange = true;
    fill(green);
  } else {
    WithinRange = false;
    fill(red);
  }

  // User Slider Bar
  rect(width*1/2.25 + ((width/2) * (Volume - AccuracyRange/4))/MaxVolume, (height/10)*3, (width/2)*(AccuracyRange/2)/MaxVolume, height/10);

  // Black Bars to Hide Clipping
  fill(0);
  rect( (width*1/2.25) - (width*1/17), (height/10)*3, (width/17), height/10);
  rect( (width*1/2.25) + (width/2), (height/10)*3, (width/8), height/10);

  fill(255);
}

void drawVolume() {

  if (5 >= VolumeTimer && VolumeTimer > 0 && SecondsSinceStart > 5) {
    textAlign(CENTER);
    if (volumeMatched == 1) {
      fill(200, 0, 200);
      rect(width*1/2.25, (height/10)*4.5, width/2-2, height/10);
      fill(255);
      text("You got it!", width*8.25/12, (height/10)*5.25);
    } else {
      fill(0);
      text("Sing Louder!", width*8.25/12, (height/10)*5.25);
    }
    textAlign(LEFT);
  }
  fill(255);
}

void countdownSet() {
  SavedTime = SecondsSinceStart;
  Countdown = 5;
  //RequiredVolume = (int) random(MinVolume, MaxVolume);
}

void sliderCountdown() {

  SliderTimer = Countdown - int(SecondsSinceStart - SavedTime);

  if (SliderTimer > 0) {
    fill(0);
    text(SliderTimer, width*10.5/12, (height/10)*3.75);
  } else if (SliderTimer == 0) {
    if (WithinRange) {
      fill(green);
      text("✓", width*10.5/12, (height/10)*3.75);
    } else {
      fill(red);
      text("X", width*10.5/12, (height/10)*3.75);
    }
  } else {
    fill(0);
    text("Wait", width*10/12, (height/10)*3.75);
  }

  fill(255);
}

void volumeCountdown() {

  VolumeTimer = Countdown - int(SecondsSinceStart - SavedTime-5);

  if (5 >= VolumeTimer && VolumeTimer > 0 && SecondsSinceStart > 5 ) {
    fill(0);
    text(VolumeTimer, width*10.5/12, (height/10)*5.25);
  } else if (SliderTimer == 5 && SecondsSinceStart > 5) {
    if (volumeMatched == 1) {
      fill(green);
      text("✓", width*10.5/12, (height/10)*5.25);
    } else {
      fill(red);
      text("X", width*10.5/12, (height/10)*5.25);
    }
  } else {
    fill(0);
    text("Wait", width*10/12, (height/10)*5.25);
  }

  fill(255);
}

void animate(PImage[] arr) {

  if (frameCount % 20 == 0) {
    aniFrame *= -1;
  }

  if (aniFrame > 0) {
    image(arr[0], 0, 0);
  }
  if (aniFrame < 0) {
    image(arr[1], 0, 0);
  }
}

void buttonSuccess() {

  if (aniCurrFramerate >= 0) {
    gamePlayImg = gamePlay[1];
    aniCurrFramerate--;
  } else {
    gamePlayImg = gamePlay[0];
  }
}

//void keyPressed() {
//  if (keyCode == 'D') {
//    if (Volume < MaxVolume) {
//      Volume++;
//    }
//  }
//    if (keyCode == 'A') {
//      if (Volume > 0) {
//        Volume--;
//      }
//  }
//}
