function    [x,ofs] = d3wavdecimate(recdir,depid,df,cues,suffix)

%     [x,fs] = d3wavdecimate(recdir,depid,df)
%		or
%		[x,fs] = d3wavdecimate(recdir,depid,df,cues)
%		or
%		[x,fs] = d3wavdecimate(recdir,depid,df,cues,suffix)
%
%		recdir is the full path to the directory with the input files.
%		fbase is the filename base, i.e., the part of the filename that is
%		 common to all the files to be decimated.
%		df is the decimation factor, a whole number. If df is large (e.g., >30),
%		 it is better to do the decimation in two steps. To do this give two 
%		 decimation factors: e.g., df = [12,10] gives a decimation of 120.
%
%		markjohnson@bios.au.dk
%		May 2022

x = [] ; ofs = [] ;
if nargin<3,
	help d3wavdecimate
	return
end

if nargin<4 || isempty(cues),
	cues = 0 ;
end

if nargin<5,
	suffix = 'wav' ;
end

% get sampling rate and number of channels
[y,fs] = d3wavread(cues(1)+[0 0.1],recdir,depid,suffix) ;
nch = size(y,2) ;
if length(df)>1,
	ofs = fs/(df(1)*df(2)) ;
else
	ofs = fs/df ;
end

if length(cues)==1
	if ~ischar(recdir(1)) && recdir(1)==0,
		cues(2) = recordlength(depid) ;
	else
		cues(2) = d3wavcues([],recdir,depid,1,suffix) ;	% get end cue
	end
end

if diff(cues)*ofs > 1e8,
	fprintf('Output data length is too large\n') ;
	return
end
	
ns = 5e6/(fs*nch) ;	% number of seconds to read at a time
z1 = df(1) ;
if length(df)>1,
	z2 = df(2) ;
end

while 1
   fprintf(' Copying minute %3.1f of %3.1f\n',cues/60) ;
   nn = min([ns diff(cues)]) ;
	if nn==0, break, end
   y = d3wavread(cues(1)+[0 nn],recdir,depid,suffix) ;
	if isempty(y), break, end
	[y,z1] = decz(y,z1) ;
	if length(df)>1,
		[y,z2] = decz(y,z2) ;
	end
   x(end+(1:size(y,1)),1:size(y,2)) = y ;
   cues(1) = cues(1)+nn ;
end

% get any last samples out of the buffers
[y,z1] = decz([],z1) ;
if length(df)>1,
	[y,z2] = decz(y,z2) ;
end
if ~isempty(y),
	x(end+(1:size(y,1)),1:size(y,2)) = y ;
end
