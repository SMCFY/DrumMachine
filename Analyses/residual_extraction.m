% residual extraction by inverse filtering, based on mode analyses
excLength = 2^10; % excitation length

filepath = '/Users/geri/Documents/Uni/SMC8/P8/DrumMachine/RecordingSess/Samples/';
[x1 fs] = audioread([filepath, 'Tom_big/tom_big_pos1.aif']); %tom
x2 = audioread([filepath, 'Snare/snare_pos1.aif']); %snare
x3 = audioread([filepath, 'Cymbal/cymbal_pos1.wav']); %cymbal
x4 = audioread([filepath, 'Kick_ass/kick_pos1.wav']); %kick

res = x4...% <------------------------------ change input here
    (1:excLength); 

% mode matrices
load('modes_invFilt.mat');
tom = modes_invFilt.tom;
snare = modes_invFilt.snare;
cymbal = modes_invFilt.cymbal;
kick = modes_invFilt.kick;

for i=1:length(tom) % mode frequencies in radians/sample
    tom(1,i) = 2*pi*tom(1,i)/fs;
    snare(1,i) = 2*pi*snare(1,i)/fs;
    cymbal(1,i) = 2*pi*cymbal(1,i)/fs;
    kick(1,i) = 2*pi*kick(1,i)/fs;
end
%%
R= 0.98;
subplot(2,1,1);
for i=1:length(tom)
        
    %R = exp(-pi*snare(i,2)/fs); % pole radius (calculated from bw)
    b = [1 -2*cos(kick(1,i)) 1];        
    a = [1 -2*R*cos(kick(1,i)) R*R];    
        
    res = filter(b,a,res); % apply inverse filter to get residual
    freqz(b,a); hold on;
end
title('cascaded notch filters');

resMag = abs(fft(res)); % magnitude spectrum of the residual  
w = [0:excLength-1].*fs/excLength; %frequency in Hertz

subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(resMag(1:length(resMag)/2)));
title('residual spectrum');

res = res/max(res);
sound(res, fs)