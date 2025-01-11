function   J = d3rmsjerk(recdir,prefix,scf,fs,cues)
%
%     J = d3rmsjerk(recdir,prefix,scf,fs,cues)
%     Calculate the RMS norm-jerk of the entire full bandwidth
%     accelerometer data in a tag deployment. This functions reads
%     the raw data (swv files) hour-by-hour, computing first the 
%     norm-jerk at the full sensor bandwidth, and then taking the
%     RMS of this over successive blocks. The result is a time
%     series of RMS norm-jerk sampled at fs Hz. The averaging time 
%     for the RMS is 2/fs seconds and there is a 50% overlap between 
%     successive blocks.
%     Default output sampling rate if fs is not given is 5 Hz.
%     Optional argument cues can be used to specify the start cue of
%     processing (if cues is a scalar) or the start and end cue (if a
%     vector).
%
%     markjohnson@bios.au.dk
%     last modified: 25/04/21 fixed bug in the end condition that had
%        resulted in longer outputs than requested when cues were specified.


if nargin<3,
   help d3rmsjerk
   return
end

if nargin<4 || isempty(fs),
	fs = 5 ;                % output sampling rate, Hz
end

if nargin<5,
   cues = 0 ;
end
LEN = 3600 ;               % analysis block length in secs

% get the sampling frequency
X = d3getswv([0 1],recdir,prefix) ;

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
bl = 2*round(fsin/fs) ; 		% work out the block size
ovl = round(bl-fsin/fs) ;
len = (bl*round(LEN*fsin/bl))/fsin ; 	% make sure len is a multiple of bl
cue = cues(1) ;
Z = [] ;
J = [] ;
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
   	X = d3getswv(cue+[0 len+(bl-ovl)/fsin],recdir,prefix) ;
   catch
		fprintf('d3getswv failed\n') ;
      break
   end
	if isempty(X.x), break, end
	A = [X.x{cn}] ;
	jj = njerk(A.*repmat(scf(:)',size(A,1),1),fsin) ;
   [Y,Z] = buffer([Z;jj],bl,ovl,'nodelay') ;
   n = size(Y,2) ;
   J(end+(1:n)) = sqrt(nanmean(Y.^2))' ;  % J is at fs
   cue = cue+len ;
   if length(cues)>1,
      if cue>=cues(2), break, end
      len = min(len,cues(2)-cue) ;
   end
end
J = J(:) ;		% make sure J is a column vector
if isempty(J), return, end

if length(cues)==1,
   J(end+1) = J(end) ;  % add one measurement to equalize length of other sensors
end

J = sens_struct(J,fs,prefix,'jerk') ;
J.input_sampling_rate = fsin ;
J.rms_averaging_time = bl/fsin ;
J.cal_poly = [scf zeros(3,1)] ;
J.history = 'd3rmsjerk' ;
if cues(1)~=0,
	J.start_offset = cues(1) ;
	J.start_offset_units = 'seconds' ;
end
return
