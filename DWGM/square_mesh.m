% Square mesh based on STK
% Square Junctions
% No animation

%% Variables and initialization

fs = 44100; % sampling frequency

Tsec = 0.6; % duration of simulation (Seconds)
Tsamp = Tsec*fs; % duration of simulation (Samples)
%Tsamp = round(length(cymOriginal)/2);

NJ = 6; % number of junctions

% initialize calculation matrices

vE = zeros(NJ, NJ); % east velocity wave
vW = zeros(NJ, NJ); % west velocity wave
vN = zeros(NJ, NJ); % north velocity wave
vS = zeros(NJ, NJ); % south velocity wave

% alternating matrix (matrix for first step, it will contain the excitation)

vE1 = zeros(NJ, NJ); % east velocity wave
vW1 = zeros(NJ, NJ); % west velocity wave
vN1 = zeros(NJ, NJ); % north velocity wave
vS1 = zeros(NJ, NJ); % south velocity wave

v = zeros(NJ-1, NJ-1); % junctions' velocity

y = zeros(1, Tsamp); % output

% reflexion

r_coeff = -1; % reflexion coefficient (-1 for perfect inverse phase reflection)
decayFactor = 0.999; 
a = 0.001;
b = 1 - abs(a);

% b = [0.5 0.5];
% a = 1;


%% Excitation parameters

% excitation position and size

excite_size = ceil(NJ/5); % excitation size
excite_pos = ceil(NJ/2); % excitation centrale position (gravity center of the strike)
% exite_pos = round((NJ-exite_size)/2); % center position (middle-10%)

% excitation shape and velocity

excite_temp = zeros(NJ-1, 1); % temporary excitation vector
% fill values around excitation point with a sine shape
excite_temp(excite_pos-round(excite_size/2):excite_pos-round(excite_size/2)+excite_size-1)...
    = 0.25*sin(pi*[0:excite_size-1]/(excite_size)); % 0.25 is the amplitude, thus the strike force!
% transpose to make it an area (vector becomes a matrix)
excite = excite_temp*transpose(excite_temp); % excitation!
% excite mesh with our sine excitation signal -> fill the alternating matrix
vW1(1:NJ-1, 1:NJ-1) = excite;
vN1(1:NJ-1, 1:NJ-1) = excite;
vE1(1:NJ-1, 2:NJ) = excite;
vS1(2:NJ, 1:NJ-1) = excite;

%% Main loop

% update junctions' velocitiy with excitation signal
v = 0.5 * (vW1(1:NJ-1,1:NJ-1) + vE1(1:NJ-1,2:NJ) + vN1(1:NJ-1,1:NJ-1) + vS1(2:NJ,1:NJ-1));

for i = 1:Tsamp
    
    if (mod(i,2) == 0) % clock 0 (even)
        
        % Velocities
        v = 0.5 * (vW(1:NJ-1,1:NJ-1) + vE(1:NJ-1,2:NJ) + vN(1:NJ-1,1:NJ-1) + vS(2:NJ,1:NJ-1));
        
        % v^+ = v_j - v^-
        vW1(1:NJ-1,2:NJ)   = v - vE(1:NJ-1,2:NJ);
        vN1(2:NJ,1:NJ-1)   = v - vS(2:NJ,1:NJ-1);
        vE1(1:NJ-1,1:NJ-1) = v - vW(1:NJ-1,1:NJ-1);
        vS1(1:NJ-1,1:NJ-1) = v - vN(1:NJ-1,1:NJ-1);
        
        % Boundaries
        vW1(1:NJ-1,1)  = decayFactor * filter(b, [1 a],   vE(1:NJ-1,1));
        vE1(1:NJ-1,NJ) = decayFactor * filter(b, [1 a],   vW(1:NJ-1,NJ));
        vN1(1,1:NJ-1)  = decayFactor * filter(b, [1 a],   vS(1,1:NJ-1));
        vS1(NJ,1:NJ-1) = decayFactor * filter(b, [1 a],   vN(NJ,1:NJ-1));
        
    else               % clock 1 (odd)
        
        % Velocities
        v = 0.5 * (vW1(1:NJ-1,1:NJ-1) + vE1(1:NJ-1,2:NJ) + vN1(1:NJ-1,1:NJ-1) + vS1(2:NJ,1:NJ-1));
        
        % v^+ = v_j - v^-
        vW(1:NJ-1,2:NJ)   = v - vE1(1:NJ-1,2:NJ);
        vN(2:NJ,1:NJ-1)   = v - vS1(2:NJ,1:NJ-1);
        vE(1:NJ-1,1:NJ-1) = v - vW1(1:NJ-1,1:NJ-1);
        vS(1:NJ-1,1:NJ-1) = v - vN1(1:NJ-1,1:NJ-1);
%         
        % Boundaries
        vW(1:NJ-1,1)  = decayFactor * filter(b, [1 a],   vE1(1:NJ-1,1));
        vE(1:NJ-1,NJ) = decayFactor * filter(b, [1 a],   vW1(1:NJ-1,NJ));
        vN(1,1:NJ-1)  = decayFactor * filter(b, [1 a],   vS1(1,1:NJ-1));
        vS(NJ,1:NJ-1) = decayFactor * filter(b, [1 a],   vN1(NJ,1:NJ-1));
        
    end
    
    % sound output pick up location
    y(i) = v(NJ-1,NJ-1);
end

y=y/max(y);

soundsc(y,fs)
plot(y)

%[res, fsres]=audioread('snare_sample_residual.wav');

%% 
% y = y';
% fftSize = 1024; % window size
% startfft = 1;
% window = y(startfft:end).*hamming(length(y(startfft:end))); % hamming window of the attack
% window = [window; zeros(2^15,1)]; % zero padded signal (higher DFT resolution)
% Xmag = abs(fft(window)); % magnitude spectrum
% 
% w = [0:length(window)-1].*fs/length(window); %frequency in Hertz
% 
% figure
% % subplot(2,1,1);
% % plot(window); % time domain
% % title('windowed signal');
% % subplot(2,1,2);
% plot(w(1:length(w)/2), 20*log10(Xmag(1:length(Xmag)/2))); % db spectrum
% title('magnitude spectrum');



