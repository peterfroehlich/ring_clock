// ### Ring Clock, based on WS2811 RGB LED strip ###
// Uses DS3231 RTC chip over I2C and capacitive touch input from metal surfaces from frame to set an short term (1-60 minutes) alarm
// PF - 12/2013

#include <DS3231.h>
#include <Wire.h>
#include <Adafruit_NeoPixel.h>
#include <CapSense.h>

#define buttonPin 2 
#define stripPin 6
// Parameter 1 = number of pixels in strip
// Parameter 2 = pin number (most are valid)
// Parameter 3 = pixel type flags, add together as needed:
//   NEO_RGB     Pixels are wired for RGB bitstream
//   NEO_GRB     Pixels are wired for GRB bitstream
//   NEO_KHZ400  400 KHz bitstream (e.g. FLORA pixels)
//   NEO_KHZ800  800 KHz bitstream (e.g. High Density LED strip)
Adafruit_NeoPixel strip = Adafruit_NeoPixel(60, stripPin, NEO_GRB + NEO_KHZ800);

// Configuration of colors
// -- colors defined as array of { main color, flanking color }
uint32_t color_hour[2] = { strip.Color(255, 0, 0), strip.Color(30, 0, 0) };
uint32_t color_minute[2] = { strip.Color(0, 255, 0), strip.Color(0, 30, 0) };
uint32_t color_second[2] = { strip.Color(0, 0, 255), strip.Color(0, 0, 30) };
uint32_t color_alarm=strip.Color(50, 50, 0);
uint32_t color_off=strip.Color(0, 0, 0);


 // initialisation of vars
int hour;
int minute;
int second;

DS3231 Clock;
bool h12 = true;
bool PM;

int setTimeInitialDelay=400;

// Outer ring to increment alarm
CapSense cs_4_8 = CapSense(4,8);        // 120k resistor between pins 4 & 8, pin 8 is sensor pin, add a wire and or foil

// Inner ring to decrement alarm
CapSense cs_4_12 = CapSense(4,12);      // 120k resistor between pins 4 & 12, pin 12 is sensor pin, add a wire and or foil
int capacitiveSensorThreshold = 160;
int AlarmTouchThreshold = 10;

int delayCounterSetAlarm = 0;
bool AlarmOn = false;
int AlarmMinutes = 0;
int AlarmSecond;
bool MinuteNotSubtractedFromAlarmFlag;


void setup() {
  // Start the I2C interface
  Wire.begin();
  
  // Initialize WS2811 strip 
  strip.begin();
  strip.show(); // Initialize all pixels to 'off'
  
  // Button to set time
  pinMode(buttonPin, INPUT);
  
  // Stuff for capazitive touch
  cs_4_8.set_CS_AutocaL_Millis(0xFFFFFFFF);     // turn off autocalibrate
  cs_4_12.set_CS_AutocaL_Millis(0xFFFFFFFF);
}

void loop() {
  // check if time set buttons are pressed
  if (digitalRead(buttonPin)) {
    setTime();   
  } else {
    // check if rings are touched and manage alarm
    checkForCapacitiveInput();
    
    // read time from clock  
    readTime();
      
    // check if short term alarm is running  
    if (AlarmOn) {
      manageAlarm();
    }
    
    // display time
    displayTime();
    delay(10);
  }
}


void manageAlarm() {
  if (AlarmSecond == second) {
    if (AlarmMinutes == 0) {
      startAlarm(); 
    } else if (MinuteNotSubtractedFromAlarmFlag) {
      --AlarmMinutes;
      MinuteNotSubtractedFromAlarmFlag = false;
    } 
  } else {
    MinuteNotSubtractedFromAlarmFlag = true;
  }
}


void startAlarm() {
  AlarmOn = false;
  colorStrip(color_off);
  while ((cs_4_8.capSense(30) < capacitiveSensorThreshold) && (cs_4_12.capSense(30) < capacitiveSensorThreshold)) {
    colorStrip(color_alarm);
    strip.show();
    delay(200);
    colorStrip(color_off);
    strip.show();
    delay(200);
  } 
  delay(400);
}


void checkForCapacitiveInput() {
  if ((cs_4_8.capSense(30) > capacitiveSensorThreshold) || (cs_4_12.capSense(30) > capacitiveSensorThreshold)) {

    if (delayCounterSetAlarm >= AlarmTouchThreshold) {
      while ((cs_4_8.capSense(30) > capacitiveSensorThreshold) || (cs_4_12.capSense(30) > capacitiveSensorThreshold)) {
        MinuteNotSubtractedFromAlarmFlag = false;
        AlarmOn = true;
        AlarmSecond = Clock.getSecond();
       
        if (cs_4_8.capSense(30) > capacitiveSensorThreshold) {
          ++AlarmMinutes; 
        } else if (cs_4_12.capSense(30) > capacitiveSensorThreshold) {
          if (AlarmMinutes <= 0) {
            AlarmMinutes = 60;
          } else {
            --AlarmMinutes;
          } 
        } 
        colorStrip(color_off);
        setAlarmPixel();
        strip.show();
        
        if ((AlarmMinutes <= 0) || (AlarmMinutes > 60)) {
          AlarmOn = false;
          AlarmMinutes = 0;
          colorStrip(color_off);
          setAlarmPixel();
          strip.show();
          delay(500);
        }
        delay(180);
      } 
    } else {
      ++delayCounterSetAlarm;
    }
    
  } else {
    if (delayCounterSetAlarm > 0) {
      --delayCounterSetAlarm;
    }
  }
}


void readTime() {
  hour=Clock.getHour(h12, PM);
  minute=Clock.getMinute();
  second=Clock.getSecond();
}


void displayTime() {  
  colorStrip(color_off);
  // Order of writing on the strip is important
  setSurroundingPixel(second, color_second);
  setSurroundingPixel(hour*5, color_hour);
  setSurroundingPixel(minute, color_minute); 
  setAlarmPixel();
  setPixel(minute, color_minute);  
  setPixel(hour*5, color_hour);
  setPixel(second, color_second);
  strip.show();
}


void setAlarmPixel() {
  uint16_t i;
  for(i=0; i<AlarmMinutes; i++) {
    strip.setPixelColor(i, color_alarm);
  } 
}


void setPixel(int pixel, uint32_t color[2]) {
  strip.setPixelColor(pixel, color[0]);
}


void setSurroundingPixel(int pixel, uint32_t color[2]) {
  if (pixel == 0) {
    strip.setPixelColor(59, color[1]);
  } else {
    strip.setPixelColor(pixel-1, color[1]);
  }

  if (pixel == 59) {
    strip.setPixelColor(0, color[1]);
  } else {
    strip.setPixelColor(pixel+1, color[1]);
  }
}


void setTime() {
  int setTimeDelay=setTimeInitialDelay;
  hour=Clock.getHour(h12, PM);
  minute=Clock.getMinute();
  
  while (digitalRead(buttonPin)) {
    minute=minute+1; 
    if (minute > 59) {
      minute=0;
      hour=hour+1;
      if (hour > 11) {
        hour=0;
      }
      Clock.setHour(hour);
    }
    Clock.setMinute(minute);
    
    displayTime();  
    int delayCounter=setTimeDelay;
    while ((digitalRead(buttonPin)) && (--delayCounter > 0)) {
      delay(1);
    }
    
    if (setTimeDelay > 20) {
     setTimeDelay=setTimeDelay-20; 
    }
  }
}


void colorStrip(uint32_t color) {
  uint16_t i;
  for(i=0; i<strip.numPixels(); i++) {
    strip.setPixelColor(i, color);
  }
}
  
  
