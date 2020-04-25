#define encoder0PinA  2
#define encoder0PinB  3
#define out2daqPinA 13
#define out2daqPinB 12

#include <Wire.h>

//Variables to change
//////////////////////////////////////////////////////////////////////
int threshold = 10;  // threshold wheel turn in degrees displacement 
int refresh = 100; // Reset frequency for angle displacement (in milliseconds)
//////////////////////////////////////////////////////////////////////

int TrialCt = 0; // Counts number of thresholds met

unsigned long SolOpenTime = 0;
unsigned long SolCloseTime = 0;
unsigned long thresholdcrossTime = 0;
unsigned long ms = 0;
unsigned int mcount = 0;
float pos;

volatile int encoder0Pos = 0;
float encoder0Deg = 0;

int EM = 0;
/*Eventmarkers
  0 = not in trial
  1 = threshold met - delay
  2 = sol open
  3 = iti start
*/

void setup() {
  //pinMode(solenoid, OUTPUT);
  //pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(115200); //set corresponding baud rate in Ardunio Serial Monitor
  attachInterrupt(0, doEncoder, CHANGE);  // encoder pin on interrupt 0 - pin 2
  Serial.println("start");                // a personal quirk
 
  pinMode(encoder0PinA, INPUT); 
  digitalWrite(encoder0PinA, HIGH);       // turn on pullup resistor
  pinMode(encoder0PinB, INPUT); 
  digitalWrite(encoder0PinB, HIGH);       // turn on pullup resistor
  pinMode(out2daqPinA, OUTPUT);
  pinMode(out2daqPinB, OUTPUT);
 
}

void doEncoder() {
 /* If pinA and pinB are both high or both low, it is spinning
  * forward. If they're different, it's going backward.
  */
 if (digitalRead(encoder0PinA) == digitalRead(encoder0PinB)) {
   encoder0Pos++;
 } else {
   encoder0Pos--;
 }

 encoder0Pos = encoder0Pos % 2048;
 encoder0Deg = encoder0Pos * (360.0/2048.0);

}

//strings to int 
void loop() {

  pos = encoder0Deg;

  ms = millis();
  switch (EM) {
    case 0: 
      if ( pos > threshold ) {
        EM = 1;
        thresholdcrossTime = millis();
        digitalWrite(out2daqPinA, HIGH); delay(2); digitalWrite(out2daqPinA, LOW);
      }
      else if ( pos < (-1 * threshold) ) {
        EM = 1;
        thresholdcrossTime = millis();
        digitalWrite(out2daqPinB, HIGH); delay(2); digitalWrite(out2daqPinB, LOW);
      }
      else {
        EM = 0;
        mcount++;
        while (mcount > refresh) {
          mcount = 0;
          encoder0Pos = 0;
          encoder0Deg = 0;
        }
      }
      break;

    case 1: // iti
        TrialCt++;
        EM = 0;
        encoder0Pos = 0;
        encoder0Deg = 0;
//      break;
  }

  Serial.println(String(ms) + ',' +  String(EM) + ',' +  String(TrialCt) + ',' + String(pos));

}

// [time EM TrialCt pos basePos]
