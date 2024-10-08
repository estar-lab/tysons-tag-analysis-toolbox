function			check_sv_elevation(OBS,latr,longr,tc,THR)

%			check_sv_elevation(OBS,latr,longr,tc,THR)
%			OBS is a structure containing pseudo-range observations 
%			from d3preprocgps. This function searches in OBS for the first
%		   grab with at least 6 SVs with received level over 200 (or the
%			user defined threshold). All grabs with 6 or more SVs over threshold
%			performed in the following 6 hours are then identified. The function
%			searches a 1x1 degree grid of possible latitudes and longitudes to
%			find the minimum elevation angle of an observed SV in the selected
%			set of grabs. Appropriate starting points lie in the set of grids
%			for which the minimum elevation angle is greater than zero.
%			latr = [min_lat,max_lat] is a range of latitudes over which to 
%			 search, in degrees.
%			longr = [min_long,max_long] is a range of longitudes over which to 
%			 search, in degrees.
%			tc = [min_t,max_t] is a range of time errors to search over, in seconds.
%			THR is an optional SV magnitude threshold. Default value is 200.
%
%			Example:
%			check_sv_elevation(OBS,[-50 -44],[62 68],[-20 20]);
%
%			markjohnson@st-andrews.ac.uk
%			8 March 2018

if nargin<4,
	help check_sv_elevation
	return
end
	
if nargin<5,
	THR = 200 ;
end

[latc,longc] = meshgrid(min(latr):max(latr),min(longr):max(longr)) ;
figure(1),clf,hold on,grid on
axis([min(longr)-0.5 max(longr)+0.5 min(latr)-0.5 max(latr)+0.5])
caxis([-10 10])
colorbar

T=vertcat(OBS.T);
S=horzcat(OBS.snr);
S=10.^(S/10) ;
ks = find(sum(S>THR)>=6) ;
tt = etime(T(ks,:),repmat(T(ks(1),:),length(ks),1)) ;
ke = find(tt<6*3600,1,'last') ;
T = T(ks(1:ke),:) ;
S = S(:,ks(1:ke)) ;
toffs = mean(tc) ;
tc = tc - mean(tc) ;

TT = datevec(datenum(T)+toffs/(24*3600)) ;
eph = cell(size(S,2),1) ;
sgps = zeros(size(S,2),1) ;
for kg=1:size(S,2),
   EPH = get_ephem(TT(kg,:),1) ;
   eph{kg} = EPH{1} ;
   tgps = utc2gps(TT(kg,:)) ;
   sgps(kg) = tgps(2) ;        % GPS second of week
end

M = NaN*zeros(size(latc,1)*size(latc,2),1) ;
for k=1:length(E),
   ecef_pos = lla2ecef([[latc(k) longc(k)]*pi/180 0]) ;
   mm = zeros(size(S,2),1) ;
   for kg=1:size(S,2),
      SVP = svposns(eph{kg},sgps(kg),ecef_pos) ;
      kk = find(S(:,kg)>THR) ;
      mm(kg) = min(SVP(kk,7)) ;
   end
   M(k) = min(mm) ;
	if isnan(M(k)),
		scatter(longc(k),latc(k),100,minC)
	else
		scatter(longc(k),latc(k),100,M(k),'filled')
	end
	caxis([minC maxC])
	drawnow
end

[m,k] = nanmin(M) ;
fprintf('Best fit at latitude %d, longitude %d with %d minimum elevation\n',latc(k),longc(k),round(m))
