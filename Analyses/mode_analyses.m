% Analyses of mode distribution in the attack portion of recorded samples
filepath = '/Users/geri/Documents/Uni/SMC8/P8/DrumMachine/RecordingSess/Samples/';
[x1 fs] = audioread([filepath, 'Tom_big/tom_big_pos1.aif']);
x2 = audioread([filepath, 'Snare/snare_pos1.aif']);
x3 = audioread([filepath, 'Cymbal/cymbal_pos1.wav']);
x4 = audioread([filepath, 'Kick_ass/kick_pos1.wav']);

fftSize = 1024; % window size
window = x2(1:fftSize).*hanning(fftSize); % rectangular window of the attack
window = [window; zeros(2^15,1)]; % zero padded signal (higher DFT resolution)
Xmag = abs(fft(window)); % magnitude spectrum

w = [0:length(window)-1].*fs/length(window); %frequency in Hertz

subplot(2,1,1);
plot(window(1:fftSize)); % time domain
title('windowed signal');
subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2)), '.'); % db spectrum
title('magnitude spectrum');

%peakLoc = 20*log10(Xmag(1:length(Xmag)/2));
%% results
% estimated mode frequencies and bandwidths in Hertz
tom_big = [115, 19;
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

modes = struct('tom', tom_big, 'snare', snare, 'cymbal', cymbal, 'kick', cardboard);