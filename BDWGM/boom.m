% Main program for BDWGM + residuals

%% load residuals, modes and mode bandwidth

[res, fs] = audioread('snare_res.wav'); % r = 0.98
%[res2, fs] = audioread('tom_big_res_bw.wav'); % variable r, depending on bandwidth
%load('modes_10k.mat');
snare = modes_10k.snare;
[snareOriginal, fs] = audioread('snare_pos1.aif');
snareOriginal = snareOriginal';

% res=filter(b,a,res);

%% basic variables

fs = 44100;
Tsec = 1; % duration of simulation (Seconds)
%Tsamp = Tsec*fs; % duration of simulation (Samples)
Tsamp = round(length(snareOriginal));

%% 2d square mesh (for high freqs)

% NJ        : number of junctions
% a         : lowpass a coefficient
% exc_size  : size of excitation in 
NJ = 10;
exc_size = 20;
exc_pos = 50;
a = -0.0001;
decayFactor = 0.99999;
y_mesh = f_mesh_square( NJ, decayFactor, a, exc_size, exc_pos, 44100, fs );

%% bdwg (for low freqs)

freqs = snare(1,:); % fundamental frequency of delay lines (modes) (Hertz)
B = snare(2,:)';
decay = snare(3,:);
damp = 0.0009;

%decay = ones(1, length(decay)); 

low_high = [0.999;1.001]; % low and high freq of BP filter (percentage)

y_bdwg = f_bdwg( freqs, B, decay, Tsamp, fs, low_high, damp );

%% put everything together

y1 = [y_mesh zeros(1,length(y_bdwg)-length(y_mesh))] + y_bdwg;
%y1 = y_bdwg;
y2 = conv(y1, res);

y2=ifft(fft(y1) .* fft([res; zeros(length(y1)-length(res),1)]'));

%Spec(y1, fs)
soundsc(y2, fs)

% plot(tomOriginal/max(tomOriginal))
% %plot(y_bdwg)
% hold on
% plot(y2/max(y2))

[pxx, f] = Spec(y2,fs,'r');
hold on
%[pxx,f] = Spec(conv(y_bdwg,res),fs, 'b');
[pxx,f] = Spec(snareOriginal,fs, 'k');

%[pxx,f] = Spec(ifft(fft(y_bdwg) .* fft([res; zeros(length(y_bdwg)-length(res),1)]')),fs);
