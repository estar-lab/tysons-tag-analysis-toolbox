function    [X,ssamp] = d3parseswv(fname,ch,ssamp)
%    [X,ssamp] = d3parseswv(fname,[ch,ssamp])
%     Read a D3 format SWV (sensor wav) sensor file using
%     the accompanying xml file to interpret the sensor channels.
%     To read all sensor files from a deployment, use d3readswv
%     which calls this function.
%     fname is the full path (if needed) and filename of the swv
%     file to read. The .swv suffix is not needed.
%     ch is an optional string specifying the sensor channel types to read
%        e.g., 'acc', 'mag', 'pres'. ch can also be a vector of channel 
%        numbers to read. The channel numbers are the same as those
%        returned in X.cn. Use [] for all channels. 
%        If ch is specified, only the sensor channels matching the type 
%        (or numbers) given in ch will be read. This is useful if you want
%        to read just one type of sensor and process it in a particular way.
%        To find out what channels are available in a dataset, use:
%        d3channames(recdir,prefix).
%     ssamp is the optional sample number to start reading from or the start
%        and end sample if a two-element vector. This is used to read a block
%        from an swv file or to read in long swv files a section at a time.
%
%     Returns:
%     X.x  is a cell array of sensor vectors. There are as many
%        cells in x as there are unique sensor channels in the
%        recording. Each cell may have a different length vector
%        according to the sampling rate of the sensor channel.
%     X.fs is a vector of sampling rates. Each entry in fs is the
%        sampling rate in Hz of the corresponding cell in x.
%     X.cn is a vector of channel id numbers corresponding to
%        the cells in x. Use d3channames to get the name and
%        description of each channel.
%     ssamp contains the next sample number in the input file and the number
%        of samples successfully read. The next sample number is -1 if X
%        contains the end of the file.
%
%     Updated 29/01/18 to enable subset of channels to be read
%     Updated 13/02/19 fixed bug in channel selection 
%		Updated 4/06/19 added support for variances to fix errors in the XML files
%     Updated 31/08/19 added support for start and end sample counts
%     markjohnson@st-andrews.ac.uk
%     Licensed as GPL, 2013

X.x = [] ; X.fs = [] ; X.cn = [] ;
if nargin<1,
   help d3parseswv
   return
end

% remove a suffix from the file name if there is one
if any(fname=='.'),
   fname = fname(1:find(fname=='.',1)-1) ;
end

suffix = 'swv' ;

% get metadata
% get sensor channel names from the xml file
d3 = getd3xml(fname) ;
if isempty(d3) | ~isfield(d3,'CFG'),
   fprintf('Unable to find or read file %s.xml - check the file name\n', fname);
   return
end

[CFG,fb,dtype] = getsensorcfg(d3) ;
if isempty(CFG),
   fprintf('No sensor configuration in file %s\n',fname) ;
   return
end

% find the channel count and numbers
N = str2double(CFG.CHANS.N) ;
if isempty(N),
   fprintf('Invalid attribute in CHANS field - check xml file\n') ;
   return
end

chans = sscanf(CFG.CHANS.CHANS,'%d,') ;

% Following lines are only needed for ml19_294b015-021 which had an eeprom
% read bug and recorded with df=10 (nch=12) but generated 6-channel SWV
% files. The accelerometer and magnetometer data are also not useable in
% these files.
n = audioinfo([fname '.' suffix]) ;
if n.NumChannels~=N,
   suffix = 'aswv' ;
   if ~exist([fname '.' suffix])
      fprintf('Error: mismatch in channel count between xml and swv, use make_aswv to make repair file\n');
      return
   end
   fprintf('Warning: mismatch in channel count between xml and swv, using repair file\n');
   N = 18 ;
   chans = chans([1:6 1:6 7:end]) ;
end
% end bug fix

if length(chans)~=N,
   fprintf('Attribute N does not match value size in CHANS field - check xml file\n') ;
   return
end

chans = chans(:) ;
uchans = unique(chans) ;

% group channels
fs = zeros(length(uchans),1) ;
for k=1:length(uchans),
   kk = find(chans==uchans(k)) ;
   fs(k) = fb*length(kk) ;
end

X.fs = fs ;
X.cn = uchans ;
if nargin>=2 && ~isempty(ch),
   if ischar(ch)
      if strcmp(ch,'info'),
         return
      else
         [chnames,descr,chnums] = d3channames(chans) ;
         cname = ch ;
         m = strfind(chnames,upper(ch)) ;
         ch = [] ;
         for k=1:length(m),
            if ~isempty(m{k}),
               ch(end+1) = chnums(k) ;
            end
         end
         if isempty(ch),
            fprintf(' No channels matching "%s" found in sensor data\n',cname) ;
            return
         end
      end
   end
   k = find(ismember(uchans,ch)) ;
   uchans = uchans(k) ;
   fs = fs(k) ;
   X.cn = uchans ;
   X.fs = fs ;
end

if isempty(uchans),
   return
end

% read the swv file and convert to fractional offset binary
n = audioinfo([fname '.' suffix]) ;

maxsamps = floor(30e6/n.NumChannels) ;
if nargin<3 || isempty(ssamp),
   ssamp = 0 ;
elseif ischar(ssamp),
   if strcmp(ssamp,'DF10BUG'),
      doreshape = 1 ;
   end
   ssamp = 0 ;
end

if ssamp(1)>n.TotalSamples,
   ssamp = 0 ;
   return
end

if length(ssamp)==1,
   ssamp(2) = n.TotalSamples ;
end

ssamp(1) = max(ssamp(1),1) ;
ssamp(2) = min(ssamp(2),n.TotalSamples) ;
nsamps = min(ssamp(2)-ssamp(1)+1,maxsamps) ;
xb = audioread([fname '.' suffix],ssamp(1)+[0 nsamps-1]) ;
if size(xb,1)~=nsamps,
	keyboard
end

if dtype==3,
   k = find(xb<0) ;
   xb(k) = 2+xb(k) ;               % convert from two's complement to offset binary
   xb = xb/2 ;                     % sensor reading range is 0..1 in Matlab
   %xb(xb==0) = NaN ;               % replace fill values with NaN
else
   xb(all(xb==-1,2),:) = NaN ;         % replace fill words with NaN
end

if ssamp(1)+nsamps>n.TotalSamples,
   ssamp(1) = -1 ;
else
   ssamp(1) = ssamp(1)+nsamps ;
end
ssamp(2) = nsamps ;

% group channels
x = cell(length(uchans),1) ;
for k=1:length(uchans),
   kk = find(chans==uchans(k)); 
   if ~isempty(kk),
      x{k} = reshape(xb(:,kk)',[],1) ;
   end
end

X.x = x ;
if isfield(CFG,'CAL'),
   X = d3builtincal(X,CFG) ;
end
return
