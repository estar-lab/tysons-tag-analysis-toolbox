function		[h,clims] = side_menu(h,g,sel)

%		[h,clims] = side_menu(s,g,sel)
%     or
%     s = update_menu(h,y,s)
%     This is a function called by echogram_annotate. Not intended for other uses.

if ishandle(h),
   ud = get(h,'UserData') ;
   k = nearest(ud.m,g) ;
   tg = ud.g(k) ;
   if tg>0,
      set(ud.t(ud.g==tg),'Color','k')
      set(ud.t(k),'Color','r')
      sel{tg} = ud.s{k} ;
   end
   h = sel ;
   return
end

s = h ;
n = max(8,length(s)) ;
mainax = gca ;
ax = get(gca,'Position') ;
ax = [0.01 ax(2) ax(1)-0.055 ax(4)] ;
%ax = [0.01 ax(2) ax(1)-0.12 ax(4)] ;   % use this for printing so that menu stays out of main plot
%clims = [ax(1) ax(1)+ax(3) ax(2) ax(2)+ax(4)] ;
clims = [0 n+1] ;
h = axes('Position',ax) ;
axis([-0.05 1.05 0 n+1])
axis off
p = NaN(length(s),1) ;
for k=1:length(s),
	if isempty(s{k}), continue, end
	p(k) = patch([0 1 1 0]',[0.1 0.1 0.9 0.9]'+n+1-k,'w') ;
end
t = text(0.5+zeros(length(s),1),n-(0:length(s)-1)+0.5,s) ;
set(t,'FontSize',12,'FontWeight','bold','HorizontalAlignment','center')
%set(t,'FontSize',11,'FontWeight','bold','HorizontalAlignment','center')

def = zeros(1,length(unique(g(g>0)))) ;
for k=1:length(def),
   kk = find(g==k) ;
   def(k) = kk(max([find(strcmp(sel{k},{s{kk}}),1),1])) ;
end

set(t(def),'Color','r')
ud.m = n-(0:length(s)-1)+0.5 ;
ud.p = p ;
ud.g = g ;
ud.t = t ;
ud.s = s ;
set(h,'UserData',ud)
axes(mainax) ;
return
