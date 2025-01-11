function    R=loadaudit(tag)
%
%    R=loadaudit(tag)
%     read an audit text file into an audit structure.
%     The text file must contain lines of the form:
%        cue duration type
%     Comments preceded by the symbol % will also be read in.
%
%     Input:
%     tag is the name of a deployment, e.g., 'hp18_102a' or is the full
%     name, including suffix, of an audit file, e.g., 'hp18_102aaudbz.txt'.
%
%     Output:
%     R is a structure containing fields:     
%        R.cue is a nx2 matrix of [cue duration] in seconds since tag on
%        R.stype is a cell array of type strings matching each row of R.cue
%        R.comment is a cell array of comments
%        R.commentcue is a vector of indices in R.cue for the notes
%
%     markjohnson@bio.au.dk
%     last modified: March 2022
%     added direct filename input option

R.cue = [] ;
R.stype = [] ;
R.comment = [] ;
R.commentcue = [] ;

if nargin<1
   help loadaudit
   return
end

% try to make filename
global TAG_PATHS
if ~isempty(TAG_PATHS) && isfield(TAG_PATHS,'AUDIT')
   fname = sprintf('%s/%s',TAG_PATHS.AUDIT,tag) ;
else
   fname = tag ;
end
if all(tag~='.')
   fname = [fname 'aud.txt'] ;
end

% check if the file exists
if ~exist(fname,'file')
   fprintf(' Unable to find audit file %s - check directory and settagpath\n',fname) ;
   return
end

f = fopen(fname,'rt') ;
done = 0 ;

while ~done
   s = fgetl(f) ;
   if s==-1
      fclose(f) ;
      return
   end

   k = min(find(s == '%')) ;
   if ~isempty(k)
      note = s(k:end) ;
      if k==1
         s = [] ;
      else
         s = s(1:k-1) ;
      end
   else
      note = [] ;
   end

   if ~isempty(s)
      [cs,s] = strtok(s) ;
      c = str2double(cs) ;
      [ds,s] = strtok(s) ;
      d = str2double(ds) ;
      if all(~isnan([c d]))
         knext = size(R.cue,1)+1 ;
         R.cue(knext,:) = [c d] ;
         [ss,s] = strtok(s) ;
         R.stype{knext} = [ss s] ;  % strip leading white space from remainder
      end
   end

   if ~isempty(note)
      knote = size(R.commentcue,1)+1 ;
      R.comment{knote} = note ;
      R.commentcue(knote,:) = size(R.cue,1) ;
   end
end

fclose(f) ;
