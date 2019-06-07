function [Xmag,Xph,f] = fftFoldNorm(X,fs)
%function [Xmag,Xph,f] = fftFoldNorm(X,fs)
%Returns a normalized, 1-sided dft spectrum
% inputs: 
% X: 2-sided DFT spectrum, ex. X = fft(x)
% fs: sampling rate
%
%outputs:
% Xmag: DFT magnitude (floor(N/2)+1 points)
% Xph: DFT phase (floor(N/2)+1 points)
% f: DFT frequency (floor(N/2)+1 points)

N = length(X); %Number of samples
k = 0:(N-1); %frequency index (number of cycles in T)
%% Convert to magnitude and phase
mag1 = abs(X);
phase1 = angle(X);

%% DFT/FFT folding and normalization
Xmag = mag1(1:floor(N/2)+1); %take only the first half of spectrum
Xmag(2:floor(N/2)) = 2*Xmag(2:floor(N/2)); %double everything except k=0 and k = N/2-1;
Xmag = Xmag/N; %normalize by N to get signal amplitude
Xph = phase1(1:floor(N/2)+1);


%% Convert to frequency
f = k(1:floor(N/2)+1)*fs/N;