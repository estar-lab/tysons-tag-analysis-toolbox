function   V = d3vedba(recdir,prefix,scf,fc,fs,cues)
%
%     V = d3vedba(recdir,prefix,scf,fc,fs,cues)
%     Calculate the VeDBA activity measure over the entire full bandwidth
%     accelerometer data in a tag deployment. This functions reads
%     the raw data (swv files) hour-by-hour, applies a high-pass filter
%		to each axis, takes the vector magnitude of the output, and computes 
%		the mean of this over successive blocks. The result is a time
%     series of VeDBA sampled at fs Hz. The averaging time 
%     for the mean is 1/fs seconds and there is no overlap between 
%     successive blocks.
%		fc is the high-pass filter cut-off frequency in Hertz. A symmetric
%		 delay-corrected FIR filter is used.
%		fs is the output sampling rate in Hz. Default output sampling rate 
%		 if fs is not given is 5 Hz.
%     Optional argument cues can be used to specify the start cue of
%      processing (if cues is a scalar) or the start and end cue (if a
%      vector).
%
%		Note: This function computes VeDBA over short intervals of 1/fs seconds.
%		To compute VeDBA over longer intervals, sum the output of this function
%		over the required intervals.
% 
%     markjohnson@bios.au.dk
%     last modified: 29/01/22
%		EXPERIMENTAL! THIS FUNCTION IS STILL BEING VALIDATED

if nargin<4,
   help d3vedba
   return
end

if nargin<5 || isempty(fs),
	fs = 5 ;                % output sampling rate, Hz
end

if nargin<6,
   cues = 0 ;
end
LEN = 3600 ;               % analysis block length in secs

% get the sampling frequency
X = d3getswv([0 1],recdir,prefix) ;
if isempty(X), V=[]; return, end

% find the acceleration channels
ch_names = d3channames(X.cn) ;
cc = strfind(ch_names,'ACC') ;
cn = [] ;
for k=1:length(cc),
	if cc{k} == 1,
		cn(end+1) = k ;
	end
end

fsin = X.fs(cn(1)) ;
bl = round(fsin/fs) ; 		% work out the block size
len = (bl*round(LEN*fsin/bl))/fsin ; 	% make sure len is a multiple of bl
nf = 4*fsin/fc ;		% filter length
nf = floor(nf/2)*2 ;   % n must be even for an integer group delay
h = fir1(nf,fc/(fsin/2),'high');	% design filter
h = h-mean(h) ;
noffs = floor(nf/2) ;

cue = cues(1) ;
% read in a little data to prime the filter states
X = d3getswv(cue+[0 max(nf/fsin,1)],recdir,prefix) ;
A = [X.x{cn}] ;
A = repmat(scf(:)',size(A,1),1) ;
[Af,Zf] = filter(h,1,flipud(A(2:floor(nf/2),:))) ;
Z = [] ;
V = [] ;
nin = 0 ;
if size(scf,2)>1,
	if size(scf,1)==1,
		scf = scf' ;
	else
		scf = scf(:,1) ;
	end
end

if length(scf)==1,
	scf = scf*[1;1;1] ;
end

while 1,
   fprintf('Reading at cue %d\n', cue) ;
   try
   	X = d3getswv(cue+[0 len],recdir,prefix) ;
   catch
		fprintf('d3getswv failed\n') ;
      break
   end
	if isempty(X.x), break, end
	A = [X.x{cn}] ;
	nin = nin+size(A,1) ;	% keep count of input samples
	[Af,Zf] = filter(h,1,A.*repmat(scf(:)',size(A,1),1),Zf) ;
   [Y,Z] = buffer([Z;sqrt(sum(Af.^2,2))],bl,0,'nodelay') ;
   n = size(Y,2) ;
   V(end+(1:n)) = nanmean(Y)' ;  % V is at fs
   cue = cue+len ;
   if length(cues)>1,
      if cue>=cues(2), break, end
      len = min(len,cues(2)-cue) ;
   end
end

% get the last samples out of the filter
[Af,Zf] = filter(h,1,A(end-(1:nf),:),Zf) ;
[Y,Z] = buffer([Z;sqrt(sum(Af.^2,2))],bl,0,'nodelay') ;
n = size(Y,2) ;
V(end+(1:n)) = nanmean(Y)' ;  % V is at fs

V = V(:) ;		% make sure V is a column vector
if isempty(V), return, end

% remove filter delay and trim output to correct length
noffs = round(nf/2*fs/fsin) ;
V = V(noffs+(1:floor(nin*fs/fsin))) ;	% remove filter delay

V = sens_struct(V,fs,prefix,'jerk') ;
V.description = 'Vectorial Dynamic Body Acceleration' ;
V.full_name = 'VeDBA' ;
V.name = 'V' ;
V.type = 'acceleration' ;
V.unit = 'm/s2' ;
V.unit_label = 'm/s^2' ;
V.unit_name = 'metres per second squared' ;
V.input_sampling_rate = fsin ;
V.rms_averaging_time = bl/fsin ;
V.cal_poly = [scf zeros(3,1)] ;
V.history = 'd3vedba' ;
if cues(1)~=0,
	V.start_offset = cues(1) ;
	V.start_offset_units = 'seconds' ;
end
return
