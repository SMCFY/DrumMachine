%% Analyses (peak picking)

[x fs] = audioread('snare_sample.wav');

fftSize = 1024; % window size
window = x(1:fftSize).*hann(fftSize); % hanning window of the attack
window = [window; zeros(fftSize,1)]; % zero padded signal
Xmag = abs(fft(window)); % magnitude spectrum

w = [0:length(window)-1].*fs/length(window); %frequency in Hertz

figure();
subplot(2,1,1);
plot(window(1:fftSize)); % time domain
title('windowed signal');
subplot(2,1,2);
plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2))); % spectrum in dBs
title('magnitude spectrum');

%% Filtering (cascade of 2nd order IIR notch filters)
freq = [193 366 495 646 796]; % estimated peak frequencies in Hz
for i=1:length(freq)
    theta(i) = 2*pi*freq(1,i)/fs; % peak frequencies in radians/sample
end
bw = [20 50 50 50 50]; % peak bandwidth estimates in Hz
res = x;
        
r = 0.95; % zero/ploe factor

figure();
subplot(2,1,1);
for i=1:length(freq)
        
%     R = exp( - pi * bw(1,i) / fs);            % pole radius
%     z = R * exp(j * 2 * pi * freq(1,i) / fs); % pole itself
%     B = [1, -(z + conj(z)), z * conj(z)] % numerator
%     A = B .* (r .^ [0 : length(B)-1]);   % denominator
    

    b = [1 -2*cos(theta(1,i)) 1];        % filter coefficients
    a = [1 -2*r*cos(theta(1,i)) r^2];    % filter coefficients
        
    res = filter(b,a,res); % apply inverse filter to get residual
    freqz(b,a); hold on;
end
title('cascaded notch filters');

resMag = abs(fft(res)); % magnitude spectrum of the residual  

wRes = [0:length(res)-1].*fs/length(res);

subplot(2,1,2);
plot(wRes(1:length(wRes)/2), 20*log10(resMag(1:length(resMag)/2)));
title('residual spectrum');
%% Resynthesis (modal synthesis with residual excitation)
y = zeros(length(x),1); % output buffer
out = y;

% excitation signal (gwn)
exc = randn(512,1);
exc = exc - mean(exc);
exc = exc / max(exc);
exc  = [exc; zeros(length(x)-length(exc),1)];

%exc = ifft(fft(res).*fft(exc)); % excitation convolved with residual
exc = conv(exc,res);

% processed samples
xn1 = 0; % x[n-1]
xn2 = 0; % x[n-2]

for i=1:length(freq)
    
    R = exp(-pi*bw(1,i)/fs); % pole radius

    for j=1:length(y)
            y(j) = 2*R*cos(theta(1,i))*xn1 - R^2*xn2+exc(j); % two pole resonator
            xn2 = xn1;
            xn1 = y(j);
    end
    out = out + y; % additive synthesis of resonant frequencies
    
end

out = out / max(out); % normalisation


figure();
plot(out);
hold on;
plot(x);
legend('resynth', 'target');

sound(x, fs);
pause(1);
sound(out, fs);