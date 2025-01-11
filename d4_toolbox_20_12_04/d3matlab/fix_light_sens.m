function    L = fix_light_sens(L)

%     L = fix_light_sens(L)
%     Reduce sampling interference in the Hamamatsu light
%     sensor channel in 2017-era DTAG sound+light tags.
%     L is the raw sensor data for the light channel at
%     the original 50 Hz sampling rate.
%     L should span more than 10s of data.

INTVL = 101 ;     % light interference cycle length in samples at 50 Hz
kc = find(L>0.99) ;
L(kc) = NaN ;
[Lb,z]=buffer(L,INTVL,0,'nodelay');
Lp=nanmedian(Lb,2);
nbl = size(Lb,2) ;
L = L-[repmat(Lp,nbl,1);Lp(1:length(L)-nbl*INTVL)] ;
L = median_filter(abs(L),3) ;
L(kc) = 1-median(Lp) ;
