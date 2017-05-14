% residual extraction by inverse filtering, based on mode analyses
excLength = 2048; % excitation length

[tom_x fs] = audioread('/Users/geri/Documents/Uni/SMC8/P8/DrumMachine/RecordingSess/Cropped_Samples/Tom_big/tom_big_pos1.aif');
tom_res = tom_x(1:excLength);

% mode matrices
modes = load('modes.mat');
tom_big = modes.tom_big;
%snare = modes.snare;

for i=1:length(tom_big)
    tom_big(i,1) = 2*pi*tom_big(i,1)/fs; % mode frequencies in radians/sample
    %snare(i,1) = 2*pi*snare(i,1)/fs; % mode frequencies in radians/sample
end


R = 0.98; % pole radius

subplot(2,1,1);
for i=1:length(tom_big)
        
    b = [1 -2*cos(tom_big(i,1)) 1];        
    a = [1 -2*R*cos(tom_big(i,1)) R^2];    
        git
    tom_res = filter(b,a,tom_res); % apply inverse filter to get residual
    freqz(b,a); hold on;
end
title('cascaded notch filters');

resMag = abs(fft(tom_res)); % magnitude spectrum of the residual  
w = [0:excLength-1].*fs/excLength; %frequency in Hertz

subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(resMag(1:length(resMag)/2)));
title('residual spectrum');