function Spec( x, fs )

[pxx,f] = pwelch(x,[],[],4*fs,fs);
figure
semilogx(f, 10*log10(pxx), 'r') % plot data as logarithmic scales for the x-axis
xlim([0 (max(f)+5000)])
grid on
hold on
xlabel('Frequency, Hz')
ylabel('Magnitude, dB')
yL = get(gca,'YLim');
line([80 80],yL,'Color','b')

end

