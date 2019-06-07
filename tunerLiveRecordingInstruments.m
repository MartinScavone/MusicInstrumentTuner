function funcOutput = tunerLiveRecordingInstruments(whatInstrumentID,targetDevice,fs,nbits,freqQuality)
%function funcOutput = tunerLiveRecordingInstruments(whatInstrumentID,targetDevice,fs,nbits,freqQuality);
%
%Instrument tuner core function - to be called to tune instruments.
%code based on the original LiveRecorder by XXXX [INSERT CREDIT TO AUTHOR OF LIVERECORDING]
%I deprived it of all the user interface - i'm not that familiar with it
%and don't want so many buttons. Let's see if a command-line based UI works
%enough.
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
%updated v0.3 "Coffee and donuts" - 2018-11-30
%changelog: see changelog in tuneRecordingVoice
%V0.0 AllSaints - 2018-11-01/06 by Les MartiWorks.

%close figures
if exist('figu1','var')
    close figures   %%added to close the figures before running. If I don't do this, they will start to overlape
end

global figu1 
global stopRecording %%Global Variables I'm going to need


%% 1 - Get the frequency table for "whatInstrument"
%%1 - locate instrument ID and bring the table of frequencies from the frequencyTable
load frequencyTable.mat frequencies;        %this MAT file contains a structure with the tuning frequencies for the compatible instruments.
instrumentNumID = zeros(1,max(size(frequencies)));
%fill the instrumentNumID vector with a for loop (Matlab doesn't like to
%bring all values at once)
for i = 1:length(frequencies)
   instrumentNumID(i) = frequencies(i).numericalID; 
end
instrPos = find(instrumentNumID==whatInstrumentID);   %the front-end checks that a valid instrument is input before calling the Tuner. So this find must always yield a result.

%% 2 - Now, bring the tuning notes [frequencies and names]
tuningNotesFreqs = frequencies(instrPos).freqs;
tuningNotesNames = frequencies(instrPos).notes;

%% 7 (or 3.5) - Target frequency resolution and sample durataion
%a) set the target deltaFreq. Use the freqQuality input (30 / 10 / 5 cents)
% the tuner's deltaFreq will be freqQuality/100 * frequency of the lowest note to tune.
%-- get it from tuningNotesFreqs
deltaFreq = freqQuality/100*(2^(1/12)-1)*min(tuningNotesFreqs);   %
  
%b) get the sampling duration for my deltaFreq.
samplingDuration = 1/deltaFreq;
sampleTargetSize = ceil(fs/deltaFreq);
%  NOTE: FOR A 5-STR BASE GUITAR, samplingTargetSize at ultra resolution is about 10333 smples, 0.7 seconds!
fprintf('Tuner Live Recorder:: Frequency resolution will be %g Hz. \n',deltaFreq);
fprintf('Tuner Live Recorder:: Frequency analysis will start after %g seconds from start \n',samplingDuration);

%% 3 - Add a msgbox to start the tuner
%%need to use a different formulation whether I'm in Octave or Matlab

isThisOctave = exist('OCTAVE_VERSION') ~=0; 
if ~isThisOctave
    %%MATLAB FORMULATION
    uiwait(msgbox(sprintf('INSTRUCTIONS:  \n Play the tuning notes in your instrument and let the tuner hear you. \n Press the "Close Window" button once you are done tuning \n \t Are you ready to start?'),'Start the tuner?','modal'));
    % NOTE:  
    % This command opens a MsgBox -(box with a text <" are you ready to start"> and an OK button). 
    %the Uiwait before the box stops the code until the user presses the OK
else
    %%OCTAVE FORMULATION!
    msgbox(sprintf('INSTRUCTIONS:  \n Play the tuning notes in your instrument and let the tuner hear you. \n Press the "Close Window" button once you are done tuning \n \t Are you ready to start?'),'Start the tuner?','modal');
    waitforbuttonpress();
end

%% 3.5 create GUI [figure with two sub-plots, with the time domain and freq. domain of the sound plot

figu1 = figure(1);
set(figu1,'Name','Musical Instrument Tuner', 'Position',[350,150,900,750],'Visible','off')
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
stopButton = uicontrol(figu1,'Style','pushbutton','String','Stop Recording','FontSize',12,'Position',[700,90,120,50],'Visible','off','Callback', @buttonStop_Callback);
closeButton = uicontrol(figu1,'Style','pushbutton','String','Close Window','FontSize',12,'Position',[700,30,120,50],'Visible','off','Callback', @buttonClose_Callback);


%% 4 - CREATE AN AUDIORECORDER OBJECT WITH TARGETDEVICE, FS ,NBITS
if targetDevice ==0
  audioRec = audiorecorder(fs,nbits,1);   %%record with the system default audio capture device
else
  audioRec = audiorecorder(fs,nbits,1,targetDevice);   %%this audiorecorder object will manage the sound input
end
%% 5 - PUT the audiorecorder TO listen to the microphone.

stopRecording = 0;     %this value will be tied to a msgbox that will ask when you wnat to stop (it will turn to 1 when pressed)

%before starting the audioRecorder, turn on the GUI.
set(figu1,'Visible','on');
set(axesTimeDomain,'Visible','on','Layer','top');
set(axesFreqDomain,'Visible','on','Layer','top');
set(annoFigu1,'Visible','on');
set(stopButton,'Visible','on');  %they don't want to show up!
set(closeButton,'Visible','on');
set(titleTimeDomain,'Visible','on');
set(titleFreqDomain,'Visible','on');

%% 9 - (moved here) - Initialize some variables I'll use during the recording.
audioSample      = [];    %I will store the audio sample to be analyzed in this variable. It will reset any time the user presses the changeTuningNote button.
audioFreqPeaks   = [];      %i will store here the peaks in intensity from the FFT of audioSample
audioFrequencies = [];      %frequency domain of the audioSample.
auxAudio         = []; 

 tic
 currentTime = toc;
 while currentTime<=3
        currentTime = toc;
        annoFigu1 =  uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',sprintf('Get ready, starting in.... %g \n',ceil(3-currentTime)),'fontsize',13,'Visible','on');
        drawnow
        %fprintf('Get ready for singing... %g\n',ceil(3-currentTime))
 end
disp('Tuner Live Recorder:: recorder starting NOW')
tic
record(audioRec,inf);
 
%% LAUNCH THE TUNER!
while ~stopRecording    %%%the tuner should stop alone when pressing the stop button in the window (the callback function changes stopREcording, which is global)
    currentTime = toc;
%     if currentTime>6*samplingDuration  %%%manual kill - REMOVE WHEN RETURNING TO FUNCTION MODE!
%         stopRecording = 1;
%     end   
  %% 9a - plot the TIME domain recording
  if currentTime>1.2   %%%need to let some time pass before starting to plot cause if not the recorder will be empty
    audioSample = getaudiodata(audioRec);
    nas = length(audioSample);
    auxTime = currentTime:-1/fs:currentTime -(nas-1)/fs;
    auxTime = fliplr(auxTime);   %this matlab function puts auxTime backward.      
    plot(axesTimeDomain,auxTime,audioSample,'k');
    drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
    hold on
    grid on
    xlabel('Time [sec]')
    ylabel('amplitude')
    hold off
  end

  %% 9b - pull data for length > samplingDuration, cut it to a target Sample Size and do the FFT
  if currentTime>max(1.5*samplingDuration,1.5)  %%update V2018-11-30 - added a fixed 1 sec threshold cause the recording lag can take more than sampleDuration to actually start recording.
    %%add some 0% more time to get the first sample because when this if first occurs, the size of audioSample is smaller than TargetSize (even though samplingDur and sampleTarg.Size have been defined consistently)      
    %size of sample to retrieve is sampleTargetSize. and audioSample should be equal or larger than that
    if sampleTargetSize < length(audioSample) 
        audioSample = audioSample(end-floor(sampleTargetSize)+1:end);   %%%this is the sample size I need to plot in time
    end
    %timeIncrement = 1/fs
    
    %% 9c - FFT of the audioSample (only if created)
    auxAudio = fft(audioSample);
    [audioFreqPeaks,~,audioFrequencies] = fftFoldNorm(auxAudio,fs);   %i will disregard the phase information... Using fftFoldNorm code seen in the course!
    clear auxAudio
    
    %% 9d plot the FReq domain figure
    plot(axesFreqDomain,audioFrequencies,audioFreqPeaks,'b');
    grid on
    drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
    xlabel('frequency [Hz]')
    ylabel('amplitude')
    
    %% 9E - UPDATE V0.3 - CHOP OFF THE INFRA SOUNDS (remove freqs. lower than 20 HZ) AND PROCEED TO PEAK RECOGNITION
    whereIs20 = find(audioFrequencies > 20);
audioFrequencies = audioFrequencies(whereIs20);
audioFreqPeaks = audioFreqPeaks(whereIs20);
    
    %% 7 - get the frequency of the first audioFreqPeaks. Once found, plot it on freq.Domain plot 
    %%use auxiliary function locatePeak (by Les Martiworks)
    freqPeakThreshold = 6*std(audioFreqPeaks);
    freqPeak = locatePeak(audioFreqPeaks,audioFrequencies,freqPeakThreshold);   %make it return a -1 if no peak higher than the threshold (diff with noise > fPeakThreshold*Stdevs!) is found.
    %                                                          %Otherwise, return the POSITION IN THE FREQ. DOMAIN of such peak
            
    %% 8 - Relate it to the closest tuning note
    if freqPeak >0 
        hold on       
        plot(axesFreqDomain,audioFrequencies(freqPeak),audioFreqPeaks(freqPeak),'*','color','r','markersize',6);  %plot the detected frequency peak in the freq. domain plot
        drawnow;    %SRC  https://stackoverflow.com/questions/2800066/plot-inside-a-loop-in-matlab
        hold off
        auxFreqTarget = abs(audioFrequencies(freqPeak) - tuningNotesFreqs);
        auxFreqTarg02 = min(auxFreqTarget);
        auxFreqTarget = find(auxFreqTarget==auxFreqTarg02);   %find the tuning note that is closest to the freqPeak (the smallest difference to the tuningNotesFreqs 
        targetFrequency = tuningNotesFreqs(auxFreqTarget);
        targetNoteName  = tuningNotesNames(auxFreqTarget);  %send these two to a dialog box!!
             
        %%analyize if the frequency target is greater or smaller than the
        %%freqPeak. Order the player to loosen or tighten the strings accordingly
       
        if auxFreqTarg02 < deltaFreq   %%your difference with the target frequency is within range - you're good!
            stringMsg = sprintf('Tuning ok!');
        else  %%off the frequency resolution, adjust tuning
            if audioFrequencies(freqPeak) > targetFrequency
                stringMsg = sprintf('Current frequency too high - loose string');
            else
                stringMsg = sprintf('Current frequency too low - tighten string');
            end            
        end
                
        %create nice text messages to pass on to the figure (1), saying
        %your current, target frequency and target note.
        stringMsg1 = sprintf('Target Frequency is %g Hz, target musical note is %s',targetFrequency,string(targetNoteName));
        stringMsg2 = sprintf('Your current frequency is %g Hz',audioFrequencies(freqPeak));
        stringMsg = sprintf('%s \n %s \n %s',stringMsg1, stringMsg2, stringMsg);
        
        % send the messages as annotation to the figure (1) - handle " figu"
        annoFigu1 = uicontrol(figu1,'Style','text','Position',[50,50,500,100],'String',stringMsg,'fontsize',13,'Visible','on');  
    end      
  end  %endIf toc>samplingDuration
end   %endwhile

pause(audioRec)  %Beta-testing shows the audioRec keeps running after leaving the while loop. I add this other stop command just in case
disp('Tuner Live Recorder:: tuning terminanted. Returning to front-end')

funcOutput = 1;  %whatever output, 

end  %endfunction

%% - ANCILLARY FUNCITONS~
function buttonStop_Callback(~,~)
%callback for when pressing the "stop recording" button
    global stopRecording   %% the global statement has also to be done in the child callback function,m otherwise it won't be modified. https://www.mathworks.com/help/optim/ug/passing-extra-parameters.html#brhntus-1
    stopRecording = 1;
    disp('Tuner Live Recorder:: stop button pressed')
end

function buttonClose_Callback(src,~)   %%here: src is the source object from where this callback has been called. and "event" is a an "actionData" obj. saying "action"
%call back to close parent figure    %% <---  SRC https://stackoverflow.com/questions/9413341/add-a-button-on-a-figure-and-to-close-the-figure-in-matlab
%     src
%     event
    close(get(src,'Parent'))       %%this statement says: close the parent object of src (the button that was pressed and called this function!)
end
