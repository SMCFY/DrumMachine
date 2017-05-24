function [pxx, f] = Spec( x, fs)

%x = x(t:t+1024);
[pxx,f] = pwelch(x(100:end),[],[],2*fs,fs);
figure
%plot(f(1:fmax), 10*log10(pxx(1:fmax)), 'r') %*fs/2
plot(f, 10*log10(pxx), 'r')
%semilogx(f, 10*log10(pxx), 'r') % plot data as logarithmic scales for the x-axis
%xlim([0 (max(f)+5000)])
grid on
hold on
xlabel('Frequency, Hz')
ylabel('Magnitude, dB')
% set(gca, 'xtick', (10.^(0:5))) % set ticks at 1,2,4,8,...
% set(gca, 'xscale', 'log') % scale x-axis logarithmic
set(gca, 'xtick', [100 500 1000 2000 3000 4000 5000 6000 7000 8000 9000 10000 15000 20000]) 
set(gca, 'xscale', 'linear')
%yL = get(gca,'YLim');
%line([80 80],yL,'Color','b')

end

