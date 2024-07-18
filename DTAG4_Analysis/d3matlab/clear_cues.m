function    clear_cues(prefix)
%
%     clear_cues(prefix)
%     Delete the directory and cue helper files for a tag deployment.
%     These helper files are generated automatically to speed up processing
%     of the large number of files in a dtag archive. If the archive is
%     changed e.g., by adding or deleting recordings, the helper files are
%     no longer valid and have to be re-built. This function deletes the
%     files forcing them to be rebuilt by subsequent operations.
%
%     markjohnson@st-andrews.ac.uk
%     10 march 2018

if nargin<1,
   help clear_cues
   return
end

cuefname = ['_' prefix '*.mat'] ;      % changed to store helper files in local directory
fn = dir(cuefname) ;
for k=1:length(fn),
   delete(fn(k).name) ;
end
