function out = f_bdwg( freqs, decay, Tsamp, fs, low_high, damp )
% Banded digital waveguide function

%% variables

n_modes = length(freqs); % number of modes
d = zeros(1, n_modes); % length of delay lines (Samples)
for i = 1:n_modes
    d(i) = floor(fs/freqs(i));
end

%% initialization

L = rand(1, max(d)); % initialize delay lines with white noise
L = L - mean(L);
L = L/max(L);
% L = repmat(L,n_modes,1);

%% filter coefficients

f_low_high = low_high*freqs;
B = f_low_high(2,:) - f_low_high(1,:); % bandwidth
% B = B';
B_rad = 2*pi/fs .* B; % bandwidth in radians/samp
psi = 2*pi/fs * freqs; % center frequencies in radians/samp
R = 1 - B_rad/2;
cosT = 2*R/(1+R.^2) * cos(psi);
A0 = (1-R.^2)/2; % normalization scale factor or gain adjustement

% a = zeros(n_modes, 3);
% b = zeros(n_modes, 3);
for i = 1:n_modes
    b = [zeros(1,d), A0(i), 0, -A0(i)]; % b coeff dependent of scaling gain factor
    a = [1, -2*R(i)*cosT(i), R(i)^2]; % a coeff depending on R and cosT     
    out(i,:) = filter(b,a,L)
end





end

