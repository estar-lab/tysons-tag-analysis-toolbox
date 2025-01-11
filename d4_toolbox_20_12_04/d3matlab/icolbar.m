function    [h,clims] = icolbar(cax,usecax,name)

%    [h,clims] = icolbar(cax,usecax,name)  % to create an interactive colourbar
%    or
%    cax = icolbar(h,sel,ul) % to update an interactive colourbar
%

if ishandle(cax)    % if there is already a colourbar, update it
   cb = get(cax,'UserData') ;
   h = caxis(cax) ;
   if name==0
      h(1) = min(max(usecax,cb(1)),cb(2)-3) ;
   else
      h(2) = max(min(usecax,cb(2)),cb(1)+3) ;
   end
   h = sort(h) ;
   if h(2)==h(1), h(2)=h(1)*1.01 ; end
   caxis(cax,h) ;
	return
end

% otherwise make one
NP = 64 ;      % number of colour points to use
mainax = gca ;
ax = get(mainax,'Position') ;
ax = [ax(1)+ax(3)+0.01 ax(2)+0.3*ax(4) 0.02 0.4*ax(4)] ;
pp = polyfit([0.3 0.7],cax,1) ; 
clims = [pp(2) pp(1)+pp(2)] ;
h = axes('Position',ax) ;
set(h,'XTick',[],'YAxisLocation','right')
axis([0 1 cax])
cp = linspace(cax(1),cax(2),NP) ;
ct = ceil(cax(1)/10)*10:10:cax(2) ;
set(h,'YTick',ct)
box on
patch(repmat([0;1;1;0],1,NP),repmat([0;0;1;1],1,NP)+repmat(cp,4,1),repmat(cp,4,1)) ;
caxis(usecax) ;
shading flat
set(h,'UserData',cax) ;
ylabel(name)
ff = gcf ;
ff.CurrentAxes = mainax ;
%axes(mainax) ;
return
