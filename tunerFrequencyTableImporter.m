%% Musical instrument tuner - - additional script to import the tables of frequencies to Matlab
%
%Data will be stored as structures [FREQUENCIES and VOICES] with the following fields
%FREQUENCIES.ID         - coded id for each instrument [g,v,gb5, gb4,P]
%FREQUENCIES.name       - Name of matching instrument
%FREQUENCIES.freqs      - Table of frequencies of all the notes to be tuned [Hz]
%FREQUENCIES.notes      - Names of the notes used in tuning
%
%VOICES.ID                - coded ID for male and female voice [vm, vf]
%FREQUENCIES.name         - Name of voice source (male/female)
%FREQUENCIES.freqLow      - Table of minimum frequency for the voice range [Hz]
%FREQUENCIES.freqHgh      - Table of maximum frequency for the voice range [Hz]
%FREQUENCIES.noteLow      - Names of the lower notes for the voice ranges
%FREQUENCIES.noteHgh      - Names of the upper notes for the voice ranges
%FREQUENCIES.voiceNM      - Names of the voice ranges
%
%
%Create structures
frequencies = struct('ID',[],'name',[],'freqs',[],'notes',[]);
voices      = struct('ID',[],'name',[],'freqLow',[],'freqHgh',[],'noteLow',[],'noteHgh',[],'voiceNm',[]);

%% Start importing
%%Instruments
%1 - guitar
frequencies(1).ID = 'G';
frequencies(1).name = 'guitar';
[nums,txt,~] = xlsread('frequencyTable','guitar','b5:c10');
frequencies(1).freqs = nums;
frequencies(1).notes = txt;

%2 - 4string bass guitar
frequencies(2).ID = 'BG4';
frequencies(2).name = '4-str. bass guitar';
[nums,txt,~] = xlsread('frequencyTable','bass guitar 4','b5:c8');
frequencies(2).freqs = nums;
frequencies(2).notes = txt;

%3 - 5string bass guitar
frequencies(3).ID = 'BG5';
frequencies(3).name = '5-str. bass guitar';
[nums,txt,~] = xlsread('frequencyTable','bass guitar 5','b5:c9');
frequencies(3).freqs = nums;
frequencies(3).notes = txt;

%4 - violin
frequencies(4).ID = 'V';
frequencies(4).name = 'violin';
[nums,txt,~] = xlsread('frequencyTable','violin','b5:c9');
frequencies(4).freqs = nums;
frequencies(4).notes = txt;

%5 - piano
frequencies(5).ID = 'P';
frequencies(5).name = 'Piano [108 keys]';
[nums,txt,~] = xlsread('frequencyTable','piano','b5:c112');
frequencies(5).freqs = nums;
frequencies(5).notes = txt;


%%VOICES
%1 - female voice
voices(1).ID = 'vf';
voices(1).name = 'female voice';
[nums,txt,~] = xlsread('frequencyTable','voiceFM','b5:f7');
voices(1).freqLow = nums(:,1);
voices(1).freqHgh = nums(:,2);
voices(1).noteLow = txt(:,1);
voices(1).noteHgh = txt(:,2);
voices(1).voiceNm = txt(:,3);

%1 - female voice
voices(2).ID = 'vm';
voices(2).name = 'male voice';
[nums,txt,~] = xlsread('frequencyTable','voiceM','b5:f8');
voices(2).freqLow = nums(:,1);
voices(2).freqHgh = nums(:,2);
voices(2).noteLow = txt(:,1);
voices(2).noteHgh = txt(:,2);
voices(2).voiceNm = txt(:,3);