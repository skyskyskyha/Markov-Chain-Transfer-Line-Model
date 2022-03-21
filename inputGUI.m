function paraMatrix = inputGUI(startState,endState,labels,machine)
% Preprocess the input information
changable = labels(find(labels=='(')+1:find(labels==')')-1);
specialState = '';
if length(changable) == 2
    specialState = changable(1);
    changable = changable(2);
end
probability = labels(find(labels=='[')+1:find(labels==']')-1);
deltaBuffer = labels(find(labels=='{')+1:find(labels=='}')-1);
% Create a figure window:
fig = uifigure('Name', 'input', 'Position',[300 300 500 500]);
lbtitle = uilabel(fig);
lbtitle.Text='Transition from State'+string(char('A'+startState-1))+' to State'+string(char('A'+endState-1));
lbtitle.Position = [150,450,900,20];
lbmachine = uilabel(fig);
if machine == 0
    lbmachine.Text = '(upstream)';
else 
    lbmachine.Text = '(downstream)';
end
lbmachine.Position = [325,450,900,20];
lbl = uilabel(fig);
lbl.Text='Changable';
lbl.Position = [30,400,90,20];
% Create a button group and radio buttons:
bg = uibuttongroup('Parent',fig,...
    'Position',[150 375 100 50]);
rb1 = uiradiobutton(bg,'Position',[10 30 91 15]);
rb1.Text='0';
rb2 = uiradiobutton(bg,'Position',[10 10 91 15]);
rb2.Text='1';

if changable == "1"
    rb2.Value=1;
else
    rb1.Value=1;
end

lbSpecialBoundary=uilabel(fig);
lbSpecialBoundary.Text = 'Target State';
lbSpecialBoundary.Position = [30,350,90,20];
lbSBHint=uilabel(fig);
lbSBHint.Text = '(Empty means default)';
lbSBHint.Position = [10,330,200,20];
txSpecialBoundary = uitextarea(fig);
txSpecialBoundary.Position = [150,335,250,30];
txSpecialBoundary.Value = specialState;
lb2 = uilabel(fig);
lb2.Text = 'Probability(Symbolic)';
lb2.Position = [30,280,191,20];
tx1 = uitextarea(fig);
tx1.Position = [150,280,250,30];
tx1.Value = probability;
lb3 = uilabel(fig);
lb3.Text = 'Buffer Change';
lb3.Position = [30,180,191,20];
% Create a button group and radio buttons:
bg2 = uibuttongroup('Parent',fig,...
    'Position',[150 150 130 100]);
rb3 = uiradiobutton(bg2,'Position',[10 60 91 15]);
rb3.Text='0';
if string(deltaBuffer) == "0"
    rb3.Value = 1;
end
rb4 = uiradiobutton(bg2,'Position',[10 38 91 15]);
rb4.Text='1';
if string(deltaBuffer) == "1"
    rb4.Value = 1;
else 
    rb4.Value = 0;
end
rb5 = uiradiobutton(bg2,'Position',[10 18 91 15]);
rb5.Text='-1';
if string(deltaBuffer) == "-1"
    rb5.Value = 1;
else 
    rb5.Value = 0;
end

btn = uibutton(fig,'push', 'ButtonPushedFcn', @(btn,event) printinput(fig,btn,rb1,rb2,tx1,rb3,rb4,rb5,txSpecialBoundary));
btn.Text = 'submit';
btn.Position = [300 50 50 25];

disp('This text prints immediately');
uiwait(fig);
getappdata(fig,'spboundary');
disp('This text prints after you click submit');
end

function stringoutput=printinput(fig,btn,rb1,rb2,tx1,rb3,rb4,rb5,txSpecialBoundary)
    changeable = 0;
    if rb1.Value == 1
        changeable = 0;
    end
    if rb2.Value == 1
        changeable= 1;
    end
    prob = tx1.Value;
%     temp = string(prob);
%     temp = str2double(temp);
%     if (temp<0.0 || temp>1.0)
%         disp('wrong probability')
%         return;
%     end
    bufferchange = 0;
    if rb3.Value == 1
        bufferchange = 0;
    end
     if rb4.Value == 1
        bufferchange = 1;
     end
     if rb5.Value == 1
        bufferchange = -1;
     end
    stringoutput=""; 
    stringoutput="("+txSpecialBoundary.Value+num2str(changeable)+")"+'{'+string(prob)+'}'+'['+int2str(bufferchange)+']';
    disp(stringoutput);
    setappdata(fig,'spboundary',txSpecialBoundary.Value);
    getappdata(fig,'spboundary');
    closereq();
end