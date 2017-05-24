% Main program for BDWGM + residuals

%% load residuals, modes and mode bandwidth

[res, fs] = audioread('snare_res.wav'); % r = 0.98
%[res2, fs] = audioread('tom_big_res_bw.wav'); % variable r, depending on bandwidth
%load('modes_10k.mat');
kick = modes_10k.kick;
[snareOriginal, fs] = audioread('snare_pos1.aif');
snareOriginal = snareOriginal';

% res=filter(b,a,res);

%% basic variables

fs = 44100;
Tsec = 1; % duration of simulation (Seconds)
%Tsamp = Tsec*fs; % duration of simulation (Samples)
Tsamp = length(snareOriginal);

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

freqs = kick(1,:); % fundamental frequency of delay lines (modes) (Hertz)
B = kick(2,:)';
decay = kick(3,:);

%decay = ones(1, length(decay)); 

low_high = [0.999;1.001]; % low and high freq of BP filter (percentage)

y_bdwg = f_bdwg( freqs, B, decay, Tsamp, fs, low_high, res );

%% put everything together

%y1 = y_mesh + y_bdwg;
y1 = y_bdwg;
y2 = conv(y1, res);

plot(snareOriginal/max(snareOriginal))
hold on
plot(y2/max(y2))

%Spec(y1, fs)
[pxx, f]=Spec(y2, fs);
soundsc(y2, fs)

