% Main program for BDWGM + residuals

%% load residuals, modes and mode bandwidth

[res, fs] = audioread('tom_res.wav'); % r = 0.98
%[res2, fs] = audioread('tom_big_res_bw.wav'); % variable r, depending on bandwidth
load('modes_10k.mat');
tom = modes_10k.tom;
[tomOriginal, fs] = audioread('tom_big_pos1.aif');
tomOriginal = tomOriginal';

% res=filter(b,a,res);

%% basic variables

fs = 44100;
Tsec = 1; % duration of simulation (Seconds)
%Tsamp = Tsec*fs; % duration of simulation (Samples)
Tsamp = length(tomOriginal);

%% 2d square mesh (for high freqs)

% NJ        : number of junctions
% a         : lowpass a coefficient
% exc_size  : size of excitation in 
NJ = 12;
exc_size = 20;
exc_pos = 50;
a = 0.15;
decayFactor = 0.999;
%y_mesh = f_mesh_square( NJ, decayFactor, a, exc_size, exc_pos, Tsamp, fs );

%% bdwg (for low freqs)

freqs = tom(1,:); % fundamental frequency of delay lines (modes) (Hertz)
B = tom(2,:)';
decay = tom(3,:);
damp = 0.9999;

%decay = ones(1, length(decay)); 

low_high = [0.999;1.001]; % low and high freq of BP filter (percentage)

y_bdwg = f_bdwg( freqs, decay, Tsamp, fs, low_high, damp );

%% put everything together

%y1 = y_mesh + y_bdwg;
y1 = y_bdwg;
y2 = conv(y1, res);

plot(tomOriginal/max(tomOriginal))
hold on
plot(y2/max(y2))

%Spec(y1, fs)
[pxx, f]=Spec(y2, fs);
soundsc(y2, fs)

