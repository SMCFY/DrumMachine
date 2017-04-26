
clear all
Fs = 10000;
p = [70 35 14]; %length of delay lines
tmax = 2;
freq = Fs./p; %fundamental of the delay lines
n = length(p);
%initial shift register contents
%filter to soften onset a bit
sr = 2*(rand(n,max(p))-0.5); 
 [bb, aa] = butter(2,.5);
 for j=1:n
     sr(j,:) = filter(bb,aa,sr(j,:));
 end

out = zeros(1,Fs*tmax);
ptrout = 3*ones(1,n) ; %pointer to sr
ptrout1 = 2*ones(1,n);
ptrout2 = 1*ones(1,n);
ptrin = 6*ones(1,n); %pointer to sr
ptrin1 = 5*ones(1,n); 
ptrin2 = 4*ones(1,n); 
DKfactor = [.998 .997 .997]; %decay factor 0.90<factor<1.0
mixfactor = [.5 .3 .2];

%set up the bandpass filter for the main loop
%ths bandpass has to match the frequency implied
%by Fs/p
for j=1:n
    [b(j,:),a(j,:)] = butter(1,[.25 3]*(freq(j)/(Fs/2)),'bandpass');
end

for i=2:Fs*tmax
    out(i)=0;
    for j=1:n
        out(i) = out(i) + mixfactor(j)*sr(j,ptrout(j));
    end
    for j=1:n
        %do the filter operation to set the timber
        sr(j,ptrout(j)) = DKfactor(j)*...
            (sr(j,ptrin(j))*b(j,1)+sr(j,ptrin1(j))*b(j,2)+sr(j,ptrin2(j))*b(j,3) ...
            -sr(j,ptrout1(j))*a(j,2)-sr(j,ptrout2(j))*a(j,3)) ;

        %update and wrap pointers
        if (ptrin(j)==p(j)) ptrin(j)=1;
        else ptrin(j)=ptrin(j)+1;
        end
        if (ptrin1(j)==p(j)) ptrin1(j)=1;
        else ptrin1(j)=ptrin1(j)+1;
        end
        if (ptrin2(j)==p(j)) ptrin2(j)=1;
        else ptrin2(j)=ptrin2(j)+1;
        end
        if (ptrout(j)==p(j))
            ptrout(j)=1; 
            %the mode-mixing term
            sr(j,ptrout(j)) = 0.25*out(i)+0.75*sr(j,ptrout(j));
        else ptrout(j)=ptrout(j)+1;
        end
        if (ptrout1(j)==p(j))ptrout1(j)=1;
        else ptrout1(j)=ptrout1(j)+1;
        end
        if (ptrout2(j)==p(j))ptrout2(j)=1;
        else ptrout2(j)=ptrout2(j)+1;
        end
    end
end

sound(out/max(out),Fs)
plot (out/max(out))