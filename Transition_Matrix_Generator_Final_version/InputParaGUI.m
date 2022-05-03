classdef InputParaGUI < handle
    properties
        spboundary;
        changeable;
        prob;
        bufferchange;
        stringoutput;
    end
    methods
        % eg: InputParaGUI("A","B",'(0)[p2*(1-r1)]{0}',0,["A","B","C","D"])
        function obj = InputParaGUI(startState,endState,labels,machine,statestrings)
            % Preprocess the input information
            changable = labels(find(labels=='(')+1:find(labels==')')-1);
            specialState = '';
            if length(changable) > 1
                specialState = changable(1:length(changable)-1);
                changable = changable(length(changable));
            end
            probability = labels(find(labels=='[')+1:find(labels==']')-1);
            deltaBuffer = labels(find(labels=='{')+1:find(labels=='}')-1);
            % Create a figure window:
            fig = uifigure('Name', 'input', 'Position',[300 300 500 500]);
            lbtitle = uilabel(fig);
            % lbtitle.Text='Transition from State'+string(char('A'+startState-1))+' to State'+string(char('A'+endState-1));
            lbtitle.Text='Transition from State "'+startState+'" to State "'+endState + '"';
            lbtitle.Position = [120,450,900,20];
            lbtitle.FontWeight = 'bold';
            lbtitle.FontSize = 16;
            lbmachine = uilabel(fig);
            if machine == 0
                lbmachine.Text = '(upstream)';
            else
                lbmachine.Text = '(downstream)';
            end
            lbmachine.Position = [210,430,900,20];
            lbChangeable = uilabel(fig);
            lbChangeable.Text='Changable';
            lbChangeable.Position = [50,400,90,20];
            
            lbChangeableExplanation = uilabel(fig);
            lbChangeableExplanation.Text='(Whether transition can';
            lbChangeableExplanation.Position = [50,380,900,20];
            lbChangeableExplanation2 = uilabel(fig);
            
            lbChangeableExplanation2.Text='happen in the boundary)';
            lbChangeableExplanation2.Position = [50,360,900,20];
            % Create a button group and radio buttons:
            bg = uibuttongroup('Parent',fig,...
                'Position',[200 375 100 50]);
            rb1 = uiradiobutton(bg,'Position',[10 30 91 15]);
            rb1.Text='No';
            rb2 = uiradiobutton(bg,'Position',[10 10 91 15]);
            rb2.Text='Yes';
            rb2.Value = 1;
            rb1.Value = 0;
            if changable == "1" || changable == ""
                rb2.Value = 1;
            else
                rb1.Value = 1;
            end
            
            lbSpecialBoundary=uilabel(fig);
            lbSpecialBoundary.Text = 'Target State';
            lbSpecialBoundary.Position = [50,310,90,20];
            lbSpecialBoundaryExp=uilabel(fig);
            lbSpecialBoundaryExp.Text = '(In the boundary)';
            lbSpecialBoundaryExp.Position = [50,290,190,20];
%             lbSBHint=uilabel(fig);
%             lbSBHint.Text = '(Empty means default)';
%             lbSBHint.Position = [10,330,200,20];
%             txSpecialBoundary = uitextarea(fig);
%             txSpecialBoundary.Position = [150,335,250,30];
%             txSpecialBoundary.Value = specialState;
            defaultTarget = 1;
            for i=1:length(statestrings)
                if (string(statestrings(i)) == specialState)
                    defaultTarget = i;
                    break;
                end
                if (string(statestrings(i)) == endState && specialState == "")
                    defaultTarget = i;
                    break;
                end
            end
            txSpecialBoundary = uidropdown(fig,...
                'Position',[200,310,250,30],...
                'Items',statestrings,...
                'Value',statestrings(defaultTarget));
            
            lb2 = uilabel(fig);
            lb2.Text = 'Probability(Symbolic)';
            lb2.Position = [50,240,191,20];
            tx1 = uitextarea(fig);
            tx1.Position = [200,240,250,30];
            tx1.Value = probability;
            if tx1.Value == ""
                tx1.Value = '0';
            end
            lb3 = uilabel(fig);
            lb3.Text = 'Buffer Change';
            lb3.Position = [50,190,191,20];
            % Create a button group and radio buttons:
            bg2 = uibuttongroup('Parent',fig,...
                'Position',[200 140 130 80]);
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
            if machine == 1
                rb4.Visible = 0;
            end
            rb5 = uiradiobutton(bg2,'Position',[10 18 91 15]);
            rb5.Text='-1';
            if string(deltaBuffer) == "-1"
                rb5.Value = 1;
            else
                rb5.Value = 0;
            end
            if machine == 0
                rb5.Visible = 0;
            end
            btn = uibutton(fig,'push', 'ButtonPushedFcn',...
                @(btn,event) obj.printinput(rb1,rb2,tx1,rb3,rb4,rb5,txSpecialBoundary,endState));
            btn.Text = 'submit';
            btn.Position = [300 50 50 25];
            
            uiwait(fig);
            
            % disp(obj)
        end
        
        function obj = printinput(obj,rb1,rb2,tx1,rb3,rb4,rb5,txSpecialBoundary,endState)
            obj.spboundary = txSpecialBoundary.Value;
            obj.changeable = 0;
            if rb1.Value == 1
                obj.changeable = 0;
            end
            if rb2.Value == 1
                obj.changeable= 1;
            end
            obj.prob = tx1.Value;
            obj.bufferchange = 0;
            if rb3.Value == 1
                obj.bufferchange = 0;
            end
            if rb4.Value == 1
                obj.bufferchange = 1;
            end
            if rb5.Value == 1
                obj.bufferchange = -1;
            end
            if string(txSpecialBoundary.Value) == endState
                obj.stringoutput="("+num2str(obj.changeable)+")"+...
                    '['+string(obj.prob)+']'+'{'+int2str(obj.bufferchange)+'}';
            else
                obj.stringoutput="("+txSpecialBoundary.Value+num2str(obj.changeable)+")"+...
                    '['+string(obj.prob)+']'+'{'+int2str(obj.bufferchange)+'}';
            end
            disp(obj.stringoutput);
            closereq();
        end
        
    end
end