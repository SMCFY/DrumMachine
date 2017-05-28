function sigFilt = gene_filtersBC(sig, fs, show)

%   FUNCTION
%       signal filtering through and filter bank corresponding to the 
%       24 critical bands. Uses FIR filters.
%   USE
%       sigFilt = gene_filtersBC(sig, fs, show)
%
%   INPUT
%       sig : signal to filter
%       fs  :
%       show: 'yes' to enable some figures display, nothing or 'no' to disable
%
%   OUTPUT
%      sigFilt: matrix of size (length(sig) X 24) which contains the
%      filtered signals in each band
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENESIS S.A. - 2009 - www.genesis.fr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin < 3, 
    show = 'no';
else
    show = 'yes';
end;

% critical bands bounds (Bark bands cut-off frequencies)
fc = [22 100 200 300 400 510 630 770 920 1080 ...
      1270 1480 1720 2000 2320 2700 3150 3700 4400 5300 ...
      6400 7700 9500 12000 15500];

N = length(sig);

sigFilt = zeros(N, 24);


for i = 1:24,
    
    % critical bands widths (normalized frequencies)

    BandWidth = [fc(i) fc(i+1)] * 2 / fs;
    
    % FIR filtering
    if     23 <= i && i <25,
        Nfir = round(86*fs/48000);
    elseif 20 <= i && i <23,
         Nfir = round(136*fs/48000);
    elseif 18 <= i && i <20,
        Nfir = round(244*fs/48000);
    elseif 13 <= i && i <18,
        Nfir = round(628*fs/48000);
    elseif  6 <= i && i <13,
        Nfir = round(1034*fs/48000);
    elseif 1 <= i && i < 6,
        Nfir = round(2014*fs/48000);
    end;
        
    b = fir1(Nfir-1, BandWidth);

    sigFilt(:, i) = fftfilt(b, sig);
    
 
end;

%% optional figures display

if strcmp(show, 'yes'),
    
    sigFiltEch = 20 * log10(abs(sigFilt) + eps);
    t = (0 : length(sig)-1) / fs;
    
    figure
    
    ymin = -100;
    ymax = 0;

    subplot(611), plot(t, 20 * log10(abs(sig) + eps)); 
        ax = axis; axis([ax(1) ax(2) ymin ymax]);
    subplot(612), plot(t, sigFiltEch(:,24)); ylabel('12000 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(613), plot(t, sigFiltEch(:,21)); ylabel('7000 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(614), plot(t, sigFiltEch(:,19)); ylabel('4500 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(615), plot(t, sigFiltEch(:,3)); ylabel('2100 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(616), plot(t, sigFiltEch(:,1)); ylabel('850 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(616), plot(t, sigFiltEch(:,1)); ylabel('150 Hz');
        axis([ax(1) ax(2) ymin ymax]);

    figure
    
    M = max(max(sigFilt));
    ymin = -(M + 0.1 * M);
    ymax = M + 0.1 * M;
    
    subplot(611), plot(t, sig); 
        ax = axis; %axis([ax(1) ax(2) ymin ymax]);
    subplot(612), plot(t, sigFilt(:,24)); ylabel('12000 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(613), plot(t, sigFilt(:,21)); ylabel('7000 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(614), plot(t, sigFilt(:,19)); ylabel('4500 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(615), plot(t, sigFilt(:,3)); ylabel('2100 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(616), plot(t, sigFilt(:,2)); ylabel('850 Hz');
        axis([ax(1) ax(2) ymin ymax]);
    subplot(616), plot(t, sigFilt(:,1)); ylabel('150 Hz');
        axis([ax(1) ax(2) ymin ymax]);

end;