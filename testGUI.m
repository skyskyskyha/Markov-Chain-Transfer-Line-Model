function testGUI(inputs)
fig = uifigure; 
fig.Position(3:4) = [440 320];

ax = uiaxes('Parent',fig,...
    'Position',[10 10 300 300]);

x = linspace(-2*pi,2*pi);
y = sin(x);
p = plot(ax,x,y);
p.Color = 'Blue';

dd = uidropdown(fig,...
    'Position',[320 160 100 22],...
    'Items',inputs,...
    'Value',inputs(1),...
    'ValueChangedFcn',@(dd,event) selection(dd,p));
end

% Create ValueChangedFcn callback:
function selection(dd,p)
val = dd.Value;
p.Color = val;
end