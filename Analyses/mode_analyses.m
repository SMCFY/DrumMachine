% Analyses of mode distribution in the attack portion of recorded samples

%filepath = '/Users/geri/Documents/Uni/SMC8/P8/DrumMachine/RecordingSess/Samples/';
% [x1 fs] = audioread([filepath, 'Tom_big/tom_big_pos1.aif']);
% x2 = audioread([filepath, 'Snare/snare_pos1.aif']);
% x3 = audioread([filepath, 'Cymbal/cymbal_pos1.wav']);
% x4 = audioread([filepath, 'Kick_ass/kick_pos1.wav']);

[x1 fs] = audioread('Tom_big/tom_big_pos1.aif');
x2 = audioread('Snare/snare_pos1.aif');
x3 = audioread('Cymbal/cymbal_pos3.wav');
x4 = audioread('Kick_ass/kick_pos1.wav');

x1_len = length(x1);
x2_len = length(x2);
x3_len = length(x3);
x4_len = length(x4);

fftSize = 1024; % window size
startfft = 700;
%window = x2a(startfft:end).*hamming(length(x2a(startfft:end))); % hamming window of the attack

num=20;
window = sigFilt(startfft:end,num).*hamming(length(sigFilt(startfft:end,num)));

window = [window; zeros(2^15,1)]; % zero padded signal (higher DFT resolution)
Xmag = abs(fft(window)); % magnitude spectrum

w = [0:length(window)-1].*fs/length(window); %frequency in Hertz

figure
% subplot(2,1,1);
% plot(window); % time domain
% title('windowed signal');
% subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2))); % db spectrum
title('magnitude spectrum');

%peakLoc = 20*log10(Xmag(1:length(Xmag)/2));

%% results resonator modes
%tom_bigM(1,:) = [112, 202, 257, 297, 331, 344, 374, 400, 450, 484, 549, 603, 653, 690, 760, 807, 1024, 1318, 1553, 1680, 1755, 2214, 2327, 2543, 2697, 2808, 2921, 3102, 3400, 3880, 4134, 5224, 6106, 7497, 8934];
tom_bigM(1,:) = [112, 203, 259, 279, 300, 332, 345, 375, 398, 407, 450, 473, 488, 488, 547, 596, 625, 653, 679, 692, 705, 760, 773, 806, 852, 899, 924, 975, 998, 1019, 1046, 1109, 1134, 1164, 1192, 1226, 1309, 1358, 1379, 1411, 1461, 1532, 1610, 1683, 1758, 1880, 2027, 2131, 2271, 2515, 2731, 2809, 2922, 3224, 4694, 5563];
tom_bigM(2,:) = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1, 1, 50, 50, 5, 50, 100, 5, 5, 10, 50, 200, 150];
tom_bigM(3,:) = [0.9999 0.9999 0.9998 0.9998 0.9998 0.9997 0.9997 0.9996 0.9996 0.9995...
    0.9995 0.9994 0.9994 0.9993 0.9993 0.9992 0.9992 0.9991 0.9991 0.999 0.999...
    0.998 0.998 0.997 0.997 0.996 0.996 0.995 0.995 0.994 0.994 0.993...
    0.993 0.992 0.992 0.991 0.991 0.991 0.991 0.991 0.991 0.991 0.991 0.991 0.99...
    0.993 0.992 0.991 0.99 0.98 0.98 0.98 0.97 0.97 0.97 0.96];

snareM(1,:) = [706 190 705 1145 967 957 985 1003 835 294 415 530 791 1216 1291 ...
    1339 1469 1874 1958 3049 4616 5656];
snareM(2,:) = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 20 20 1];
snareM(3,:) = [0.99 0.99 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 ...
    0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 ...
    0.98];

% snareM(1,:) = maxtab(1:27,1);
% snareM(2,:) = ones(1, 27);
% snareM(3,:) = [0.999 0.99 0.99 0.99 0.995 0.998 0.995 0.99 0.991 0.991 0.995 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99 0.99];

cymbalM(1,:) = [79 693 836 883 1212 1511 1793 1863 2666 3198 3657 ...
    3741 4556 4725 4867 5005 6165 5768]; %  6840  6461
cymbalM(2,:) = [1 1 1 1 1 2 1 1 1 5 1 1 1 1 1 1 1 5];
%cymbalM(2,:) = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
cymbalM(3,:) = [0.99 0.9998 0.9998 0.9989 0.999 0.995 0.995 0.995 0.9999 0.994 ...
    0.9998 0.9998 0.9998 0.994 0.994 0.999 0.999 0.999];

cardboardM(1,:) = [27 44 54 72 100 123 151 170 232 247 263 299 317 ...
    331 353 368 409 618];
cardboardM(2,:) = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 3 2];
cardboardM(3,:) = [0.999 0.99 0.99 0.99 0.99 0.9 0.9 0.98 0.9 0.94 0.94 0.98 ...
    0.94 0.94 0.94 0.94 0.93 0.92];
%cardboardM(3,:) = ones(1, length(cardboardM(3,:)));

modes_10k = struct('tom', tom_bigM, 'snare', snareM, 'cymbal', cymbalM, 'kick', cardboardM);
% [snareM, zeros(1,length(tom_bigM)-length(snareM))]

% cardboardM(1,:) = [27, 54, 74, 100, 124, 149, 171, 200, 208, 230, 244, 259, 301, 318, 332, 350, 370, 407, 436, 454, 477, 494, 525, 558, 636, 744, 894, 975, 1128, 1348, 1527, 2081, 2434, 3370, 4347, 5372, 7031];
% cardboardM(2,:) = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 5, 5, 2, 1, 2, 5, 5, 10, 5, 5, 5, 5, 10, 10];
% cardboardM(3,:) = [0.99 0.99 0.99 0.99 0.97 0.97 0.98 0.98 0.98 0.98 0.98 0.98...
%     0.99 0.99 0.99 0.99 0.99 0.99 0.9 0.9 0.9 0.9 0.9 0.9 0.9 0.9 0.89 0.89...
%     0.89 0.89 0.89 0.89 0.89 0.89 0.89 0.89 0.89];

%% results
% estimated mode frequencies in Hertz
tom_big = [115, 215, 305, 446, 508, 607, 712, 816, 1027, 1139, 1321, 1896]; 
snare = [194, 346, 475, 716, 1291, 1472, 1870, 2842, 3462, 4125, 4634, 4945];
cymbal = [695, 874, 1015, 2601, 2739, 3712, 4876, 5548, 5768, 6145, 6593, 7428];
cardboard = [47, 200, 315, 561, 643, 748, 950, 1296, 1445, 2082, 2258, 2468];

modes_invFilt = struct('tom', tom_big, 'snare', snare, 'cymbal', cymbal, 'kick', cardboard);