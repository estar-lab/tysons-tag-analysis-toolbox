function   J = d3maxjerk(recdir,prefix,scf,T,cues)
%
%     J = d3maxjerk(recdir,prefix,scf,T,cues)
%     Calculate the max-in-block norm-jerk of the entire full bandwidth
%     accelerometer data in a tag deployment. This functions reads
%     the raw data (swv files) hour-by-hour, computing first the 
%     norm-jerk at the full sensor bandwidth, and then taking the
%     maximum value of this over successive blocks. The result is a time
%     series of max norm-jerk sampled at non-overlapping T second intervals.
%		This is useful for finding thresholds to distinguish different
%		activities. To do this, plot the histogram of log(J).
%
%		scf is the scale factor needed to convert raw accelerometer values into
%		 m/s2. It can be a single number that is applied to all axes or a vector
%		 of three scale factors, one for each axis. scf can also be taken from
%		 an accelerometer calibration tool such as auto_cal_acc and in this case
%		 use: scf = cal.poly.
%     T is the block length of the analysis in seconds. Default value if T
%		 is not given is 10 s.
%     cues optional argument to specify the start cue of
%     processing (if cues is a scalar) or the start and end cue (if a
%     vector).
%
%     markjohnson@bios.au.dk


if nargin<3,
   help d3maxjerk
   return
end

if nargin<4 || isempty(T),
	T = 10 ;                % output block size, s
end

if nargin<5,
   cues = 0 ;
end
LEN = 3600 ;               % nominal read length in secs

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
bl = round(fsin*T) ; 		% work out the block size in samples
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
   	X = d3getswv(cue+[0 len],recdir,prefix) ;
   catch
		fprintf('d3getswv failed\n') ;
      break
   end
	if isempty(X.x), break, end
	A = [X.x{cn}] ;
	jj = njerk(A.*repmat(scf(:)',size(A,1),1),fsin) ;
   [Y,Z] = buffer([Z;jj],bl,0,'nodelay') ;
   n = size(Y,2) ;
   J(end+(1:n)) = max(Y)' ;  % J is at T second intervals
   cue = cue+len ;
   if length(cues)>1,
      if cue>=cues(2), break, end
      len = min(len,cues(2)-cue) ;
   end
end
J = J(:) ;		% make sure J is a column vector
if isempty(J), return, end

J = sens_struct(J,fsin/bl,prefix,'jerk') ;
J.input_sampling_rate = fsin ;
J.block_length = bl/fsin ;
J.block_length_units = 'seconds' ;
J.cal_poly = [scf zeros(3,1)] ;
J.description = 'Maximum norm-jerk in blocks' ;
J.name = 'Jm' ;
J.full_name = 'MaxJerk' ;
J.history = 'd3maxjerk' ;
if cues(1)~=0,
	J.start_offset = cues(1) ;
	J.start_offset_units = 'seconds' ;
end
return
