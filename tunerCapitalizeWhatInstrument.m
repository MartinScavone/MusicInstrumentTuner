function numID = tunerCapitalizeWhatInstrument(instrumentID)
%function b = tunerCapitalizeWhatInstrument(a);
%auxiliary function to the tuner's frontEnd: IT WILL CONVERT THE ORIGINAL
%MUSICAL INSTRUMENT ID TO A NUMERICAL ID. (because the tuner's Core won't
%work with text IDs'


if instrumentID=='v' || instrumentID == 'V'
    numID = 4;
elseif instrumentID =='p'|| instrumentID == 'P'
    numID = 5;    
elseif instrumentID =='g' || instrumentID == 'G'
    numID = 1;
elseif instrumentID == 'b' || instrumentID == 'B'  %instrumentID== 'bg4' || instrumentID == 'BG4' || 
    numID = 2;
elseif instrumentID || 'j' || instrumentID == 'J'  %instrumentID == 'bg5' || instrumentID == 'BG5' ||
    numID = 3;
end

%%additionally, assign numerical ID to voices 
if instrumentID == 'F' || instrumentID == 'f'
    numID = 1;
elseif instrumentID =='M' || instrumentID == 'm'
    numID = 2;
end

%%%%
    
    
