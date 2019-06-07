function lePeak = locatePeak(amplitude,frequency,peakThreshold)
%function lePeak = locatePeak(vector,threshold)
%This function will locate the 1st peak on a vector of values. Search
%criterion: the peaks shall be distant from the vector's mean more than
%peakThreshold x stdev(vector)
%
%function will return:
%lePeak = -1 if there is no point in "vector" which satisfies being greater
%than the mean value by the peakThreshold
%lePeak = position (>0) if such peak exists
%
%NOTE: this function has been crafted to work only with POSITIVE (GREATER
%THAN AVG.) PEAKS
%
%V0.2 "Tuesday"                2018-11-20
%CHANGELOG: Uses built-in function "locatepeaks" to search for possible
%sub-multiples of the peak freq. instead of a recursion (which overflows matlab)
%           Added "frequency" input to correct a mistake in the harmonic
%           selection (it was using ratios in vect. position; not actual
%           frequency ratios)
%V0.1 "Thanksgiving Recursion" 2018-11-19
%CHANGELOG: Function will run on a recursive loop until a single peak <or
%none> is left. /// abandoned
%V0.0 2018-11-06
%
%Developed by Les MartiWorks

%initialize - set the worst-case scenario output for locatePeak
lePeak = -1;

%get the mean and maximum of vector
nn  = mean(amplitude);
%stdd = std(vector);
nmax = max(amplitude);
posmax = find(amplitude==nmax);
fmax = frequency(amplitude==nmax);  %save using posmax here

if fmax-nn < peakThreshold%*stdd
    %vector's maximum doesnt' satisfy the threshold. No more math to do.
    %lePeak = -1
    return
else
    %there is a peak, and qualifies as maximum. 
    %Just in case, search for any other peaks that can also qualify at
    %lower frequencies (nmax is a harmonic). 
    %
    %a) Recursive loop - pass on a vector with all the peaks above
    %threshold at frequencies lower than nmax
    %The tuner assumes that no sub-harmonic exist!
    vectorChopped = amplitude(1:floor(0.9*posmax));  %chopped vector to pass on.  // a case where this methodolgy would fail is if the peak is >= 10th harmonic (hard to occur actually)
    if length(vectorChopped)<=3
        %%added this condition to prevent a crash in Matlab, if
        %%vectorChopped has less than 3 elements, findPeaks won't have
        %%enough elements to work and give out an error. 
        return
    else
        maybePeaks = findpeaks(vectorChopped);   %maybePeaks will be the amplitude values in "amplitude" which are local maxima
        maybePkPos = [];  %%need to locate the position of hte Peaks. Matlab doesn't like find statements with vectora == vector b element by element. Will need a for loop
        for i = 1:length(maybePeaks)  %%note: I'm assuming matlab will return a non-zero vector in maybePeaks
            maybePkPos = [maybePkPos find(amplitude == maybePeaks(i))];
        end
        maybeFundFreq = frequency(maybePkPos);
        
        if isempty(maybePeaks)  %findpeaks will always return a peak value, this case shall never happen'
            %However, if so, it means there's no worthy peak in the chopped vector.
            %Pass nmax!
            lePeak = posmax;
        else
            %firstly - check if the local maxima below nmax are actual peaks
            %(i.e. their amplitude is greater than the threshold)
            %auxMaybePeaks = find(maybePeaks-nn>peakThreshold);
            maybePeaks = maybePeaks(maybePeaks-nn>peakThreshold); %get only the potential peaks from maybePeaks [those greater than Threshold]
            maybePkPos = [];  %%need to locate the position of hte Peaks. Matlab doesn't like find statements with vectora == vector b element by element. Will need a for loop
            for i = 1:length(maybePeaks)  %%note: I'm assuming matlab will return a non-zero vector in maybePeaks
                maybePkPos = [maybePkPos find(amplitude == maybePeaks(i))];
            end
            maybeFundFreq = frequency(maybePkPos);    %update the possible fundFreq values with the actual fund.freq. peaks
            
            %now check if the maybeFUndFreqs are actual sub-multiples of nmax
            %and fmax / reduce the maybeFundFreqs to the sub-multiple cases only
            integerTolerance = 0.015;
            freqRatio = fmax./maybeFundFreq;
            errorRatio = abs(freqRatio-round(freqRatio));
            maybeFundFreq = maybeFundFreq(errorRatio<integerTolerance);
            if isempty(maybeFundFreq)
                lePeak = posmax;     %%all the peaks that are at freqs lesser than fmax aren't sub-multiples (I'm dealing with noise). Pass nmax
            else
                %there is one or more sub-multiples of nmax which are good
                %maxima. Pass the smaller position one which is the sound's fundamental
                %freq.
                lePeak = maybePkPos(1);
            end
        end
    end
end
%endFunction



