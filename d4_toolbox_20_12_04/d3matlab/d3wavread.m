function    [x,fs] = d3wavread(cues,recdir,prefix,suffix)

%     [x,fs] = d3wavread(cues,tag)  % read data from tag using tag path
%     or
%     [x,fs] = d3wavread(cues,0,tag)  % read data from tag using tag path
%     or
%     [x,fs] = d3wavread(cues,recdir,prefix) % read data from a directory
%     or
%     [x,fs] = d3wavread(cues,recdir,prefix,suffix) % specify WAV file suffix
%
%     Inputs:
%     cues = [start_cue end_cue], cues are in seconds with respect
%        to the ref_time associated with the recording (see d3getcues)
%     or
%     cues = [start_cue end_cue ref_time], cues are in seconds
%        with respect to a user-defined ref_time. ref_time must be in
%        UNIX seconds (fractional seconds are allowed). Use d3datevec
%        to convert a date-time vector to UNIX time.
%     recdir is the deployment directory e.g., 'e:/eg15/eg15_207a'.
%     prefix is the base part of the name of the files to analyse e.g., 
%        if the files have names like 'eg207a001.wav', put prefix='eg207a'.
%
%     Returns:
%     x is a vector (or matrix if the WAV data is multichannel) containing
%       the sound data at the requested cues.
%     fs is the sampling rate of x in Hz.
%
%     Examples:
%        1. explicit definition of where the audio files are:
%         d3wavread([2000 2010],'f:/hp14/hp14_226b','hp14_226b');
%        2. use settagpath shortcut method as with dtag2 data:
%         settagpath('AUDIO','f:')
%         d3wavread([2000 2010],'hp14_226b');
%
%     MJ with help from DMW
%     Modified 12/2/15 to allow gaps between recordings
%     Modified 2/3/18 to fill gaps with NaN instead of 0 and fixed bug on line 148
%     Modified 12/9/18 to support dtag version 2 to 4
%     Modified 20/12/18 to support dutycycled data sources such as sonars
%     Fixed small bug in fail detection 26/02/19
%
%     markjohnson@st-andrews.ac.uk
%     Licensed as GPL, 2013


x = [] ; fs = [] ;
if nargin<2,
   help d3wavread
   return
end

if nargin<4 || isempty(suffix) || ~ischar(suffix),
   suffix = 'wav' ;
end

if nargin>=3 && ~ischar(recdir(1)) && recdir(1)==0,
   [recdir,prefix] = tag2recdirprefix(prefix) ;
end

if nargin<3,
   [recdir,prefix] = tag2recdirprefix(recdir) ;
end

if length(cues)<2,
   fprintf(' Cues must be a two-element vector with start and end time in seconds\n');
   return
end

if isdtag2(prefix),
   [x,fs] = tagwavread(prefix,cues(1),cues(2)-cues(1)) ;
   return
end

[ct,ref_time,fs,fn,recdir] = d3getcues(recdir,prefix,suffix) ;
if isempty(ct),
   fprintf(' Unable to make cue file\n') ;
   return
end

if size(ct,2)<5, % convert an older style cuetable to the new 5 column format
   ct(:,5) = 0 ;
end

% convert cues with a different time reference, if necessary
if length(cues)>2,
   cues = cues(1:2)+(cues(3)-ref_time) ;
end

if length(cues)==1,
   cues(2) = cues(1)+1 ;
end

k = find(ct(:,2)<=cues(1),1,'last') ;
if isempty(k),
   fprintf(' Cue is before the start of recording\n') ;
   return
end

% compute the number of samples to read
n = round(fs(1)*(cues(2)-cues(1))) ;    
c = cues(1) ;
x = [] ;
fails = 0 ;     % keep track of number of fails in loop
while n>0,
   % find which block the next cue comes from
   bn = find(c>=ct(:,2),1,'last') ;    % find which block the current cue comes from
   fnum = ct(bn,1) ;
   bn1 = find(ct(:,1)==fnum,1,'first') ;  % find the first block of the file that the cue comes from
   kg = bn1-1+find(ct(bn1:bn-1,4)<0) ;    % find any gap blocks - these do not appear in the file
   % convert cue to samples wrt start of block
   st = round(fs(1)*(c-ct(bn,2))) ;
   % convert cue to samples wrt start of file
   stb = round(fs(1)*(c-ct(bn1,2)))-sum(ct(kg,3)) ;
   % find out how many samples can be taken from this block
   len = min(n,ct(bn,3)-st) ;
   %fprintf('piece: %d %d %d %f %d %d\n',fnum,bn,bn1,c,n,len);
   %fprintf(' ct bn: %d %f %d %d %d\n',ct(bn,:));
   %fprintf(' ct bn1: %d %f %d %d %d\n',ct(bn1,:));
   if len<n & bn==size(ct,1), 
      fprintf(' cue is beyond end of recording - truncating\n') ;
   elseif len<0,
      if bn<size(ct,1),    % if there are more blocks...
         fprintf(' Warning: possible gap between blocks\n') ;
         c = ct(bn+1,2) ; % skip to the next block
         fails = fails+1 ;
         if fails < 3,
            continue
         else
            break
         end
      else
         fprintf(' Warning: not enough samples in recording\n') ;
         break 
      end
   elseif len==0,
      c = c+1/(2*fs(1));   % catch rare case of cue coinciding with block end
      fails = fails+1 ;
      if fails < 3,
         continue
      else
         break
      end
   end

   if size(ct,2)==5 & ct(bn,5)==1,
      rsuffix = ['a' suffix] ;
   else
      rsuffix = suffix ;
   end
   
   % and read the samples
   if ct(bn,4)<0,
      fprintf(' Warning: cue falls in a gap - filling with NaN\n') ;
      if isempty(x),
         % find out how many channels there are
         nn = audioinfo([recdir fn{ct(bn-1,1)},'.',rsuffix]) ;
         nch = nn.NumChannels ;
      else
         nch = size(x,2) ;
      end
      xx = NaN*zeros(len,nch) ;

   else
      fname = fn{ct(bn,1)} ;
      try
         sz = audioinfo([recdir fname,'.',rsuffix]) ;
         sz = sz.TotalSamples ;
      catch
         fprintf(' Unable to read from file %s.%s\n',fname,rsuffix) ;
         return
      end
      
      len = min(len,sz(1)-stb);
      if len<1,
         fprintf(' -ve length request from file %s, skipping\n',fname) ;
         c = c+1/(fs(1)*2);
         fails = fails+1 ;
         if fails < 3,
            continue
         else
            break
         end
      end
  %fprintf('Reading %d samples starting at %d in %s\n',len,stb,fname)
      xx = audioread([recdir fname,'.',rsuffix],stb+[1 len]) ;
  %fprintf('  Got %d samples\n',size(xx,1))
      fails = 0 ;
   end
   
   x = [x;xx] ;
   if size(xx,1)<len,
      fprintf(' error reading file %s - insufficient samples\n',fname) ;
      return
   end
   n = n-len ;
   %c = c+(len+1)/fs ;		% was this until 2/3/18. Not sure why +1
   c = c+len/fs(1) ;				% MJ changed to this.
end
