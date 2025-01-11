function		R = mergeaudit(R1,R2)

%		R = mergeaudit(R1,R2)
%		Combine two audit structures
%

R.cue = [R1.cue;R2.cue] ;
R.stype = {R1.stype{:} R2.stype{:}} ;
R.comment = {R1.stype{:} R2.stype{:}} ;
R.commentcue = [R1.commentcue;R2.commentcue] ;
[r,I] = sort(R.cue(:,1)) ;
R.cue = R.cue(I,:) ;
R.stype = {R.stype{I}} ;
