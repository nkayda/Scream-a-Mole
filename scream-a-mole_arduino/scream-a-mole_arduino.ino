// LAST CODE VERSION BEFORE PROTOTYPE PRESENTATION



// PIN NUMBERS
int blueLed[] = { 3, 5, 6, 9 };       // PWM Pins, incdicate which sensor the player needs to touch
int buttons[] = { 2, 4, 8, 11 };  // Digital Pins, corresponds to each touch sensor

int redLed = 12;   // Digital pin, glows when player has missed or touched the wrong sensor
int greenLed = 7;  // Digital pin, glows when player touched the right sensor in time

int soundPin = 1;
int servoPin = 10;   // The servo pin, used for metronome to showcase pace
int sliderPin = A0;  // The slider pin, used for minigame
int numSensors = 4;  // The total number of touch sensors

int touchSensor = 13;


//SOUND VARIABLE
int volumeMatched = 0;

// SCORE VARIABLES
bool got = true;  // boolean if player hit the right sensor
int score = 0;     // int that saves player score (currently unused)
int misses = 0;    // int that saves player misses (currently unused)

// SLIDER VARIABLES
int sliderValue = 0;          // Raw slider value, 0-1023
int processingSliderValue;    // Mapped slider value, 0-100
int RequiredVolume = 0;       // Randomly set value that the player must match
int AccuracyRange = 10;       // Range around RequiredVolume that counts as matching
int MinVolume = 0;            // The minimum slider value
int MaxVolume = 100;          // The maximum slider value
boolean WithinRange = false;  // Boolean that states whether player is within required range

// SLIDER TIMING VARIABLES
int Interval = 10;      // Includes Countdown, amount of time between randomly set required value
int Countdown = -1;     // Amount of time player has to reach required value
int Timer = -1;         // Counts down from Countdown, used to display time player has left
long TimerSavedTime;    // Saves current time in seconds, used as reference point for the countdown timer
int Speed = 2;          // Changes how much time the player has to react, this is altered by slider minigame
bool sliderDebounce = false;  // Boolean used to prevent code from firing repeatedly
bool soundDebounce = false;  // Boolean used to prevent code from firing repeatedly

// TIME MANAGEMENT VARIABLES
int SecondsSinceStart;         // How many seconds have passed since game started
long savedTime;                // Time saved in millis(), used to change game state
bool waiting;                  // Boolean on whether green or red led or on
int touchWaitDuration = 2000;  // How many milliseconds the player has to touch the right sensor
int ledWaitDuration = 1000;    // How many milliseconds the red or green light glows

// RANDOMLY CHOSEN SENSOR VARIABLES
int choice = random(0, numSensors);      // pick sensor from 0-3 (index-based)
int lastActiveSensor = choice;
int activeSensor = buttons[choice];  // the currently chosen sensor
int light = blueLed[choice];             // the LED pin of the chosen sensor
int touchReading = HIGH;                 // variable that stores whether the pin is touched

// SERVO / METRONOME VARIABLES
#include <Servo.h>        // Import servo library
Servo myservo;            // create the servo object
bool metronome;           // A boolean that toggles the direction of the metronome
long savedMetronomeTime;  // Time saved in millis(), used to pace metronome

// GAME STATE
int MaxScore = 30;
int gameState = 1;

void setup() {
  Serial.begin(9600);

  pinMode(greenLed, OUTPUT);
  pinMode(redLed, OUTPUT);

  pinMode(sliderPin, INPUT);

  for (int i = 0; i < numSensors; i++) {
    pinMode(blueLed[i], OUTPUT);
    pinMode(buttons[i], INPUT);
  }

  myservo.attach(servoPin);
}



void loop() {

  //  Serial.println(gameState);

  if (gameState == 1 && digitalRead(touchSensor) == LOW) {
    gameState = 2;
  }

  if (gameState == 3 && digitalRead(touchSensor) == LOW) {

    score = 0;
    misses = 0;

    gameState = 1;

  }


  if (gameState == 2) {

    if (!Serial) { //check if Serial is available... if not,
      Serial.end();      // close serial port
      delay(100);        //wait 100 millis
      Serial.begin(9600); // reenable serial again
    }


    // SOUND SENSOR CODE, RUNS EVERY LOOP
    if (analogRead(soundPin) > 120) {
      volumeMatched = 1;
    }
    if (Timer == 4 && SecondsSinceStart > 5) {
      volumeMatched = 0;
    }
    // SOUND SENSOR CODE END


    // -- METRONOME CODE, RUNS ONCE AT REGULAR INTERVALS THAT VARY WITH SPEED --
    if (millis() > savedMetronomeTime + touchWaitDuration / 2) {  // this should toggle quickly, at a rate of 2 ticks per button switch

      if (metronome) {
        metronome = false;

        myservo.write(60);

      } else {
        metronome = true;
        myservo.write(120);
      }

      savedMetronomeTime = millis();
    }
    // -- METRONOME CODE ENDS --



    // -- SLIDER CODE, RUNS EVERY LOOP --
    SecondsSinceStart = millis() / 1000;

    // Every interval, set required slider position randomly
    if (SecondsSinceStart % Interval == Interval / 2 && !sliderDebounce) {

      //Serial.println("Set random required slider value");

      TimerSavedTime = SecondsSinceStart;
      Countdown = 5;
      RequiredVolume = (int)random(MinVolume, MaxVolume);
      sliderDebounce = true;
    }

    Timer = Countdown - (SecondsSinceStart - TimerSavedTime);

    sliderValue = analogRead(sliderPin);  // 0-1023
    processingSliderValue = map(sliderValue, 0, 1023, 0, 100);

    // Check if slider is within range
    if (processingSliderValue > RequiredVolume - AccuracyRange && processingSliderValue < RequiredVolume + AccuracyRange) {
      WithinRange = true;
    } else {
      WithinRange = false;
    }

    if (Timer == 0 && sliderDebounce) {
      sliderDebounce = false;
      soundDebounce = true;

      // Depending on if slider is in range, speed up or slow down game pace
      if (WithinRange) {
        if (Speed > 0) {
          Speed--;
        }
      } else {
        if (Speed < 5) {
          Speed++;
        }
      }
      touchWaitDuration = 1000 - Speed * 100;
    }
    // -- SLIDER CODE ENDS --



    // -- SOUND CODE, RUNS ONCE EVERY 10 SECONDS --
    if (Timer == 5 && soundDebounce) {
      soundDebounce = false;
      // Depending on if slider is in range, speed up or slow down game pace
      if (volumeMatched == 0) {
        if (Speed > 0) {
          Speed--;
        }
      } else {
        if (Speed < 5) {
          Speed++;
        }
      }
    }
    // -- SOUND CODE END --


    // -- SEND DATA PACKAGES TO PROCESSING, RUN EVERY LOOP --
    // Note: this means code will run quickly, making it effective but drowning the Serial Moniter
    Serial.print("a");  //character 'a' will delimit the reading from the light sensor
    Serial.print(sliderValue);
    Serial.print("a");

    Serial.print("b");  //character 'b' will delimit the required slider value
    Serial.print(RequiredVolume);
    Serial.print("b");

    Serial.print("c");  //character 'c' will delimit Aruino's millis() value
    Serial.print(millis());
    Serial.print("c");

    Serial.print("d"); //character 'd' will delimit the player's score
    Serial.print(score);
    Serial.print("d");

    Serial.print("e"); //character 'e' will delimit the player's misses
    Serial.print(misses);
    Serial.print("e");

    Serial.print("f"); //character 'f' will delimit the game's current state
    Serial.print(gameState);
    Serial.print("f");

    Serial.print("g"); //character 'g' will delimit the last active sensor, used for setting the note sound to be played
    Serial.print(lastActiveSensor);
    Serial.print("g");

    Serial.print("h"); //character 'h' will delimit whether the player reached the volume required for the volume sensor
    Serial.print(volumeMatched);
    Serial.print("h");

    Serial.print("&"); //denotes end of readings from both sensors

    Serial.println();
    //   -- DATA PACKAGE CODE ENDS --



    // -- CHECK FOR PLAYER INPUT, RUNS UNTIL SENSOR TOUCHED OR TIME RUNS OUT --
    if (millis() < savedTime + touchWaitDuration && !waiting) {

      touchReading = digitalRead(activeSensor);  // Get whether chosen sensor was touched

      for (int i = 0; i < numSensors; i++) {

        int touchReading = digitalRead(buttons[i]);

        if (touchReading == HIGH) {  // sensor is pressed

          if (buttons[i] == activeSensor) {
            //Serial.print("touch good: ");
            //Serial.print(buttons[i]);
            //Serial.println();

            touchReading = HIGH;
            got = true;
          }

          else {
            //Serial.print("touch bad: ");
            //Serial.print(buttons[i]);
            //Serial.println();

            got = false;
          }

          savedTime = savedTime - touchWaitDuration;  // Sets savedTime to value smaller than millis to mimic time running out
          break;
        }
      }

      if (digitalRead(activeSensor) == LOW) {  // checks not touched
        //Serial.println("nope");
      }
    }
    // -- CHECKING FOR PLAYER INPUT ENDS --



    // -- A SENSOR WAS TOUCHED OR TIME RAN OUT, RUNS ONCE AFTER WAIT TIME --
    if (millis() > savedTime + touchWaitDuration && !waiting) {

      //        Serial.println("WAITING");

      waiting = true;

      // If player got sensor in time, glow green. Otherwise glow red.
      if (got) {
        score++;
        digitalWrite(light, LOW);
        digitalWrite(greenLed, HIGH);
      }
      else {
        misses++;
        digitalWrite(light, LOW);
        digitalWrite(redLed, HIGH);
      }
      lastActiveSensor = choice;
    }
    // -- SENSOR TOUCHED / TIME OUT CODE ENDS --


    // -- RESETS CHOSEN LIGHT/SENSOR, RUNS ONCE AFTER WAIT TIME --
    if (millis() > savedTime + touchWaitDuration + ledWaitDuration && waiting) {

      //        Serial.println("RESET");

      waiting = false;

      savedTime = millis();

      digitalWrite(greenLed, LOW);
      digitalWrite(redLed, LOW);
      digitalWrite(light, LOW);

      got = false;

      // random LED lights up
      choice = random(0, numSensors);  // pick sensor from 0-3 (index-based)
      activeSensor = buttons[choice];
      light = blueLed[choice];
      digitalWrite(light, HIGH);

      touchReading = HIGH;
    }
    // -- RESET CODE ENDS --
  }

  // Set game state
  if (score + misses >= MaxScore) {
    gameState = 3;
  }

  if (gameState == 3) {
    // -- SEND DATA PACKAGES TO PROCESSING, RUN EVERY LOOP --
    // Note: this means code will run quickly, making it effective but drowning the Serial Moniter
    Serial.print("a");  //character 'a' will delimit the reading from the light sensor
    Serial.print(sliderValue);
    Serial.print("a");

    Serial.print("b");  //character 'b' will delimit the required slider value
    Serial.print(RequiredVolume);
    Serial.print("b");

    Serial.print("c");  //character 'c' will delimit Aruino's millis() value
    Serial.print(millis());
    Serial.print("c");

    Serial.print("d"); //character 'd' will delimit the player's score
    Serial.print(score);
    Serial.print("d");

    Serial.print("e"); //character 'e' will delimit the player's misses
    Serial.print(misses);
    Serial.print("e");

    Serial.print("f"); //character 'f' will delimit the game's current state
    Serial.print(gameState);
    Serial.print("f");

    Serial.print("g"); //character 'g' will delimit the last active sensor, used for setting the note sound to be played
    Serial.print(lastActiveSensor);
    Serial.print("g");

    Serial.print("h"); //character 'h' will delimit whether the player reached the volume required for the volume sensor
    Serial.print(volumeMatched);
    Serial.print("h");

    Serial.print("&"); //denotes end of readings from both sensors

    Serial.println();
    //   -- DATA PACKAGE CODE ENDS --
  }


}
