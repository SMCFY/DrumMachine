% Main program for BDWGM + residuals

%% load residuals, modes and mode bandwidth

[res, fs] = audioread('tom_big_res.wav'); % r = 0.98
[res2, fs] = audioread('tom_big_res_bw.wav'); % variable r, depending on bandwidth
modes = load('modes.mat');
tom = modes.tom_big;
[tomOriginal, fs] = audioread('tom_big_pos1.aif');
tomOriginal = tomOriginal';

%% basic variables

fs = 44100;
Tsec = 1; % duration of simulation (Seconds)
Tsamp = Tsec*fs; % duration of simulation (Samples)
Tsamp = length(tomOriginal); 

%% 2d square mesh (for high freqs)

% NJ        : number of junctions
% a         : lowpass a coefficient
% exc_size  : size of excitation in 
NJ = 24;
exc_size = 20;
exc_pos = 50;
a = 0.15;
decayFactor = 0.99;
%y_mesh = f_mesh_square( NJ, decayFactor, a, exc_size, exc_pos, Tsamp, fs );

%% bdwg (for low freqs)

freqs = tom(:,1)'; % fundamental frequency of delay lines (modes) (Hertz)
freqs = [112 188 203 259 279 332 346 375 400 450 475 488 497 550 602 625 654 805 852 975 998 1019 1047 1082 1109 1135 1164 1226 1312 1358 1379 1533 1682];
decay = [0.9999 0.9999 0.9999 0.9999 0.9998 0.9997 0.9997 0.9996 0.9996 0.9996 0.9995 0.9995 0.9995 0.9994 0.9994 0.9997 0.9996 0.9993 0.999 0.999...
    0.9995 0.9995 0.999 0.99 0.99 0.99 0.99 0.99 0.999 0.99 0.99 0.99 0.99]; % decay factors
decay = [0.9999 0.9999 0.9999 0.9999 0.9999 0.9999 0.9996 0.9999 0.9999 0.9996 0.9995 0.9995 0.9995 0.9994 0.9994 0.9997 0.9996 0.9993 0.999 0.999...
    0.9995 0.9995 0.999 0.99 0.99 0.99 0.99 0.99 0.999 0.99 0.99 0.99 0.99];
%decay = [1 1 1 1 1 1 1 1 1 1 1]; 

low_high = [0.75; 1.25]; % low and high freq of BP filter (percentage)
B = tom(:,2);
B = [5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5]';

y_bdwg = f_bdwg( freqs, B, decay, Tsamp, fs, low_high, res );

%% put everything together

%y1 = y_mesh + y_bdwg;
y1 = y_bdwg;
y2 = conv(y1, res);

plot(tomOriginal/max(tomOriginal))
hold on
plot(y2/max(y2))

%Spec(y1, fs)
%Spec(y2, fs)
soundsc(y2, fs)

