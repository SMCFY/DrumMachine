function out = Comb( in, f, d, N )
% Lowpass feedback comb filter (LBCF)
% INPUT
% in  : input signal
% f   : feedback (lowpass scale factor)
% d   : damping
% N   : order of the filter
% OUTPUT
% out : filtered signal

b = [zeros(1,N) 1 -d];
% b = 1;
a = [1 -d zeros(1, N-2) (f*d-f)];
out = filter(b, a, in);

freqz(b,a)

%h = dsp.IIRFilter('Numerator',b,'Denominator',a);

%out = step(h,in);

% freqz(h)

end

