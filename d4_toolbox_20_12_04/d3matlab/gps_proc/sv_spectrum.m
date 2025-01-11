function    G = sv_spectrum(sv,CF,noresamp)
% 
%    G = sv_spectrum(sv,CF,noresamp)
%		Compute the complex spectra of GPS satellite codes.
%		The spectra are over-sampled and interpolated to a
%		power-of-2 length to match the GPS processing in fast_fdoppx.
%
%		Inputs:
%		sv  GPS satellite number 1..32.
%		CF  Over-sampling ratio, a positive integer.
%		noresamp  prevents 1023-to-1024 interpolation if equal to 1.
%			 Default is to perform the interpolation.
%
%		Last updated:
%		10 April 2021 - modified for compatibility with Octave

if nargin<2,
	CF = 2 ;
end
	
if nargin<1 || isempty(sv)
   sv = 1:32 ;
end

if nargin<3,
	noresamp = 0 ;
end
	
if noresamp==0
	Nfft = 1024*CF ;
else
	Nfft = 1023*CF ;
end
G = zeros(Nfft,length(sv)) ;
n = 5 ;     % use 8 to match interp() but lower values seem to work better
h = 2*fir1(n*2,0.5)' ;

for k=1:length(sv),
   % was this:
   %g = interp(2*ca_code(sv(k))-1,CF);      % interpolate C/A code by factor of CF

   % changed to this for compatibility with Octave
   cc = 2*ca_code(sv(k))-1 ;
   c2 = reshape([cc';zeros(CF-1,length(cc))],[],1);
   ch = filter(h,1,[c2(end+(-n+1:0));c2;c2(1:n)]) ;
   g = ch(length(h)-1+(1:length(c2))) ;
   %g = reshape(repmat(2*ca_code(sv)-1,1,CF)',[],1); % faster but lower quality interpolation method
	if noresamp==0,
      % was this:
		%g = resample(g,1024,1023);				% use this method unless speed is really important
      % changed to this to improve start and end conditions
      g = resample([g(end+(-49:0));g;g(1:50)],1024,1023);				% use this method unless speed is really important
      g = g(50+(1:CF*1024)) ;
      %g = [g(1:1023);0;g(1024:end);0] ;	% faster but lower quality interpolation method
	end
   G(:,k) = conj(fft(g,Nfft)) ;
end
