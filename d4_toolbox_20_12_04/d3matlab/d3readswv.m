function    X = d3readswv(recdir,prefix,df,ch,fnums)

%     X = d3readswv(recdir,prefix)
%     or
%     X = d3readswv(recdir,prefix,df)
%     or
%     X = d3readswv(recdir,prefix,df,ch)
%     or
%     X = d3readswv(recdir,prefix,df,ch,fnums)
%     or
%     X = d3readswv(recdir,prefix,'info') % return sensor information
%     or
%     d3readswv(recdir,prefix)  % just show the sensor information
%
%     Reads a sequence of D3 format SWV (sensor wav) sensor files
%     and assembles a continuous sensor sequence in x.
%     Calls d3parseswv to read in each file.
%     recdir is the deployment directory e.g., 'e:/eg15/eg15_207a'.
%     prefix is the base part of the name of the files to analyse e.g., 
%        if the files have names like 'eg207a001.wav', put prefix='eg207a'.
%     df is an optional decimation factor. If df is not specified, a
%        df of 1 is used, i.e., the full rate data is returned (which
%        may be very large and cause memory problems). If df is a
%        positive integer, the data will be decimated to give a rate 
%        for each channel of 1/df of the input data rate.
%        If df is replaced with the string 'info', d3readswv will just
%        return the sampling rate and sensor channel names without reading
%        the data.
%     ch is an optional string specifying the sensor channel types to read
%        e.g., 'acc', 'mag', 'pres'. ch can also be a vector of channel 
%        numbers to read. The channel numbers are the same as those
%        returned in X.cn. Use [] for all channels. 
%        If ch is specified, only the sensor channels matching the type 
%        (or numbers) given in ch will be read. This is useful if you want
%        to read just one type of sensor and process it in a particular way.
%        To find out what channels are available in a dataset, use:
%        d3channames(recdir,prefix).
%     fnums is an optional vector of file numbers to read. The default is
%        to read all files in recdir with names starting with prefix. fnums
%        allows a subset of files to be specified. This is useful if there
%        is a large gap between recordings (e.g., due to duty-cycling) that
%        you do not want to fill to make a contiguous sensor vector.
%
%     Returns:
%     X  is a structure containing:
%        x: a cell array of sensor vectors. There are as many
%        cells in x as there are unique sensor channels in the
%        recording. Each cell may have a different length vector
%        according to the sampling rate of the sensor channel.
%        fs: a vector of sampling rates. Each entry in fs is the
%        sampling rate in Hz of the corresponding cell in x.
%        cn: a vector of channel id numbers corresponding to
%        the cells in x. Use d3channames to get the name and
%        description of each channel.
%        If the 'info' option is selected, X will contain an empty
%        .x field but the .fs and .cn fields will contain information
%        on the sensors.
%
%     If no output argument is given, a list of the channels and
%     sampling rates will be shown.
%
%     markjohnson@bios.au.dk
%     Licensed as GPL, 2013
%     Modified 8/7/18 to add alternative calling formats
%     Modified 31/8/19 to fix bug in handling gaps within files
%     Modified 24/4/21 to accept cuetables with an additional column (these
%        are to allow repaired swv files for a few deployments). Also
%			fixed minor bug that affected last few samples of decimated data.

X = [] ;
DISCARD = 1 ;     % discard the first 1s of data at start and after each gap
                  % to avoid power-up transients. Discard is done by replacing
                  % with NaNs to keep timing correct
OUTTHR = 0.4 ;
MAXOUT = 100 ;
MAXSIZE = 30e6 ;  % maximum size of storage object before using part files

if nargin<3 || isempty(df),
   df = 1 ;
end

if nargin<4,
   ch = [] ;
end

% get file names and cue table
[cuetab,nu1,basefs,fn,recdir,recn] = d3getcues(recdir,prefix,'swv') ;
if isempty(fn), return, end
X = d3parseswv([recdir '/' fn{1}],'info') ;
cn = X.cn ; fs = X.fs ;

% check if the call is an info request
if nargin>=3 && ischar(df) && strncmp(lower(df),'info',4),
   return
end

[chnames,descr,nu1,ctype] = d3channames(cn) ;
chnames = strvcat(chnames) ;
if nargout==0,
   fprintf('Sensor type\t\t\tSampling rate (Hz)\tDescription\n') ;
   for k=1:length(fs),
      fprintf('%10s\t%-5.1f\t\t\t\t%s\n',chnames(k,:),fs(k),descr{k}) ;
   end
end

if nargin==5 && ~isempty(fnums),    % restrict cue table to just requested file numbers
   k = find(ismember(recn(cuetab(:,1)),fnums)) ;
   cuetab = cuetab(k,:) ;
end

if nargin>=4 & ~isempty(ch),     % restrict channels to just requested channels
   if ischar(ch),
      k = find(all(chnames(:,1:length(ch))==repmat(upper(ch),size(chnames,1),1),2)) ;
      if isempty(k),
         fprintf(' No channels matching "%s" found in sensor data\n',ch) ;
         return
      end
      ch = cn(k) ;
   end
   % check that if pressure is requested that temperature is also returned
   k = find(ismember(cn,ch)) ;
   if any(all(chnames(k,1:4)==repmat('PRES',length(k),1),2)),
      ktemp = find(all(chnames(:,1:4)==repmat('TEMP',size(chnames,1),1),2)) ;
      ch = unique([ch(:);cn(ktemp)]) ;
      k = find(ismember(cn,ch)) ;
   end
   fs = fs(k) ;
   ctype = {ctype{k}} ;
else
   ch = cn ;
end

if ischar(df),
   fso = sscanf(upper(df),'U%d') ;
   df = round(fs/fso) ;
else
   df = df(1)*ones(length(fs),1) ;
end

zinit = cell(length(fs),1) ;
for kk=1:length(fs),
   zinit{kk} = df(kk) ;
end

fsmult = round(fs/basefs) ;

% collapse cuetab to amalgamate data-filled blocks
% i.e., block types 0 or 1
ct = cuetab(1,:) ;
for k=2:size(cuetab,1),
   if cuetab(k,4)<0 || cuetab(k,1)~=ct(end,1) || ct(end,4)<0,
      ct(end+1,:) = cuetab(k,:) ;
   else
      ct(end,3) = ct(end,3)+cuetab(k,3) ;
   end
end

x = [] ;
dodiscard = 1 ;
npartf = 0 ;
delete('_d3rpart*.mat') ;
ssamp = [1 0] ;
cnum = 1 ;
z = zinit ;

while cnum<=size(ct,1),     % read in swv data block-by-block
   if isempty(x),
      x = cell(length(fs),1) ;
   end
   blk = ct(cnum,:) ;
   if blk(4)<0,
      %if cnum==size(ct,1), break, end     % don't fill a trailing gap
      nfill = blk(3) ;
      fprintf(' Gap filled in recn %d, %d samples\n', recn(blk(1)),nfill);
      for kk=1:length(fs),
         xx{kk} = NaN(nfill*fsmult(kk),1) ;
      end
      dodiscard = 1 ;   % do a discard on the next block
      ssamp(2) = nfill ;
   else
      if ssamp(1)==1,
         fprintf('Reading file %s\n', fn{blk(1)}) ;
      else
         fprintf('Reading more from %s\n', fn{blk(1)}) ;
      end
      
      [XX,ssamp] = d3parseswv([recdir '/' fn{blk(1)}],ch,ssamp(1)+[0 blk(3)-1]) ;
      if isempty(XX.fs), return, end
      xx = XX.x ;
      clear XX
      
      % replace first DISCARD seconds with NaNs if dodiscard is set
      if dodiscard,
         nfill = round(basefs*DISCARD) ;
         for kk=1:length(fs),
            fill = NaN*ones(nfill*fsmult(kk),1) ;
            xx{kk}(1:size(fill,1)) = fill ;
         end
         dodiscard = 0 ;
      end
      
      % remove any single sample outliers on each sensor, skipping MAG and ACC sensors
      for kk=1:length(fs),
         if ismember(ctype{kk},{'acc','mag'}), continue, end
         xx{kk} = deglitch(xx{kk}) ;
      end
   end
   
   for kk=1:length(fs),
      if df(kk)==1,
         x{kk}(end+(1:length(xx{kk}))) = xx{kk} ;
      else 
   	   [xd,z{kk}] = decz(xx{kk},z{kk}) ;            
         x{kk}(end+(1:size(xd,1))) = xd ;
      end
   end
   sz = whos('x') ;
   if sz.bytes > MAXSIZE,
      npartf = npartf+1 ;
      fname = sprintf('_d3rpart%d.mat',npartf) ;
      save(fname,'x') ;
      x = [] ;
   end
   
   if ssamp(1)<0,
      cnum = cnum+1 ;
      ssamp = [1 0] ;
   else
      ct(cnum,3) = ct(cnum,3)-ssamp(2) ;
      if ct(cnum,3)==0,
         cnum = cnum+1 ;
      end
   end
end

X.fs = fs./df ;

% reload part files if they were used
if npartf>0,
	if ~isempty(x),
		npartf = npartf+1 ;
		fname = sprintf('_d3rpart%d.mat',npartf) ;
		save(fname,'x') ;
	end
   x = cell(length(xx),1) ;
   for k=1:npartf ;
      fname = sprintf('_d3rpart%d.mat',k) ;
      xx = load(fname) ;
      delete(fname) ;
      xx = xx.x ;
      for kk=1:length(xx),
         x{kk}(end+(1:length(xx{kk}))) = xx{kk} ;
      end
   end
   clear xx
end

% reorient columns if necessary
for kk=1:length(x),
   x{kk} = x{kk}(:) ;
end

if df>1,   % get the last few samples out of the decimation filter
   for kk=1:length(x),
      xd = decz([],z{kk}) ;
      x{kk}(end+(1:length(xd))) = xd ;
   end
end

X.x = x ;
X.cn = ch ;
return
