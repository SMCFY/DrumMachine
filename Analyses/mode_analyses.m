% Analyses of mode distribution in the attack portion of recorded samples
filepath = '/Users/geri/Documents/Uni/SMC8/P8/DrumMachine/RecordingSess/Samples/';
[x1 fs] = audioread([filepath, 'Tom_big/tom_big_pos1.aif']);
x2 = audioread([filepath, 'Snare/snare_pos1.aif']);
x3 = audioread([filepath, 'Cymbal/cymbal_pos1.wav']);
x4 = audioread([filepath, 'Kick_ass/kick_pos1.wav']);

fftSize = 1024; % window size
window = x1(1:fftSize).*hamming(fftSize); % hamming window of the attack
window = [window; zeros(2^15,1)]; % zero padded signal (higher DFT resolution)
Xmag = abs(fft(window)); % magnitude spectrum

w = [0:length(window)-1].*fs/length(window); %frequency in Hertz

subplot(2,1,1);
plot(window(1:fftSize)); % time domain
title('windowed signal');
subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2))); % db spectrum
title('magnitude spectrum');

%peakLoc = 20*log10(Xmag(1:length(Xmag)/2));
%% results
% estimated mode frequencies in Hertz
tom_big = [115, 215, 305, 446, 508, 607, 712, 816, 1027, 1139, 1321, 1896]; 
snare = [194, 346, 475, 716, 1291, 1472, 1870, 2842, 3462, 4125, 4634, 4945];
cymbal = [695, 874, 1015, 2601, 2739, 3712, 4876, 5548, 5768, 6145, 6593, 7428];
cardboard = [47, 200, 315, 561, 643, 748, 950, 1296, 1445, 2082, 2258, 2468];

modes_invFilt = struct('tom', tom_big, 'snare', snare, 'cymbal', cymbal, 'kick', cardboard);