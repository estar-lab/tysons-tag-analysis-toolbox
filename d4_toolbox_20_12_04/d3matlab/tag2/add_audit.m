function    aud = add_audit(aud,cues,stype)

%    aud = add_audit(aud,newaud)
%    or
%    aud = add_audit(aud,cues,stype)
%    Append new annotations to an audit structure

if ~isstruct(cues),
   naud.cue = cues ;
   if ischar(stype)
      [naud.stype{1:size(cues,1)}] = deal(stype) ;
   else
      naud.stype = stype ;
   end
else
   naud = cues ;
end

if isempty(aud),
   aud = naud ;
else
   aud.cue(end+(1:size(naud.cue,1)),1:2) = naud.cue ;
   [aud.stype{end+(1:size(naud.cue,1))}] = deal(naud.stype{:}) ;
end
