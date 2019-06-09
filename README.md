# MusicInstrumentTuner - Beta
Matlab-based music instrument tuner and voice range calculator. Beta version.
I developed this code as the term project for a signal processing class (CE 5984) at Virginia Tech. 

This tuner code has been written in Matlab. You may need a Matlab interpreter (Matlab (R) or GNU-Octave) to run it, 
it relies on "audioRecorder" objects, which exist in both interpreters. 
I never tried executing in Octave though, I cannot guarantee that some GUI components may work properly.
Please have a look at the slideshow (fat ODP file) of the presentation I made when bringing the tuner to the class 
(or the other resource files I uploaded) for some background on what lies behind the tuner.

# How to use:
 run the "tunerFrontEnd.m" script from the interpreter's command window.
And follow the prompts on screen as you use the software.
IMPORTANT: This tuner makes use of your PC's sound card to listen to the instruments you want to tune 
(or the voice of the singer whose range you want to determine), thus:
  1) make sure your sound card is properly installed on your pc (that is, you have the right drivers and it's working)
  2) make also sure that your pc has a microphone and it's enabled and can perceive sounds. 
  If using a desktop PC without a built-in microphone (or a laptop or all-in-one with a disabled mic),
  plug an external mic in before opening the interpreter and running the code. 
  Otherwise, the interpreter would crash on you.
  3) There's the chance that the first time you run the tuner on your interpreter it may crash as soon as starts receiving sounds. 
  THat seems to happen because the sound card takes a while to initialize the recorder and send sounds to the Interpreter.
  Ignore that error and re-run (it should work fine by then)
  4) Have fun!

# List of pending improvements
1) The tuner detects the musical note of the sounds you're producing by doing a Fast Fourier transform of the sound stream from your microphone and analyzing the frequency peaks. Instruments with a low-intensity first harmonic and richer 2nd-3rd harmonics may trick the tuner into incorrect notes. 
I need to improve the peak detection technique...
Maybe analyze the log of the FFT components amplitude vs. frequency (may bump up the small first freqs.) 
or do a cleverer multi-peak analysis and guess the fundamental freq from all the peaks the software is sensing...   

# Licensing
I hereby license this tuner to you (including the source code) under the terms of the CC-BY-SA 4.0 International license. 
When using the tuner, you accept the following terms:
  1) Respect the terms of the CC-BY-SA-4.0 int'l license when using the tuner or deriving original work from it.
  The license terms can be read here: http:// creativecommons.org/licenses/by-sa/4.0/
  2) Acknowledge that the tuner is given AS-IS, and without warranty of fitting any particular purpose. 
  Release the author (Scavone, M) of any liability that may result as a consequence (either direct or indirect)
  of the use, lack of use, or misuse of the musical instrument tuner.
  As the end-user of the tuner, you are expected to apply your common sense and judgement on the results 
  given by it
  
