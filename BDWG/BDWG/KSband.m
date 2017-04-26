
% variables

Fs = 44100;
p = 2000; % length of delay line
tmax = 1;
freq = Fs/p; % fundamental of the delay line

%initial shift register contents
%filter to soften onset a bit
sr = rand(1,p);
[b,a] = butter(2,.5);
sr = filter(b,a,sr);

out = zeros(1,Fs*tmax);
ptrout = 3; %pointer to sr
ptrout1 = 2;
ptrout2 = 1;
ptrin = 6; %pointer to sr
ptrin1 = 5; 
ptrin2 = 4; 
factor = .9999; %decay factor 0.90<factor<1.0

%set up the bandpass filter for the main loop
%the bandpass has to match the frequency implied
%by Fs/p
[b,a] = butter(1,[.75 1.25]*(freq/(Fs/2)),'bandpass');

for i=1:Fs*tmax
        out(i) = sr(ptrout);
    %do the filter operation to set the timber
    sr(ptrout) = factor*(sr(ptrin)*b(1)+sr(ptrin1)*b(2)+sr(ptrin2)*b(3) ...
        -sr(ptrout1)*a(2)-sr(ptrout2)*a(3));
    
    %update and wrap pointers
    if (ptrin==p) ptrin=1;
    else ptrin=ptrin+1;
    end
    if (ptrin1==p) ptrin1=1;
    else ptrin1=ptrin1+1;
    end
    if (ptrin2==p) ptrin2=1;
    else ptrin2=ptrin2+1;
    end
    if (ptrout==p)ptrout=1;
    else ptrout=ptrout+1;
    end
    if (ptrout1==p)ptrout1=1;
    else ptrout1=ptrout1+1;
    end
    if (ptrout2==p)ptrout2=1;
    else ptrout2=ptrout2+1;
    end
end

sound(out/max(out),Fs)
plot (out/max(out))