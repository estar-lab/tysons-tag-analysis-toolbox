function		make_aswv(recdir,depid,fnums)

%		make_aswv(recdir,depid,fnums)
%		Fix the accelerometer decimation error in a few long D4 deployments
%		such as ml19_295b.
%		This generates an adjunct swv file with suffix aswv which has reconstructed
%		data with the correct number of channels and samples to match the rest of
%		the deployment. Note that the sampling rate of the A data is repaired by
%		repeating samples - the effective bandwidth of affected files is still one
%		half of the intended sampling rate.

for k=1:length(fnums),
	fn = sprintf('%03d',fnums(k)) ;
	[xb,fs]=audioread([recdir '\' depid fn '.swv']);
	if rem(size(xb,1),2),
		xb = xb(1:end-1,:) ;
	end
	xb = reshape(xb',12,[])' ;
	xb = xb(:,[1:3 1:3 4:6 4:6 7:12]) ;
   
   % check length is correct compared to wavt
   fname = [recdir '\' depid fn,'.wavt'] ;  % first check if there are '.wavt' files in the new format
   c = csvproc(fname,[],[],1) ;
   ks = strmatch('swv',{c{:,1}}) ;
   blks = [] ;
   for kk=1:length(ks),
      blks(end+1,:) = str2double({c{ks(kk),2:end}}) ;
   end
   
   if size(xb,1)~=sum(blks(:,3)),
      n = sum(blks(:,3))-size(xb,1) ;
      if n>0,
         fprintf('File %s is short by %d samples: adding zeros\n',[depid fn],n) ;
         xb(end+(1:n),:) = 0 ;
      else
         fprintf('File %s is long by %d samples: truncating\n',[depid fn],-n) ;
         xb = xb(1:sum(blks(:,3)),:) ;
      end
   end

	if exist('wavwrite'),
		wavwrite(xb,fs,16,[recdir '\' depid fn '.aswv']) ;
	else
		% For matlab after 2013, use:
		audiowrite([recdir '\' depid fn 'temp.wav'],xb,fs,'BitsPerSample',16) ;
		movefile([recdir '\' depid fn 'temp.wav'],[recdir '\' depid fn '.aswv']) ;
	end
end

clear_cues(depid) ;
