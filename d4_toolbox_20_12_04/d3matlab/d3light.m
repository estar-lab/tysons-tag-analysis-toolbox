function   L = d3light(recdir,prefix,fs,cues,NR)
%
%     L = d3light(recdir,prefix,fs,cues,NR)
%     Perform noise cancellation and decimation on the light sensor
%     data for an entire full bandwidth tag deployment. This functions
%     reads the raw data (swv files) hour-by-hour and then decimates to
%     the requested output rate.
%     Default output sampling rate if fs is not given is 5 Hz.
%     Optional argument cues can be used to specify the start cue of
%     processing (if cues is a scalar) or the start and end cue (if a
%     vector).
%		If optional argument NR=1, an interference reduction step is
%		performed prior to decimation.
%
%     markjohnson@st-andrews.ac.uk
%     12 march 2018

if nargin<3,
   help d3light
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
	
len = 3600 ;               % analysis block length in secs

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
Z = round(fsin/fs) ; 		% work out the decimation factor
cue = cues(1) ;
L = [] ;

while 1,
   fprintf('Reading at cue %d\n', cue) ;
	try
		X = d3getswv(cue+[0 len],recdir,prefix) ;
	catch
		break
	end
	if isempty(X.x), break, end
	if NR==0,
		[ll,Z] = decz(X.x{cn},Z) ;
	else
		[ll,Z] = decz(fix_light_sens(X.x{cn}),Z) ;
	end
	L(end+(1:length(ll))) = ll ;
   if length(cues)>1,
      if cue>=cues(2), break, end
      cue = cue+min(len,cues(2)-cue) ;
   else
      cue = cue+len ;
   end
end

ll = decz([],Z);
L(end+(1:length(ll))) = ll ;
L = L(:) ;		% make sure L is a column vector
L = sens_struct(L,fs,prefix,'light') ;
L.input_sampling_rate = fsin ;
L.decimation_factor = round(fsin/fs) ;
if NR==0,
	L.history = 'd3light no noise reduction' ;
else
	L.history = 'd3light with noise reduction' ;
end
return
