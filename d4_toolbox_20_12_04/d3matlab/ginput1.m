function    [x,y,button] = ginput1(ax)

%
%
%

if nargin==0,
   ax = gca ;
end
set(gcf,'Pointer','crosshair');
set(gcf,'WindowButtonMotionFcn',@(o,e) dummy());
drawnow
if waitforbuttonpress,
   button = get(gcf,'CurrentCharacter');
else
   switch get(gcf,'SelectionType')
      case 'extend',
         button = 2 ;
      case 'alt'
         button = 3 ;
      otherwise
         button = 1 ;
   end
end
pt = get(ax, 'CurrentPoint');
x = pt(1,1) ;
y = pt(1,2) ;
set(gcf,'Pointer','arrow');
%drawnow
set(gcf,'WindowButtonMotionFcn','');
return

function dummy()
% do nothing, this is there to update the GINPUT WindowButtonMotionFcn. 
return
