function   L = d3maxlight(recdir,prefix,fs,doclean)
%
%     L = d3maxlight(recdir,prefix,fs,doclean)
%     Calculate the RMS norm-jerk of the entire full bandwidth
%     accelerometer data in a tag deployment. This functions reads
%     the raw data (swv files) hour-by-hour, computing first the 
%     norm-jerk at the full sensor bandwidth, and then taking the
%     RMS of this over successive blocks. The result is a time
%     series of RMS norm-jerk sampled at fs Hz. The averaging time 
%     for the RMS is 2/fs seconds and there is a 50% overlap between 
%     successive blocks.
%     Default output sampling rate if fs is not given is 5 Hz.
%
%     markjohnson@st-andrews.ac.uk
%     2 march 2018

if nargin<2,
   help d3maxlight
   return
end

if nargin<3,
	fs = 5 ;                % output sampling rate, Hz
end

if nargin<4,
	doclean = 0 ;           % default is to not clean raw data
end
	
LEN = 3600 ;               % analysis block length in secs
									
% get the sampling frequency
X = d3getswv([0 1],recdir,prefix) ;

% find the acceleration channels
ch_names = d3channames(X.cn) ;
cc = strfind(ch_names,'EXTIN') ;
cn = [] ;
for k=1:length(cc),
	if cc{k} == 1,
		cn(end+1) = k ;
	end
end
cn = cn(1) ;

L = [] ;
fsin = X.fs(cn) ;
if rem(fsin/fs,1)~=0,
	fprintf(' Output fs must be an integer divisor of raw sampling rate (%f Hz)\n',fsin) ;
	L = [] ;
	return
end

bl = round(fsin/fs) ; 		% work out the block size
nsamps = bl*round(LEN*fsin/bl) ;
len = nsamps/fsin ; 			% make sure len is a multiple of bl
lenreq = len+bl/fsin ;
cue = 0 ;
Z = [] ;

while 1,
   fprintf('Reading at cue %d\n', cue) ;
	X = d3getswv(cue+[0 lenreq],recdir,prefix) ;
	if isempty(X.x), break, end
	ll = [X.x{cn}] ;
	if doclean,
	   ll = fix_light_sens(l) ;
	end
	if length(ll)>nsamps,
		ll = ll(1:nsamps) ;
	end
   Y = buffer(ll,bl,0,'nodelay') ;
   n = size(Y,2) ;
   L(end+(1:n)) = max(Y)' ;  % L is at fs
   cue = cue+len ;
end

L = L(:) ;		% make sure J is a column vector
L(end+1) = L(end) ;     % add one measurement to equalize length of other sensors
L = sens_struct(L,fs,prefix,'light') ;
L.input_sampling_rate = fsin ;
L.max_block_time = bl/fsin ;
L.history = 'd3maxlight' ;
return
