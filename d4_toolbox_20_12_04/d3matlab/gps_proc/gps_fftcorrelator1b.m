function    [DEL,DOP,STATS,X] = gps_fftcorrelator1b(b,SV,Fmax)
%
%    [DEL,DOP,STATS,X] = gps_fftcorrelator1b(b,SV,Fmax)
%		Process a GPS snapshot to pseudo-ranges using an exhaustive
%		delay-doppler search and incoherent averaging.
%
%		Inputs:
%		b is the unpacked time series of the capture at a nominal 
%		  sampling rate of 16.368 MHz. b must contain at least 2046 samples
%		  (i.e., a minimum capture duration of 1ms).
%		SV is a list of satellites to search for. If SV is not given,
%		  all 32 satellites are searched.
%		Fmax is the maximum Doppler shift to search over, in Hz. The search is
%		  symmetrical from -Fmax to Fmax.
%
%		Last updated:
%		1 April 2021 - added improved interpolation and doppler shift method


DEL=[];DOP=[];STATS=[];X=[];

if nargin<2 || isempty(SV),
   SV = 1:32 ;
end

if nargin<3,
   Fmax = 8e3 ;
end

if length(b)<2046,
   return
end

CF = 2 ;
FC = 1575.42e6 ;           % GPS L1 carrier frequency
FS = 1023e3*CF ;           % base-band sampling rate
wd = -2*pi*Fmax/FS ;       % starting doppler is -Fmax
Nfft = 2048 ;              % FFT size to use
nd = ceil(2*Fmax/1000) ;   % number of dopplers to test per pass
ndinc = 2 ;                % number of doppler tests per 1 kHz (use 2 or 3)

FD = -Fmax:1000/ndinc:Fmax;
FD = FD(1:nd*ndinc);
wds = 2*pi*FD/FS ;

G = sv_spectrum(SV) ;
b = resample(b,1024,1023);

DEL = zeros(length(SV),1) ;
DOP = zeros(length(SV),1) ;
STATS = zeros(length(SV),5) ;

for ksv=1:length(SV),
   X = zeros(Nfft,length(wds)) ;
   for kk=1:length(wds),
		[B,z] = buffer(b.*exp(-j*(0:length(b)-1)'*wds(kk)),Nfft,0,'nodelay') ;
      SS = fft(B,Nfft) ;
      XX = ifft(SS.*repmat(G(:,ksv),1,size(SS,2)),Nfft) ;
      X(:,kk) = mean(abs(XX).^2,2) ;	% incoherent average
   end
	%[m n]=max(max(X));
	%[ksv wds(n)]
   [DEL(ksv),DOP(ksv),STATS(ksv,:)] = gpsperf(X,SV(ksv),size(SS,2),-FD,0.001,0) ;
end
