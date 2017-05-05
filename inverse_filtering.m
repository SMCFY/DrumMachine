%% magnitude spectrum

[x fs] = audioread('/Users/geri/Documents/Uni/SMC8/P8/drum_samples/56469__surfjira__tom2-hard.wav');

fftSize = 1024; % window size
window = x(length(x)-fftSize:length(x)-1)%.*hann(fftSize); % hanning window from the end
% window = [window; zeros(1024,1)]; % zero padded window
Xmag = abs(fft(window)); % magnitude spectrum

w = [0:length(window)-1].*fs/length(window); %frequency in Hertz

subplot(2,1,1);
plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2))); % spectrum in dBs

%% inverse filtering
freq = [86];  % estimated peak frequencies in Hz
bw = [10];        % peak bandwidth estimates in Hz
res = window;
        
r = 0.7;     % zero/pole factor (notch isolation)


for i=1:length(freq)
        
    R = exp( - pi * bw(1,i) / fs);            % pole radius
    z = R * exp(j * 2 * pi * freq(1,i) / fs); % pole itself
    B = [1, -(z + conj(z)), z * conj(z)] % numerator
    A = B .* (r .^ [0 : length(B)-1]);   % denominator
        
    res = filter(B,A,res); % apply inverse filter to get residual
end

resMag = abs(fft(res)); % magnitude spectrum of the residual        
subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(resMag(1:length(resMag)/2)));
        
% time domain
figure();
subplot(2,1,1);
plot(window);
subplot(2,1,2);
plot(res);

soundsc(x,fs);