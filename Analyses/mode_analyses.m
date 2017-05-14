% Analyses of position 1(middle) samples, and extraction of frequency and
% bandwidth of modes for each instrument's attack

[x fs] = audioread('/Users/geri/Documents/Uni/SMC8/P8/DrumMachine/RecordingSess/Cropped_Samples/Tom_big/tom_big_pos1.aif');

fftSize = 2048; % window size
window = x(1:fftSize); % rectangular window of the attack
window = [window; zeros(2^15,1)]; % zero padded signal (higher DFT resolution)
Xmag = abs(fft(window)); % magnitude spectrum

w = [0:length(window)-1].*fs/length(window); %frequency in Hertz

subplot(2,1,1);
plot(window(1:fftSize)); % time domain
title('windowed signal');
subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2)), '.'); % db spectrum
title('magnitude spectrum');

%% results
tom_big = [115, 19;   % estimated mode frequencies and bandwidths in Hertz
           215, 14;
           305, 17;
           446, 18;
           508, 16;
           607, 20;
           712, 17;
           816, 20;
           1027, 17;
           1139, 15;
           1321, 17]; 
snare = [0, 0];
cymbal = [0, 0];
cardboard = [0, 0];