%% STFT
winS = 1024;
hopS = winS/2;

frnop=floor(l1/hopS-1);
for i=1:frnop
    fr=x1((i-1)*hopS+(1:winS)).*hamming(winS);
    mX(:,i)=abs(fft(fr))';
end
mX=mX(1:100,:);
imagesc(mX)
 