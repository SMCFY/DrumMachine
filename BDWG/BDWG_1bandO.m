% clear all; close all

%% variables

fs = 44100; % sampling rate (Hertz)
f0 = 400; % fundamental frequency of delay line (Hertz)
d = floor(fs/f0); % length of delay line (Samples)
Tsec = 2; % duration of simulation (Seconds)
Tsamp = Tsec*fs; % duration of simulation (Samples)
decay = 0.999; % decay factor

%% initialization

L = 2*rand(1,d); % initialize delay line
L = L - mean(L); % centerize

[x, fs] = audioread('tom_big_res_bw.wav');
x=x/max(x);
%x = [x' zeros(1,length(out)-length(x)+2)];
L = x;

out = zeros(1, Tsamp); % output
p_out = 3; % pointers out      (see shift register)
p_out1 = 2;
p_out2 = 1;
p_in = 6; % pointers in
p_in1 = 5; 
p_in2 = 4; 

%% bandpass filter coefficients around fundamental

w_low = 0.75; % 75% below f0
w_high = 1.25; % 125% upper f0
[b,a] = butter(1, [w_low w_high]*(f0/fs*2), 'bandpass'); % (unit of cutoff frequencies in "pi rad/sample")
freqz(b,a) % magnitude and phase response

%% main loop

for i=1:Tsamp
    %out(i) = L(p_out);
    
    % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
    L(p_out) = decay * (b(1)*L(p_in) + b(2)*L(p_in1) + b(3)*L(p_in2) - a(2)*L(p_out1) - a(3)*L(p_out2));
    
    out(i) = L(p_out);
    
    % update and wrap pointers
    if (p_in==d) 
        p_in=1; 
    else
        p_in=p_in+1;
    end
    if (p_in1==d) 
        p_in1=1; 
    else
        p_in1=p_in1+1; 
    end
    if (p_in2==d) 
        p_in2=1; 
    else
        p_in2=p_in2+1;
    end
    if (p_out==d) 
        p_out=1; 
    else
        p_out=p_out+1; 
    end
    if (p_out1==d) 
        p_out1=1; 
    else
        p_out1=p_out1+1; 
    end
    if (p_out2==d) 
        p_out2=1; 
    else
        p_out2=p_out2+1; 
    end
end

%% sound and plots

soundsc(out, fs)
plot(out/max(out))
Spec(out, fs, 10000) % my spectrum function
