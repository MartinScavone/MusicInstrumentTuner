function amILeaving = tunerFrontEnd()
%function amILeaving = tunerFrontEnd()
% Musical instrument tuner front-end
%
% This script will launch the tuner and after asking for needed inputs it will call the "LiveRecording" app
% Needed inputs:
% 1) instrument to tune. Options are: Guitar (G), base-guitar 4 strings (BG4), base-guitar 5 strings (BG5), violin (V), piano (P)
% and voice (VO)
% 2) microphone to use: enhance the hardware check performed in LiveRecording and ask the user accordingly.
% 
% V0.1 Thanksgiving eve - 2018-11-21
%CHANGELOG: FIRST FULL-SHAPE BETA VERSION!
% V0.0 AllSaints Ahead. 2018-10-27
%
%Developed by Les Martiworks
%
clear variables
close all
%clc
disp('Musical Instrument Tuner. Welcome.')
%
%tunerConfig
%%global fs nbits   The " global" feature wasn't working properly when
%%passing between functions. I will pass them on old-school way (as
%%input args.)

fs = 16000;     %sampling frequency [Hz]
nbits = 16;     %digital res. [bits]

%% - Inputs: Ask the user what instrument will be tuned
[whatInstrument,whatFreqResolution] = tunerInstrumentInput;  %%I MOVED IT TO DOWN BELOW AS AN AUX. FUNCTION TO THE FRONT END!

%Inputs: Detect if a microphone is available. If more than one exists, ask the user which one to use.
%Use an audiodevinfo obj.

audioDevices = audiodevinfo;
%the info on input devices is in the struct. audioDevices.input
%first check: audioDevices.input must not be empty (if so, there're no microphones available)
if isempty( audioDevices.input)
	%self-note: this check is the same as doing "if audiodevinfo(1) == 0" [audiodevinfo(1) asks Matlab to report input devices]
	disp('Music Instr. Tuner: No audio input device detected. Connect device, restart Matlab, and relaunch')
	return
else
	%there are microphones plugged in and ready to use. If there's only one, report the 	
	numberMics = length(audioDevices.input);
	if numberMics ==1
		fprintf('Music Instr. Tuner: Using default audio input device \n');
		fprintf(audioDevices.input(1).Name);
		targetDevice = audioDevices.input(1).ID;
	else
		%there is more than 1 microphone. List them and ask the user which one to use for the recording!
		fprintf('Music Instr. Tuner: More than one input device detected \n');
 		for j = 1:numberMics
			fprintf('Device no: %g is %s \n',j,audioDevices.input(j).Name);  %this line should put a string
		end
    fprintf('or 0: system default audio capture device \n')
		auxTgD = input('Music instr. Tuner: Give the number of the microphone to use....'); 
		targetDevice = audioDevices.input(auxTgD).ID;
	end
end



%% - Now get teh frequency tables
%load frequencyTable.mat;    --- USE OF THE FREQ. TABLE PASSES TO THE TUNER'S CORE!
%This file contains
%   FREQUENCIES - structure with fields ID,name,freqs,notes for each instrument
%   VOICES      - structure with fields ID, name, freqLow,freqHgh,noteLow,noteHgh,voiceNm for each voice type

%% - Add a while loop not to close the tuner. So that after each full execution
%(an instrument tuning round) the tuner won't close. Eventually, add the
%input dialog case you wanted to switch instrument/voice.

amILeaving = 0;
while ~amILeaving
    %just in case, convert a non-capitalized instrument name to a capitalized
    %one (for voices, downgrade an input in capitals [such as F or M] )
    %%--Moved inside the loop so that it can actually change instrument every
    %%--time the test repeates
    whatInstrumentNumeric = tunerCapitalizeWhatInstrument(whatInstrument);
        
    %inputs gathered. Launching Vollmer's "LiveRecording" app.  %%%NOTE THE CONTAINS FUNCTION IS MATLAB ONLY!!!
    if ~isempty(strfind(['m','f', 'M','F'],whatInstrument))   %%%ignore what matlab says on using "contains", that doesn't work in octave
        disp('Music Instr. Tuner: Launching LiveRecording for voice analysis')
        tunerLiveRecordingVoice(whatInstrumentNumeric,targetDevice,fs,nbits,whatFreqResolution);
    elseif ~isempty(strfind(['p', 'g', 'v', 'b', 'j','P','G','V','B','J'],whatInstrument))
        disp('Music Instr. Tuner: Launching LiveRecording for instrument tuning');
        tunerLiveRecordingInstruments(whatInstrumentNumeric,targetDevice,fs,nbits,whatFreqResolution);
    else
        disp('Music Instr. Tuner: Instrument not recognized')
        amILeaving = 1;
        return
    end    
    %now ask the user if they want to tune something else or close the
    %tuner....
    amILeaving = input(sprintf('Tuning complete. \n \t Do you want to tune another instrument? [say 0] \n \t or do you want to leave? [say 1]...'));
    if ~amILeaving  %the user decides to tune another instrument. Ask the user what instrument to tune.
        [whatInstrument,whatFreqResolution] = tunerInstrumentInput;
        %the next while loop will call the appropriate tuner with the newly
        %chosen Instrument
    else
        %do nothing, the user is leaving, the while loop closes and code
        %will stop.
    end
end
%this last line will launch when LiveRecording closes
disp('Execution ended. Goodbye!')

end   %ENDFUNCTION

%% -----------------
function [whatInstrument,whatFreqResolution] = tunerInstrumentInput()
%auxiliary function to the frontEnd. Asks the user what instrument to tune.
%I moved it from the front-end itself so that I can call it from different
%places.
whatInstrument = input(sprintf('Specify which instrument are you going to tune (between inv. commas)....\n  \t "G" for guitar \n \t "b" for 4-string bass guitar \n \t "j" for 5-string bass guitar \n \t "V" for violin \n \t "P" for piano \n \t "f" Woman"s vocal range\n \t "m" Man"s vocal range \n \t Your choice: \t '));
%[whatFreqResolution] = input(sprintf('Specify the quality of the tuning process\n  \t "30" raw quality (30 cents)\n \t "10" good quality (10 cents) \n \t "5" ultra ear-like quality (5 cents)\n \t Your choice: \t '));
whatFreqResolution = input(sprintf('Specify the frequency resolution to use [cents] \n \t 30 (basic recognition) \n \t 10 (guitar tuna) \n \t 5 (human-ear-like recognition).....'));   
%Rollback: give the option to many freq. resolution at 5 cents 
%cause I mis-did the calculation, for low-freq @ 5-cents deltaFreq I may
%need about 10 seconds to tune.
end
