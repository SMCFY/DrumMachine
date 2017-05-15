% Main program for BDWGM + residuals

%% load residuals

[res, fs] = audioread('snare_sample_residual.wav');

%% basic variables

fs = 44100;
Tsec = 1; % duration of simulation (Seconds)
Tsamp = Tsec*fs; % duration of simulation (Samples)

%% 2d square mesh (for high freqs)

% NJ        : number of junctions
% a         : lowpass a coefficient
% exc_size  : size of excitation in 
NJ = 12;
exc_size = 20;
exc_pos = 50;
a = 0.15;
decayFactor = 0.99;
y_mesh = f_mesh_square( NJ, decayFactor, a, exc_size, exc_pos, Tsamp, fs );

%% bdwg (for low freqs)

freqs = [193 366 495 646 796]; % fundamental frequency of delay lines (modes) (Hertz)
decay = [0.9999 0.9998 0.9997 0.9996 0.9995]; % decay factors

low_high = [0.75; 1.25]; % low and high freq of BP filter (percentage)

y_bdwg = f_bdwg( freqs, decay, low_high, Tsamp, fs );

%% put everything together

y1 = y_mesh + y_bdwg;
y2 = conv(y1, res);

Spec(y1, fs)
Spec(y2, fs)
soundsc(y2, fs)

