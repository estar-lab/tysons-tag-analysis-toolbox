function    R = gps_incoherent(b,df,SV,dop)

%    R = gps_incoherent(b,df,sv,dop)
%		Improve GPS pseudo-range estimates. This function performs a fine 
%		delay search for a GPS grab in which coarse peaks have already
%		been found. This function is called by d3refinegps and should not be used
%		by itself.
%
%		markjohnson@bios.au.dk
%		last modified: 1 april 2021		


CF = max(round(16/df),2) ;	% oversampling rate
FS = 1023e3*CF ;           % base-band sampling rate
Nfft = 1023*CF ;           % FFT size to use
NC = 1 ;

G = sv_spectrum([],CF,1) ;
wds = 2*pi*dop/FS ;
R = zeros(length(SV),4) ;

for k=1:length(SV),
	[B,z] = buffer(b.*exp(j*(0:length(b)-1)'*wds(k)),Nfft,0,'nodelay') ;
	SS = fft(B,Nfft) ;
	XX = ifft(SS.*repmat(G(:,SV(k)),1,size(SS,2)),Nfft) ;
	X2 = abs(XX).^2 ;
	XI = mean(X2,2) ;
	[m n] = max(XI) ;
	kp = mod(n+(-NC:NC)-1,Nfft)+1 ;
	kn = mod([1:n-1 n+1:Nfft]-1,Nfft)+1 ;
	nf = mean(XI(kn)) ;
	Xpk = sqrt(XI(kp)) ;
	ppl = polyfit(-NC:NC,log(Xpk)',2) ;
	rdel = n-ppl(2)/2/ppl(1) ;
	df = size(B,2)*2 ;      % degrees of freedom of the chi-sq distribution
	R(k,:) = [SV(k) m*df/nf-df nf mod(rdel*1023/Nfft,1023)] ;
end
