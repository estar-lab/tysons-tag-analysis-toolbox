function    cl = getclicksr(x,fs,opts)
%
%   cl = getclicksr(x,fs,opts)
%		EXPERIMENTAL
%		General purpose click finder with a fixed threshold set
%		to the noise floor.
%		Unlike rainbow.m, this function is suitable for single channel
%		data.
%		x is an envelope sampled at fs Hz.
%		opts is an optional structure of configuration options. Valid
%		 fields are: blank, rthr, thr.

blank = round(0.001*fs) ;
noiseintvl = 0.001 ;
rthr = 4 ;
thresh = [] ;

if nargin>2,
   if isfield(opts,'blank'), blank = round(fs*opts.blank) ; end
   if isfield(opts,'rthr'), rthr = opts.rthr ; end
   if isfield(opts,'thr'), thresh = opts.thr ; end
end

[X,z]=buffer(x,round(fs*noiseintvl),0,'nodelay');
if isempty(thresh),
	thresh = rthr*mean(median(X));
end
dxx = diff(x>thresh) ;
cc = find(dxx>0)+1 ;

% eliminate detections which do not meet blanking criterion.
% blanking time is calculated after pulse returns below threshold

% first compute raw pulse endings
coff = find(dxx<0)+1 ;    % find where envelope returns below threshold
cend = size(x,1)*ones(length(cc),1) ;
for k=1:length(cc)-1,
   kends = find(coff>cc(k),1) ;
   if ~isempty(kends),
      cend(k) = coff(kends) ;
   end
end

% merge pulses that are within blanking distance
done = length(cc)<2 ;
while ~done,
   kg = find(cc(2:end)-cend(1:end-1)>blank) ;
   done = length(kg) == (length(cc)-1) ;
   cc = cc([1;kg+1]) ;
   cend = cend([kg;end]) ;
end

% find peak level of each detection and adjust start time to the first
% sample with value > 0.5 of peak level.
level = zeros(length(cc),1) ;
for k=1:length(cc),
	xx = x(cc(k):cend(k)) ;
   [level(k),n] = max(xx) ;
	cc(k) = cc(k)-1+find(xx(1:n)>=level(k)/2,1) ;
end

cl = [cc*(1/fs) level] ;
	