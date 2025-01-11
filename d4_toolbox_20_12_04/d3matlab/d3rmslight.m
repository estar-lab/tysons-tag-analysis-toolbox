function   L = d3rmslight(recdir,prefix,fs,cues,NR)
%
%     L = d3rmslight(recdir,prefix,fs,cues,NR)
%     Perform noise cancellation and decimation on the light sensor
%     data for an entire full bandwidth tag deployment. This functions
%     reads the raw data (swv files) hour-by-hour and then decimates to
%     the requested output rate by taking the rms over blocks of 2/fs samples.
%     Default output sampling rate if fs is not given is 5 Hz.
%     Optional argument cues can be used to specify the start cue of
%     processing (if cues is a scalar) or the start and end cue (if a
%     vector).
%		If optional argument NR=1, an interference reduction step is
%		performed prior to decimation.
%
%     markjohnson@st-andrews.ac.uk
%     12 march 2018

L = [] ;
if nargin<2,
   help d3rmslight
   return
end

if nargin<3 || isempty(fs),
	fs = 5 ;                % output sampling rate, Hz
end

if nargin<4 || isempty(cues),
   cues = 0 ;
end

if nargin<5,
	NR = 0 ;
end
	
LEN = 3600 ;               % analysis block length in secs

% get the sampling frequency
X = d3getswv([0 1],recdir,prefix) ;

% find the light (external) channel
ch_names = d3channames(X.cn) ;
cc = strfind(ch_names,'EXT') ;
cn = [] ;
for k=1:length(cc),
   if ~isempty(cc{k}),
      cn = k ;
      break
   end
end

if isempty(cn),
   fprintf('Light sensor not recorded in this deployment\n') ;
   return
end
		
fsin = X.fs(cn) ;
bl = 2*round(fsin/fs) ; 		% work out the block size
ovl = round(bl-fsin/fs) ;
len = (bl*round(LEN*fsin/bl))/fsin ; 	% make sure len is a multiple of bl
cue = cues(1) ;
Z = [] ;

while 1,
   fprintf('Reading at cue %d\n', cue) ;
	try
		X = d3getswv(cue+[0 len],recdir,prefix) ;
	catch
		break
	end
	if isempty(X.x), break, end
	ll = X.x{cn} ;
	if NR~=0,
		ll = fix_light_sens(ll) ;
	end
   [Y,Z] = buffer([Z;ll],bl,ovl,'nodelay') ;
   n = size(Y,2) ;
   L(end+(1:n)) = sqrt(mean(Y.^2))' ;  % L is at fs
   if length(cues)>1,
      if cue>=cues(2), break, end
      cue = cue+min(len,cues(2)-cue) ;
   else
      cue = cue+len ;
   end
end

L = L(:) ;		% make sure L is a column vector
L = sens_struct(L,fs,prefix,'light') ;
L.input_sampling_rate = fsin ;
L.decimation_factor = round(fsin/fs) ;
L.history = 'd3light' ;
L.noise_reduction = NR ;
L.input_sampling_rate = fsin ;
L.rms_averaging_time = bl/fsin ;
if cues(1)~=0,
	L.start_offset = cues(1) ;
	L.start_offset_units = 'seconds' ;
end
return
