function 	Z = wav_decimate(ifname,ofname,df,Z)
%
%   wav_decimate(ifname,ofname,df)
%	 or
%   Zo = wav_decimate(ifname,ofname,df,Zi)
%   Decimate audio data from wav file fname into a new wav file
%
%   mark johnson
%   markjohnson@bios.au.dk
%   last modified: January 2022

if nargin<3,
   help wav_decimate
   return
end

if nargin<4,
	Z = [] ;
end
	
% get sampling rate and number of channels
s = audioinfo(ifname) ;
fs = s.SampleRate ;
cend = s.TotalSamples ;
nch = s.NumChannels ;
if length(df)>1,
	ofs = fs/(df(1)*df(2)) ;
else
	ofs = fs/df ;
end

% create wav file
audiowrite(ofname,zeros(10,nch),round(ofs),'BitsPerSample',16) ;
f = fopen(ofname,'r+','l') ;

% move file cursor to start of data chunk
fseek(f,-10*2*nch,'eof') ;

% copy the data, piece at a time
curs = 1 ;
db = 0 ;

flen1 = 18*df(1) ;
h1 = fir1(flen1,0.9/df(1))' ;
if length(df)>1,
	flen2 = 18*df(2) ;
	h2 = fir1(flen2,0.9/df(2))' ;
end

if isstruct(Z),
	z1 = Z.filt1 ;
	s1 = Z.s1 ;
	if length(df)>1,
		z2 = Z.filt2 ;
		s2 = Z.s2 ;
	end
else
	z1 = zeros(length(h1)-1,1) ;
	s1 = [] ;
	if length(df)>1,
		z2 = zeros(length(h2)-1,1) ;
		s2 = [] ;
	end
end

while curs<cend,
   fprintf(' Copying minute %3.1f of %3.1f\n',curs/fs/60,cend/fs/60) ;
   n = min([1e7 cend-curs]) ;
   y = audioread(ifname,[curs curs+n-1]) ;
   [y,z1] = filter(h1,1,y,z1) ;
	y = [s1;y] ;
	nz = rem(size(y,1),df(1)) ;
	s1 = y(end+(-nz+1:0)) ;
   y = y(df(1):df(1):end,:) ;
	if length(df)>1,
		[y,z2] = filter(h2,1,y,z2) ;
		y = [s2;y] ;
		nz = rem(size(y,1),df(2)) ;
		s2 = y(end+(-nz+1:0)) ;
		y = y(df(2):df(2):end,:) ;
	end
   fwrite(f,round(32768*reshape(y',[],1)),'short') ;
   curs = curs+n ;
   db = db+size(y,1) ;
end

Z.filt1 = z1 ;
Z.s1 = s1 ;
if length(df)>1,
	Z.filt2 = z2 ;
	Z.s2 = s2 ;
end

% adjust header of output wavfile
db = db*2*nch ;
riff_size = 36+db ;

% Fix RIFF chunk size:
fseek(f,4,'bof') ;                % skip RIFF chunk header
fwrite(f,riff_size,'ulong');      % RIFF chunk size: 4 bytes 

% skip WAVE chunk (4 bytes)
% skip fmt chunk (8+16 bytes)
% skip data chunk header (4 bytes)

% Fix data chunk size
fseek(f,32,'cof') ;
fwrite(f,db,'ulong');      % data chunk size: 4 bytes 

% Close file:
fclose(f);
