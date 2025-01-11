function    [ct,ref_time,fs,fn,recdir,recn] = d3getcues(recdir,prefix,suffix)
%
%    [ct,ref_time,fs,fn,recdir,recn] = d3getcues(recdir,prefix,suffix)
%     Get the cue table, reference time, sampling rate and file information
%     for a D3 deployment.
%     ct has a row for each contiguous block in the deployment.
%     The columns of ct are:
%        File number (this is the sequential number of the file in the
%           directory, not the numerical suffix of the filename)
%        Start time in seconds since the reference time
%        Number of samples in the block
%        Status of block (0=data, -1=unfilled gap, 1=zero-filled)
%
%     Note: to convert the first column of ct to filename suffix, do:
%        ct(:,1) = recn(ct(:,1)) ;
%
%     markjohnson@st-andrews.ac.uk
%     bug fix: FHJ 8 april 2014
%     improved help 31/8/19

ct = [] ; ref_time = [] ; fs = [] ; fn = [] ; C = [] ; recn = [] ;

if nargin<2,
   help d3getcues
   recdir = [] ;
   return
end

if nargin<3 || isempty(suffix) || ~ischar(suffix),
   suffix = 'wav' ;
end

if ~isempty(recdir) && ~ismember(recdir(end),'/\'),
   recdir(end+1) = '/' ;
end

recdir(recdir=='\') = '/' ;      % use / for MAC compatibility
cuefname = [gettempdir '_' prefix suffix 'cues.mat'] ; 

if exist(cuefname,'file'),
   C = load(cuefname) ;
   if ~isfield(C,'vers') || C.vers ~= d3toolvers(),
      C = [] ;
   end
end
      
if isempty(C),
   fprintf(' Generating cue file for %s - will take a few seconds\n', suffix) ;
   cuefname = makecuefile(recdir,prefix,suffix) ;
   if isempty(cuefname),
      fprintf(' Unable to make cue file\n') ;
      return
   end
   C = load(cuefname) ;
end

fs = C.fs ;
ct = C.cuetab ;
fn = C.fn ;
recn = C.recn ;
ref_time = C.ref_time ;
return
