function testComplete = tunerLiveRecordingVoice(whatInstrumentID,targetDevice,fs,nbits,freqQuality)
%function testComplete = tunerLiveRecordingVoice(whatInstrumentID,targetDevice,fs,nbits,freqQuality);
%
%Instrument tuner core function - to be called to perform a voice test.
%code with elements from the original LiveRecorder by Markus Wallmer
%I re-wrote the user interface and the processing functions to do the task
%I want.
%
%Inputs:
%   whatInstrumentID- as user said in the front-end, the NUMERICAL ID of
%   the instrument to be tuned
%   targetDevice    - the ID of the sound input device to be recording from
%   fs              - sampling frequency [Hz]
%   nbits           - number of bits to define sound
%   freqQuality     - frequency resolution (quality) of the tuning process: raw (33 cents) / fine (10 cents) / ear-quality (5 cents)
%Outputs: 
    %funcOutput     - it's going to be a 1, saying the function ended successfully.
    %When the function execution stops (because the user said so), the frontEnd will close itself
%
%Updated v0.3 "Coffee and Donuts" 2018-11-30
%   CHANGELOG: Added an "ideal high-pass filter" at 20Hz to kill all
%   infrasound background noise
%Updated v0.2 Tuesday       - 2018-11-20
%   CHANGELOG: Matlab function format, to be called from the front-end script
%Updated v0.1 EdvardGrieg   - 2018-11-18
%   CHANGELOG: Managed to make the GUI plot the time and freq. domain plots% 
%              First version to complete a test!!!
%V0.0 AllSaints - 2018-11-01/06 
%
%Developed by Les MartiWorks.

%close figures
if exist('figu1','var')
    close figures   %%added to close the figures before running. If I don't do this, they will start to overlap
end
global figu1 %%Global Variables I'm going to need


%% 1 - Get the frequency table for "whatInstrument"
%%1 - locate instrument ID and bring the table of frequencies from the frequencyTable
load frequencyTable.mat voices;        %this MAT file contains a structure with the tuning frequencies for the compatible instruments.
instrumentNumID = zeros(1,max(size(voices)));
%fill the instrumentNumID vector with a for loop (Matlab doesn't like to bring all values at once)
for i = 1:length(voices)
   instrumentNumID(i) = voices(i).numericalID; 
end
instrPos = find(instrumentNumID==whatInstrumentID);   %the front-end checks that a valid instrument is input before calling the Tuner. So this find must always yield a result.

%% 2 - Now, bring the low and high threshold notes [frequencies and names]
lowNoteFreqs = voices(instrPos).freqLow;
lowNoteNames = voices(instrPos).noteLow;
hghNoteFreqs = voices(instrPos).freqHgh;
hghNoteNames = voices(instrPos).noteHgh;
lesVoiceNmes = voices(instrPos).voiceNm;

%% 7 (or 3.5) - Target frequency resolution and sample durataion
%a) set the target deltaFreq. Use the freqQuality input (30 / 10 / 5 cents)
% the tuner's deltaFreq will be freqQuality/100 * frequency of the lowest note to tune.
%-- get it from tuningNotesFreqs
deltaFreq = freqQuality/100*(2^(1/12)-1)*min(lowNoteFreqs);
%%freqQuality is an input to this function, in CENTS
  
%b) get the sampling duration for my deltaFreq.
samplingDuration = 1/deltaFreq;
sampleTargetSize = ceil(fs/deltaFreq);
%  NOTE: FOR A 5-STR BASE GUITAR, samplingTargetSize at ultra resolution is about 10333 smples, 0.7 seconds!
fprintf('Voice Range Test:: Frequency resolution will be %g Hz. \n',deltaFreq);
fprintf('Voice Range Test:: Frequency analysis will start after %g seconds from start \n',samplingDuration);

%% 3 - Add a msgbox to start the tuner
%%need to use a different formulation whether I'm in Octave or Matlab

singString = sprintf('INSTRUCTIONS:  \n \t 1) Start by singing your lowest note for %g seconds. \n \t 2) When the software tells you, sing your highest note for %g seconds too. \n  DISCLAIMER: I will upload your singing to FB... just kidding! \n \t Are you ready to start??', round(samplingDuration),round(samplingDuration));
isThisOctave = exist('OCTAVE_VERSION') ~=0; 
if ~isThisOctave
    %%MATLAB FORMULATION
    uiwait(msgbox(singString,'Start the voice range test?','modal'));
    % NOTE:  
    % This command opens a MsgBox -(box with a text <" are you ready to start"> and an OK button). 
    %the Uiwait before the box stops the code until the user presses the OK
else
    %%OCTAVE FORMULATION!
    msgbox(singString);
    waitforbuttonpress();
end

%% 3.5 create GUI [figure with two sub-plots, with the time domain and freq. domain of the sound plot

figu1 = figure(1);
set(figu1,'Name','Voice range test', 'Position',[150,150,900,750],'Visible','off')
%movegui(figu1,'center')  %%movegui not implemented in Octave!

%%%EDIT POSITION OF ELEMENTS OF SUBPLOT AND ANNOTATION TEXT (DEFINED LATER
%%%ON). AS IT'S NOW, THE TWO PLOTS OVERLAP ON THE FIGURE!
axesTimeDomain = axes('Units','Pixels','Position',[100,500,750,200],'XGrid','on','YGrid','on','Visible','off');
xlabel('Time [sec]')
ylabel('amplitude')

axesFreqDomain = axes('Units','Pixels','Position',[100,200,750,200],'XGrid','on','YGrid','on','Visible','off');
xlabel('Freq [Hz]')
ylabel('Amplitude')

titleTimeDomain = uicontrol(figu1,'Style','text','Position',[250,700,500,30],'String',sprintf('Time Domain Plot'),'fontsize',11,'Visible','off');
titleFreqDomain = uicontrol(figu1,'Style','text','Position',[250,400,500,30],'String',sprintf('Freq. Domain Plot'),'fontsize',11,'Visible','off');

annoFigu1 =  uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',sprintf('Frequency analysis output \n Not enough time yet passed. Waiting for FFT to start'),'fontsize',13,'Visible','off');
closeButton = uicontrol(figu1,'Style','pushbutton','String','Close Window','FontSize',12,'Position',[700,30,120,50],'Visible','off','Callback', @buttonClose_Callback);

%% 4 - CREATE AN AUDIORECORDER OBJECT WITH TARGETDEVICE, FS ,NBITS
if targetDevice == 0
  audioRec = audiorecorder(fs,nbits,1);   %%use system default
  else
  audioRec = audiorecorder(fs,nbits,1,targetDevice);   %%this audiorecorder object will manage the sound input
end


%% 5 - PUT the audiorecorder TO listen to the microphone.

%before starting the audioRecorder, turn on the GUI.
set(figu1,'Visible','on');
set(axesTimeDomain,'Visible','on','Layer','top');
set(axesFreqDomain,'Visible','on','Layer','top');
set(annoFigu1,'Visible','on');
set(closeButton,'Visible','on');
set(titleTimeDomain,'Visible','on');
set(titleFreqDomain,'Visible','on');

%% FIRST RECORDER - GET THE SINGER'S DEEPEST NOTE
%%%before start to record, put a 3-second count-down to show up on the GUI!

%% 9 - (moved here) - Initialize some variables I'll use during the recording.
audioSampleLOW      = [];    %I will store the audio sample to be analyzed in this variable. It will reset any time the user presses the changeTuningNote button.
audioFreqPeaksLOW   = [];      %i will store here the peaks in intensity from the FFT of audioSample
audioFrequenciesLOW = [];      %frequency domain of the audioSample.
auxAudio            = []; 

%%add a longer While loop case the singer sings too shallowly and cannot get a peak frequency - itĺl return to this point after processing the frequency peaks;
leavePhase1 = 0;
while ~leavePhase1 
    tic
    currentTime = toc;
    while currentTime<=3
        currentTime = toc;
        annoFigu1 =  uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',sprintf('Get ready for singing.... %g \n',ceil(3-currentTime)),'fontsize',13,'Visible','on');
        drawnow
        %fprintf('Get ready for singing... %g\n',ceil(3-currentTime))
    end
    annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String','Singing test in progress...','fontsize',13,'Visible','on');
    
    disp('Voice Range Test:: Phase 1 starting NOW!')
    tic
    
    record(audioRec,samplingDuration);
    currentTime = toc;
    %% LAUNCH THE TUNER!
    while currentTime<samplingDuration
        currentTime = toc;
        %% 9a - plot the TIME domain recording
        if currentTime>1.5   %%%need to let some time pass before starting to plot cause if not the recorder will be empty
            audioSampleLOW = getaudiodata(audioRec);
            nas = length(audioSampleLOW);
            auxTimeLOW = currentTime:-1/fs:currentTime -(nas-1)/fs;
            auxTimeLOW = fliplr(auxTimeLOW);   %this matlab function puts auxTime backward.
            plot(axesTimeDomain,auxTimeLOW,audioSampleLOW,'k');
            drawnow;    %The "drawnow" order makes matlab do the plot within the loop (and not wait until it's completed) SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
            hold on
            grid on
            xlabel('Time [sec]')
            ylabel('amplitude')
            hold off
        end
    end %endwhile
    
    %% 9b - FFT of the audioSample (only if created)
    audioSampleLOW = detrend(audioSampleLOW);  %%just in case, remove the DC component (0 Hz) of the audioSample
    auxAudio = fft(audioSampleLOW);
    [audioFreqPeaksLOW,~,audioFrequenciesLOW] = fftFoldNorm(auxAudio,fs);   %i will disregard the phase information... Using fftFoldNorm code seen in the course!
    audioFrequenciesLOW = audioFrequenciesLOW';
    clear auxAudio
    
  %% 9c - UPDATE V 2018'-11-30: Cut off the input signal
    % to remove infra-sound components that may appear - - -CUT OFF @ 20Hz~!!
%     
whereIs20 = find(audioFrequenciesLOW > 20);
audioFrequenciesLOW = audioFrequenciesLOW(whereIs20);
audioFreqPeaksLOW = audioFreqPeaksLOW(whereIs20);
%%%TEST V0.3!!!

    %% 9d plot the FrReq domain figure
    plot(axesFreqDomain,audioFrequenciesLOW,audioFreqPeaksLOW,'b');
    grid on
    drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
    xlabel('frequency [Hz]')
    ylabel('amplitude')    
    
    %% 7 - get the frequency of the first audioFreqPeaks. Once found, plot it on freq.Domain plot
    %%use auxiliary function locatePeak (by Les Martiworks)
    freqPeakThreshold = 5*std(audioFreqPeaksLOW);
    peakLow = locatePeak(audioFreqPeaksLOW,audioFrequenciesLOW,freqPeakThreshold);   %make it return a -1 if no peak higher than the threshold (diff with noise > fPeakThreshold*Stdevs!) is found.
    %                                                          %Otherwise, return the POSITION IN THE FREQ. DOMAIN of such peak
    %% 8 - Relate it to the closest tuning note
    if peakLow >0
        leavePhase1 = 1;   %%% a peak frequency was found. Can leave this phase of the voice range test.
        %%add the frequency peak to the freqDomain plot
        hold on
        plot(axesFreqDomain,audioFrequenciesLOW(peakLow),audioFreqPeaksLOW(peakLow),'*','color','r','markersize',6);  %plot the detected frequency peak in the freq. domain plot
        drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
        hold off
        
        %create nice text messages to pass on to the figure (1), saying the current
        stringMsg1 = sprintf('Your low-note frequency is %g Hz',peakLow);
        stringMsg = sprintf('%s',stringMsg1);
        
        % send the messages as annotation to the figure (1) - handle " figu"
        annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',stringMsg,'fontsize',13,'Visible','on');
    end
    %%before closing the while loop, check if we can leave. If not, report in "annoFigu01" that the test must re-start
    if leavePhase1
        %do nothing!
    else
        %the test must be restarted. no frequency peak must found
        annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String','No frequency peak found. The test will restart!','fontsize',13,'Visible','on');
    end

end   %%end while ~leavePhase1.
disp('Voice Range Test:: Phase 1 Completed. Getting ready for phase 2')

%%add a longer While loop case the singer sings too shallowly and cannot get a peak frequency - itĺl return to this point after processing the frequency peaks;
leavePhase2 = 0;
while ~leavePhase2 
    tic
    currentTime = toc;
    while currentTime<=3
        currentTime = toc;
        annoFigu1 =  uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',sprintf('Get ready for singing again... %g',ceil(3-currentTime)),'fontsize',13,'Visible','on');
        drawnow
    end
    annoFigu1 =  uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String','Singing test in progress...','fontsize',13,'Visible','on');
    
    disp('Voice Range Test:: Phase 2 starting NOW!')
    tic
    record(audioRec,samplingDuration);
    
    currentTime = toc;
    %% LAUNCH THE TUNER!
    while currentTime<samplingDuration
        currentTime = toc;
        if currentTime>0.5   %%%need to let some time pass before starting to plot cause if not the recorder will be empty
            audioSampleHgh = getaudiodata(audioRec);
            nas = length(audioSampleHgh);
            auxTimeHgh = currentTime:-1/fs:currentTime -(nas-1)/fs;
            auxTimeHgh = fliplr(auxTimeHgh);   %this matlab function puts auxTime backward.
            plot(axesTimeDomain,auxTimeHgh,audioSampleHgh,'r');
            drawnow;    %The "drawnow" order makes matlab do the plot within the loop (and not wait until it's completed) SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
            hold on
            grid on
            xlabel('Time [sec]')
            ylabel('amplitude')
            hold off
        end
    end %endwhile
    
    %% 9b - FFT of the audioSample (only if created)
    audioSampleHgh = detrend(audioSampleHgh);
    auxAudio = fft(audioSampleHgh);
    [audioFreqPeaksHgh,~,audioFrequenciesHgh] = fftFoldNorm(auxAudio,fs);   %i will disregard the phase information... Using fftFoldNorm code seen in the course!
    audioFrequenciesHgh = audioFrequenciesHgh';
    clear auxAudio
    
    %% 9c - UPDATE V 2018'-11-30: Cut off the input signal
    % to remove infra-sound components that may appear - - -CUT OFF @ 20Hz~!!
%     
whereIs20 = find(audioFrequenciesHgh > 20);
audioFrequenciesHgh = audioFrequenciesHgh(whereIs20);
audioFreqPeaksHgh = audioFreqPeaksHgh(whereIs20);
%%%TEST V0.3!!!

    %% 9d plot the FrReq domain figure
    plot(axesFreqDomain,audioFrequenciesHgh,audioFreqPeaksHgh,'b');
    grid on
    drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
    xlabel('frequency [Hz]')
    ylabel('amplitude')
    
    %% 7 - get the frequency of the first audioFreqPeaks. Once found, plot it on freq.Domain plot
    %%use auxiliary function locatePeak (by Les Martiworks)
    freqPeakThreshold = 6*std(audioFreqPeaksHgh);
    peakHigh = locatePeak(audioFreqPeaksHgh,audioFrequenciesHgh,freqPeakThreshold);   %make it return a -1 if no peak higher than the threshold (diff with noise > fPeakThreshold*Stdevs!) is found.
    %                                                          %Otherwise, return the POSITION IN THE FREQ. DOMAIN of such peak
    
    %% 8 - Relate it to the closest tuning note
    if peakHigh >0
        leavePhase2 = 1;   %%% a peak frequency was found. Can leave this phase of the voice range test.
        %%add the frequency peak to the freqDomain plot
        hold on
        plot(axesFreqDomain,audioFrequenciesHgh(peakHigh),audioFreqPeaksHgh(peakHigh),'*','color','b','markersize',6);  %plot the detected frequency peak in the freq. domain plot
        drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
        hold off
        
        %create nice text messages to pass on to the figure (1), saying the current
        stringMsg2 = sprintf('Your high-note frequency is %g Hz',peakHigh);
        stringMsg = sprintf('%s \n %s',stringMsg1,stringMsg2);  %add the "high-note" result to the string with the low note.
        
        % send the messages as annotation to the figure (1) - handle " figu"
        annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',stringMsg,'fontsize',13,'Visible','on');
    end
    %%before closing the while loop, check if we can leave. If not, report in "annoFigu01" that the test must re-start
    if leavePhase2
        %do nothing
    else
        %the test must be restarted. no frequency peak must found
        annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String','No frequency peak found. The test will restart!','fontsize',13,'Visible','on');
    end

end   %%end while ~leavePhase2.

disp('Voice Range Test:: Phase 2 Completed. Analyzing voice range...')

%% 10: re-do the plots in a good-looking way
cla(axesTimeDomain)
cla(axesFreqDomain)

plot(axesTimeDomain,auxTimeLOW,audioSampleLOW,'k');
xlabel('time [sec]')
ylabel('amplitude')
grid on
hold on
plot(axesTimeDomain,auxTimeHgh,audioSampleHgh,'r');
hold off
legend('low note','high note')

plot(axesFreqDomain,audioFrequenciesLOW,audioFreqPeaksLOW,'k');
xlabel('frequency [Hz]')
ylabel('amplitude')
grid on
hold on
plot(axesFreqDomain,audioFrequenciesLOW(peakLow),audioFreqPeaksLOW(peakLow),'*','color','k','markersize',6);
plot(axesFreqDomain,audioFrequenciesHgh,audioFreqPeaksHgh,'r');
plot(axesFreqDomain,audioFrequenciesHgh(peakHigh),audioFreqPeaksHgh(peakHigh),'*','color','r','markersize',6);
hold off
legend('low note','low note fund. freq','high note','high note fund. freq')

%% 11: actual frequency comparison and voice range recognition.

%create a second figure to put the results of the voice analysis
figu2 = figure(2);
set(figu2,'Name','Voice analyzer results!','Position',[1200,150,600,800])
axesFreq = axes(figu2,'XGrid','on','YGrid','on','Visible','on','XLim',[0,1.1*max([max(hghNoteFreqs),max(peakHigh)])],'Position',[0.13,0.35,0.70,0.60]);  
annoFigu2 = uicontrol(figu2,'Style','text','Position',[30,80,400,150],'String','Voice analysis results','fontsize',13,'Visible','on');        
closeButton02 = uicontrol(figu2,'Style','pushbutton','String','Close Window','FontSize',12,'Position',[300,30,120,50],'Visible','on','Callback',@buttonClose_Callback);  %<<%this button doesn't want to work.

%do the plot
auxYourFreq = audioFrequenciesLOW(peakLow):audioFrequenciesHgh(peakHigh);
plot(axesFreq,auxYourFreq,ones(length(auxYourFreq),1),'k','linewidth',3)
title('frequency comparison of your voice to lyric voice ranges')
legendstring = {'Your Voice'};
xlabel('frequency [Hz]')
hold on
for i = 1:length(lowNoteFreqs)
    auxRange = lowNoteFreqs(i):hghNoteFreqs(i);
    plot(axesFreq,auxRange,(i+1)*ones(length(auxRange),1),'color',rand(1,3),'linewidth',3);
    legendstring = [legendstring lesVoiceNmes(i)];  %%lesVoiceNmes is a string array!    
end
legend(legendstring{:})
hold off

%% ADD A TEXT-BASED ANALYSIS OF VOICE RANGE!
%%use an auxiliary function - coincidence!
coincidenceRatios = zeros(length(lowNoteFreqs),1);
stringVoiceResults = {'Your voice matches the target ranges as follows:'};   %%this string I will use below for figure 2. I'll fill it up during the for loop that follows
for i = 1:length(lowNoteFreqs)
   coincidenceRatios(i) = 100*coincidenceVoice([audioFrequenciesLOW(peakLow), audioFrequenciesHgh(peakHigh)],[lowNoteFreqs(i) hghNoteFreqs(i)]);  
   %this aux. function will see what freq. range fits the closest the
   %subject's voice. Output is the percentage (of each target voice range)
   %that is covered by the singer!
   stringVoiceResults = [stringVoiceResults;{sprintf('You match %s by %g percent',string(lesVoiceNmes(i)),coincidenceRatios(i))}];
end
%get the maximum coincidenceRatio - subject's closest voice range, and
%report it.!
maxRatio = max(coincidenceRatios);
whereMaxRatio = find(coincidenceRatios == maxRatio);
singersVoice = lesVoiceNmes(whereMaxRatio);  %%<-- cell variable type!

%simple report for figure 1 - say only which voice range is best match
annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',sprintf('Your lowest note was %g [Hz] \n Your highest note was %g [Hz] \n Your voice most closely relates to %s \n',audioFrequenciesLOW(peakLow),audioFrequenciesHgh(peakHigh),string(singersVoice)),'fontsize',13,'Visible','on');        

%detailed report for figure 2 - report the % match to each voice range
annoFigu2 = uicontrol(figu2,'Style','text','Position',[30,80,400,150],'String',string(stringVoiceResults),'fontsize',12,'Visible','on');        
drawnow

%%FOR FUNCTION MODE ONLY!
testComplete = 1;  %whatever output, Test completed successfully
end %endfunction

%%%%%%%%%%%%%%%%--------------------------------------------
%% ANCILLARY FUNCTIONS - GUI BUTTONS CALLBACKS.

function buttonClose_Callback(src,~)   %%here: src is the source object from where this callback has been called. and "event" is a an "actionData" obj. saying "action"
%call back to close parent figure    %% <---  SRC https://stackoverflow.com/questions/9413341/add-a-button-on-a-figure-and-to-close-the-figure-in-matlab
%     src
%     event
    close(get(src,'Parent'))       %%this statement says: close the parent object of src (the button that was pressed and called this function!)
end  %endfunction

function coincRatio = coincidenceVoice(yourVoiceRange,stdVoiceRange)
%function coincRatio = coincidenceVoice([yourVoiceRangeLow yourVoiceRange High],[stdVoiceRangeLow stdVoiceRangeHigh])
%auxiliary function to calculate how much of the test subject's voice range
%matches a standardized voice range
%Input: both series' low and hgh frequencies
%Output:percentage of targetVoiceRange that is covered within the yourVoiceRange.
sngrFreqRange = stdVoiceRange(2) - stdVoiceRange(1);

coincRatio = 1;
%diff 01: yourHigh - rangeHigh
diff01 = yourVoiceRange(2)-stdVoiceRange(2);
if diff01>0
    coincRatio = 1 - 0; %don't reduce the coincidenceRatio / the high-freq limit is covered
else
    coincRatio = coincRatio - (-diff01)/sngrFreqRange;
end
%diff 02: your Low - range Low
diff02 = yourVoiceRange(1) - stdVoiceRange(1);
if diff02>0
   coincRatio = coincRatio - (diff02/sngrFreqRange);     %reduce coincidenceRatio / a stretch of the low-freq limit is NOT covered
else
    coincRatio = coincRatio - 0;
end
%%>> all done, export result!
end  %endfunction