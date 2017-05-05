% clear all; close all

%% variables

fs = 10000; % sampling rate (Hertz)
freqs = [100 200 500]; % fundamental frequency of delay lines (modes) (Hertz)
decay = [0.999 0.998 0.996]; % decay factors
n_modes = length(freqs); % number of modes
d = zeros(1, n_modes); % length of delay lines (Samples)
for i = 1:n_modes
    d(i) = floor(fs/freqs(i));
end
Tsec = 2; % duration of simulation (Seconds)
Tsamp = Tsec*fs; % duration of simulation (Samples)

%% initialization

L = rand(n_modes, max(d)); % initialize delay line

L = L;

% m1=mean(L(1,:)); m2=mean(L(2,:)); m3=mean(L(3,:));
% L(1,:) = L(1,:) - m1; % centerize
% L(2,:) = L(2,:) - m2; % centerize
% L(3,:) = L(3,:) - m3; % centerize
% for i = 1:n_modes
%     L(i,:) = L(i,:) - mean(L(i,:)); % centerize
% end

out = zeros(1, Tsamp); % output
p_out = 3*ones(1,n_modes); % pointers out      (see shift register)
p_out1 = 2*ones(1,n_modes);
p_out2 = 1*ones(1,n_modes);
p_in = 6*ones(1,n_modes); % pointers in
p_in1 = 5*ones(1,n_modes); 
p_in2 = 4*ones(1,n_modes); 

%% bandpass filter coefficients around fundamental

w_low = 0.75; % 75% below f0
w_high = 1.25; % 125% upper f0
for i = 1:n_modes
    [b(i,:),a(i,:)] = butter(1, [w_low w_high]*(freqs(i)/fs*2), 'bandpass'); % (unit of cutoff frequencies in "pi rad/sample")
end
% freqz(b(1,:),a(1,:)) % magnitude and phase response

%% main loop

for i=1:Tsamp
    
    out(i) = 0;
    
    for j = 1:n_modes
        
        out(i) = out(i) + L(j,p_out(j));
        
        % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
        L(j, p_out(j)) = decay(j) * (b(j,1)*L(j, p_in(j)) + b(j,2)*L(j, p_in1(j))...
            + b(j,3)*L(j, p_in2(j)) - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)));
        
        % update and wrap pointers
        if (p_in(j)==d(j))
            p_in(j)=1;
        else
            p_in(j)=p_in(j)+1;
        end
        if (p_in1(j)==d(j))
            p_in1(j)=1;
        else
            p_in1(j)=p_in1(j)+1;
        end
        if (p_in2(j)==d(j))
            p_in2(j)=1;
        else
            p_in2(j)=p_in2(j)+1;
        end
        if (p_out(j)==d(j))
            p_out(j)=1;
        else
            p_out(j)=p_out(j)+1;
        end
        if (p_out1(j)==d(j))
            p_out1(j)=1;
        else
            p_out1(j)=p_out1(j)+1;
        end
        if (p_out2(j)==d(j))
            p_out2(j)=1;
        else
            p_out2(j)=p_out2(j)+1;
        end
        
    end
end

%% sound and plots

soundsc(out, fs)
%figure; 
plot(out/max(out))
Spec(out, fs) % my spectrum function