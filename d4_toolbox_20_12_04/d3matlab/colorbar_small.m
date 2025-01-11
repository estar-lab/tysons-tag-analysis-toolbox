function		colorbar_small(name,locn)

%		colorbar_small(name,locn)
%
%

if nargin<2,
	locn = 'outside' ;
end

NP = 64 ;      % number of colour points to use
mainax = gca ;
ax = get(mainax,'Position') ;
cax = caxis ;

if strcmp(locn,'inside'),
	ax = [ax(1)+ax(3)-0.015 ax(2)+0.3*ax(4) 0.015 0.5*ax(4)] ;
else
	ax = [ax(1)+ax(3)+0.01 ax(2)+0.3*ax(4) 0.015 0.5*ax(4)] ;
end
pp = polyfit([0.25 0.75],cax,1) ; 
clims = [pp(2) pp(1)+pp(2)] ;
h = axes('Position',ax) ;
set(h,'XTick',[],'YAxisLocation','right')
axis([0 1 cax])
cp = linspace(cax(1),cax(2),NP) ;
ct = ceil(cax(1)/10)*10:10:cax(2) ;
set(h,'YTick',ct)
box on
patch(repmat([0;1;1;0],1,NP),repmat([0;0;1;1],1,NP)+repmat(cp,4,1),repmat(cp,4,1)) ;
caxis(cax) ;
shading flat
set(h,'UserData',cax) ;
ylabel(name)
ff = gcf ;
ff.CurrentAxes = mainax ;
