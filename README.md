ring_clock
==========

wall clock w. alarm based on Arduino, WS2811 RGB LEDs and DS3231 RTC chip

Hardware
--------
- Arduino Pro Mini, 5V 16MHz
- DS3231 board (mini RTC pro)
- RGB LED strip w. 60x WS2811 enabled pixels 
- Button

PIN layout
----------
- Pin2 : Button to set clock
- Pin4 : 'ground' pin for capacitive input
- Pin6 : single data wire to strip
- Pin8 : 'touch' pin (1) - used for activating / incrementing alarm
- Pin12 : 'touch' pin (2) - used for activating / decrementing alarm (wraps around)
- Analog 4 : SDA to DS3231
- Analog 5 : SDC to DS3231

Build instructions
------------------

This was build with Arduino 0022. At the moment it will not compile with Arduino 1.x.x.
You need to install all used libraries (see links below) in your Arduino IDE [(need help?)](http://arduino.cc/en/Guide/Libraries)

A new version (04) of the CapSense Library was released. This code still uses the old 03 version. 
I've linked the download to the old version below. 

Links
-----
[Adafruit NeoPixel Arduino help](http://learn.adafruit.com/adafruit-neopixel-uberguide/arduino-library)  
[Arduino Playground - CapSense](http://playground.arduino.cc//Main/CapacitiveSensor?from=Main.CapSense)  
[CapSense03 Download link](http://playground.arduino.cc/uploads/Main/CapacitiveSense003.zip)  
[Dr. Ajars DS3231 library](http://hacks.ayars.org/2011/04/ds3231-real-time-clock.html)  



