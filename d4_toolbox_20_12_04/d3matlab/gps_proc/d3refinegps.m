function obs = d3refinegps(recdir,depid,thr)

%		d3refinegps(recdir,depid,thr)
%		Improve estimates of pseudo-ranges after gps pre-processing.
%		This function does a finer delay-doppler search around each ambiguity
%		function peak found by d3preprocgps. This can improve the accuracy of
%		the resulting position estimates by a few metres.
%		thr is an optional minimum signal power threshold. If not given, a
%		default value of 200 is used.
%
%		This function adds a field called R to the OBS structures in the gps
%		files produced by d3preprocgps. R is a matrix containing 4 columns:
%		SV number, signal power, noise floor, code delay
%		R only has as many rows as there are satellites above the threshold.
%
%		markjohnson@bios.au.dk
%		last modified: 1 april 2021		

suffix = 'bin' ;		% default suffix for gps files
ending = 'gps' ;		% default ending of gps preprocessed files

obs = [] ;

if nargin<2,
	help d3refinegps
	return
end

if nargin<3,
	thr = 200 ; 
end

fdir = dir([recdir '/' depid '*' ending '.mat'])	;
fnames = {fdir.name} ;

findz = 1 ;		% search for a zero sentinel in the grab data
nb = 1 ;			% grab data has 1 bit resolution

for k=1:length(fnames),
	fprintf(' Reading file %d of %d\n',k,length(fnames)) ;
	S = load([recdir,'/',fnames{k}]) ;
	obs = S.obs ;
	if isempty(obs), continue, end
	
	fn = fnames{k} ;
	B = d3readbin([recdir,'/',fn(1:end-length(ending)-4) '.' suffix],[]) ;
	
	for kk=1:length(obs),
		fprintf(' Processing capture %d of %d\n',kk,length(obs)) ;
		x = B{kk} ;	% get next grab data
		if findz==1,	% find the start point in the data
			kz = find((x(1:end-1)==0) & (x(2:end)==0)) ;
			if isempty(kz), continue, end
			x = x([kz(end)+2:end 1:kz(1)-2]) ;
		end
   
		snr = 10.^(obs(kk).snr/10) ;
		dop = obs(kk).dop ;
		ksv = find(snr>thr) ;
		if isempty(ksv),
			obs(kk).R = [] ;
		else
			[bb,fs] = bitgrab2bb(x,8,0,nb);
			obs(kk).R = gps_incoherent(bb,8,ksv,dop(ksv));
		end
	end

	proc = sprintf('d3refinedel, thr=%d, span=%d-%d ms',round(thr),1,floor(length(x)/2046)) ;
	save([recdir,'/',fnames{k}],'obs','proc') ;
end
