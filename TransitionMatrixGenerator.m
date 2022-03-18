classdef TransitionMatrixGenerator
    %TRANSITIONMATRIXGENERATOR Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function result = sortstates(states)
            if length(states) < 2
                result = states;
                return;
            end
            result = [];
            
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
        end
        
        function m = getProbabilityMatrix(stateFlowChart)
            % Get a list of states with names in alphanumeric order, then
            % create m such that m(row, col) represents probability of
            % moving from col to row
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            N = length(states);
            m = zeros(N);
            m = sym(m);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    prob = t.LabelString;
                    % disp(prob)
                    prob = prob(find(prob=='[')+1:find(prob==']')-1);
                    if prob == ""
                        prob = "0";
                    end
                    m(i, j) = str2sym(prob);
                end
            end
        end
        
        function b = getBufferMatrix(stateFlowChart)
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            b = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    change=change(find(change=='{')+1:find(change=='}')-1);
                    change=str2double(change);
                    b(i, j) = change;
                end
            end
        end
        
        function c = getConditionMatrix(stateFlowChart)
            
            % Add logic for arbitrary buffer condition in the future.
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            c = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    change=change(find(change=='(')+1:find(change==')')-1);
                    if (strlength(change) == 0)
                        continue;
                    end
                    if (strlength(change) == 1)
                        change=str2double(change);
                        c(i, j) = change;
                    else
                        temp = char(change);
                        c(i,j) = temp(end)-'0';
                    end
                end
            end
        end
        
        function sub = getSpecialBoundary(stateFlowChart, stateNameMap)
            
            % Add logic for arbitrary buffer condition in the future.
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            sub = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    change=change(find(change=='(')+1:find(change==')')-1);
                    if (strlength(change) == 0)
                        continue;
                    end
                    if (strlength(change) == 1)
                        sub(i,j)=i;
                    else
                        temp = char(change);
                        temp = temp(1:length(temp)-1);
                        sub(i,j) = stateNameMap(temp);
                    end
                end
            end
        end
        
        function names = getStateNames(stateFlowChart)
            
            % Extract names of the states and index them into a Map
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            names = containers.Map;
            result = [];
            count = 1;
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                names(min) = count;
                count = count + 1;
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
        end
        
        function indexes = getStateIndexes(stateFlowChart)
            
            % Extract names of the states and index them into a Map
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            indexes = containers.Map;
            result = [];
            count = 1;
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                indexes(char(count+'0')) = min;
                count = count + 1;
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
        end
        
        function namecells = getStateNameCells(stateFlowChart)
            
            % Extract names and insert into a cell array
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            namecells = {};
            result = [];
            count = 1;
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                namecells{end+1} = min;
                count = count + 1;
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
        end
        
        function obj = getManualInput(stateFlowChart)
            % Add logic for arbitrary buffer condition in the future.
            
            states = find(stateFlowChart, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            
            states = result;
            
            N = length(states);
            sub = zeros(N);
            for i=1:N
                for j=1:N
                    t = find(stateFlowChart, '-isa',...
                        'Stateflow.Transition', 'Source', states(j),...
                        'Destination', states(i));
                    if isempty(t)
                        continue
                    end
                    change=t.LabelString;
                    
                end
            end
        end
        
    end
    
    
    
    
    properties
        DEBUG = 1; % Set to 1 to skip the GUIs
        m1;
        m2;
        num1;
        num2;
        m1_to_num1;
        m2_to_num2;
        b1;
        b2;
        c1; % Conditional connection matrices
        c2;
        op1; % Whether state is operable
        op2;
        sub1;
        sub2;
        s1Name; % Map of name, key is name and value is index
        s2Name;
        n1Name; % Map of name, key is index and value is name
        n2Name;
        stateNameCells1; % An array of states' names
        stateNameCells2;
        bufCap;
        svm;
        T;      % Numeric result
        Tf;     % Function for evaluation
        Ts;     % Symbolic result
        Tn; % Numeric Matrix after substitution into Tf
        optimalFunc; % The optimalization function we currently have
        groups;
        spboundary; % Special Boundary when machine is starved or blocked
        changeable; % Whether the transfer can happen when machine is starved or blocked
        prob; % Probability of transfer in symbolic
        bufferchange; % The change of buffer, in {-1,0,1}
        validProb; % Whether the sum of probability is 1
    end
    
    methods
        function obj = TransitionMatrixGenerator(m1StateFlow,m2StateFlow,bufCap)
            %TRANSITIONMATRIXGENERATOR Construct an instance of this class
            %   Detailed explanation goes here
            if (obj.DEBUG ~= 1)
                InitMatrix = InitGUI();
                tempMacName = string(InitMatrix.machineName);
                tempUpMac = string(InitMatrix.upStream);
                tempDownMac = string(InitMatrix.downStream);
                m1StateFlow = char(tempMacName+"/"+tempUpMac);
                m2StateFlow = char(tempMacName+"/"+tempDownMac);
                bufCap = str2num(cell2mat(InitMatrix.bufCap));
            end
            %tic
            rt = sfroot;
            if (obj.DEBUG == 1)
                obj.bufCap=bufCap;
            end
            m1StateFlow = find(rt, '-isa', 'Stateflow.Chart',...
                'Path', m1StateFlow);
            m2StateFlow = find(rt, '-isa', 'Stateflow.Chart',...
                'Path', m2StateFlow);
            
            obj.s1Name = obj.getStateNames(m1StateFlow);
            obj.s2Name = obj.getStateNames(m2StateFlow);
            obj.n1Name = obj.getStateIndexes(m1StateFlow);
            obj.n2Name = obj.getStateIndexes(m2StateFlow);
            obj.stateNameCells1 = obj.getStateNameCells(m1StateFlow);
            obj.stateNameCells2 = obj.getStateNameCells(m2StateFlow);
            obj.m1 = obj.getProbabilityMatrix(m1StateFlow);
            obj.m2 = obj.getProbabilityMatrix(m2StateFlow);
            obj.b1 = obj.getBufferMatrix(m1StateFlow);
            obj.b2 = obj.getBufferMatrix(m2StateFlow);
            obj.bufCap = bufCap;
            obj.c1 = obj.getConditionMatrix(m1StateFlow);
            obj.c2 = obj.getConditionMatrix(m2StateFlow);
            obj.c1(isnan(obj.c1)) = 0;
            obj.c2(isnan(obj.c2)) = 0;
            obj.sub1 = obj.getSpecialBoundary(m1StateFlow, obj.s1Name);
            obj.sub2 = obj.getSpecialBoundary(m2StateFlow, obj.s2Name);
            % obj = obj.getManualInput(m1StateFlow);
            states = find(m1StateFlow, '-isa', 'Stateflow.State');
            
            result = [];
            while ~isempty(states)
                min = states(1).Name;
                minInd = 1;
                for i=2:length(states)
                    if string(states(i).Name) < string(min)
                        min = states(i).Name;
                        minInd = i;
                    end
                end
                result = [result; states(minInd)];
                states(minInd) = [];
            end
            if (obj.DEBUG == 2)
                % Pop up GUI for modification
                states = result;
                for i=1:length(obj.c1)
                    for j=1:length(obj.c1)
                        t = find(m1StateFlow, '-isa',...
                            'Stateflow.Transition', 'Source', states(j),...
                            'Destination', states(i));
                        if isempty(t)
                            continue
                        end
                        change=t.LabelString;
                        startState = obj.n1Name(char(j+'0'));
                        startState = string(startState);
                        endState = obj.n1Name(char(i+'0'));
                        endState = string(endState);
                        paraMatrix = InputParaGUI(startState,...
                            endState,change,0,obj.stateNameCells1);
                        % disp('matrix:')
                        disp(paraMatrix)
                        if strlength(string(paraMatrix.spboundary)) >= 0
                            temp = string(paraMatrix.spboundary);
                            temp = convertStringsToChars(temp);
                            temp = obj.s1Name(temp);
                            obj.sub1(i,j) = temp;
                        end
                        obj.c1(i,j) = paraMatrix.changeable;
                        obj.m1(i,j) = str2sym(paraMatrix.prob);
                        obj.b1(i,j) = paraMatrix.bufferchange;
                        t.labelString = paraMatrix.stringoutput;
                    end
                end
                
                states = find(m2StateFlow, '-isa', 'Stateflow.State');
                
                result = [];
                while ~isempty(states)
                    min = states(1).Name;
                    minInd = 1;
                    for i=2:length(states)
                        if string(states(i).Name) < string(min)
                            min = states(i).Name;
                            minInd = i;
                        end
                    end
                    result = [result; states(minInd)];
                    states(minInd) = [];
                end
                
                states = result;
                for i=1:length(obj.c2)
                    for j=1:length(obj.c2)
                        t = find(m2StateFlow, '-isa',...
                            'Stateflow.Transition', 'Source', states(j),...
                            'Destination', states(i));
                        if isempty(t)
                            continue
                        end
                        change=t.LabelString;
                        startState = obj.n2Name(char(j+'0'));
                        startState = string(startState);
                        endState = obj.n2Name(char(i+'0'));
                        endState = string(endState);
                        paraMatrix = InputParaGUI(startState,...
                            endState,change,1,obj.stateNameCells2);
                        % disp('matrix:')
                        disp(paraMatrix)
                        if strlength(string(paraMatrix.spboundary)) >= 0
                            temp = string(paraMatrix.spboundary);
                            temp = convertStringsToChars(temp);
                            temp = obj.s2Name(temp);
                            obj.sub2(i,j) = temp;
                        end
                        obj.c2(i,j) = paraMatrix.changeable;
                        obj.m2(i,j) = str2sym(paraMatrix.prob);
                        obj.b2(i,j) = paraMatrix.bufferchange;
                        t.labelString = paraMatrix.stringoutput;
                    end
                    
                end
            end
            obj.op1 = zeros(length(obj.c1),1);
            for i=1:length(obj.c1)
                sum=0;
                for j=1:length(obj.c1)
                    sum=sum+obj.c1(j,i);
                end
                if (sum==1)
                    % 1 means operable state, which can't fail while starve
                    % or block
                    obj.op1(i)=1;
                else
                    obj.op1(i)=0;
                end
            end
            obj.op2 = zeros(length(obj.c2),1);
            for i=1:length(obj.c2)
                sum=0;
                for j=1:length(obj.c2)
                    sum=sum+obj.c2(j,i);
                end
                if (sum==1)
                    % 1 means operable state, which can't fail while starve
                    % or block
                    obj.op2(i)=1;
                else
                    obj.op2(i)=0;
                end
            end
            %toc
            obj.T = [];
            obj = obj.verifySumProb();
            if obj.validProb == -1
                return;
            end
            tic
            obj = obj.generateOptimizeFunction();
            toc
            %obj.mainGUI(0);
        end
        
        function obj = verifySumProb(obj)
            % Verify the sum probability of every state is one
            sumProb=sum(obj.m1);
            sumProb=simplify(sumProb);
           
            try
                for i=1:length(sumProb)
                    for j=1:20
                        sumProb(i)=subs(sumProb(i),10);
                    end
                end
                sumProb=double(sumProb);
            catch ME
                obj.validProb = -1;
                disp("The sum of out probability is not 1");
                return;
            end
            for i=1:length(obj.c1)
                if ~sumProb(i)==1
                    obj.validProb = -1;
                    disp("The sum of out probability is not 1");
                    return;
                end
            end
            sumProb=sum(obj.m2);
            sumProb=simplify(sumProb);
            try
                for i=1:length(sumProb)
                    for j=1:20
                        sumProb(i)=subs(sumProb(i),10);
                    end
                end
                sumProb=double(sumProb);
            catch ME
                obj.validProb = -1;
                disp("The sum of out probability is not 1");
                return;
            end
            for i=1:length(obj.c2)
                if ~sumProb(i)==1
                    obj.validProb = -1;
                    disp("The sum of out probability is not 1");
                    return;
                end
            end
        end
        
        function mainGUI(obj, placeholder)
            % Create a figure window:
            fig = uifigure('Name', 'main', 'Position',[300 300 500 500]);
            lbtitle = uilabel(fig);
            lbtitle.Text='Transition Matrix Generator';
            lbtitle.Position = [120,450,900,20];
            lbtitle.FontWeight = 'bold';
            lbtitle.FontSize = 16;
            
            lbNumMat = uilabel(fig);
            lbNumMat.Text='Generate matrix with numeric values';
            lbNumMat.Position = [50,400,900,20];
            
            lbNumMatExp = uilabel(fig);
            lbNumMatExp.Text='Example: [0.05,0.1],[0.07,0.09]';
            lbNumMatExp.Position = [50,370,900,20];
            
            txNumMat = uitextarea(fig);
            txNumMat.Position = [50,340,250,30];
            txNumMat.Value = '';
            
            btn = uibutton(fig,'push', 'ButtonPushedFcn',...
                @(btn,event) obj.handleNumMat(txNumMat));
            btn.Text = 'submit';
            btn.Position = [400 320 50 25];
            
            lbOptFunc=uilabel(fig);
            lbOptFunc.Text = 'Generate new optimization function';
            lbOptFunc.Position = [50,240,900,20];
            
            lbOptFuncExp=uilabel(fig);
            lbOptFuncExp.Text = 'Example: (-1,-1,0.07,0.09)';
            lbOptFuncExp.Position = [50,210,900,20];
            
            txOptFunc = uitextarea(fig);
            txOptFunc.Position = [50,180,250,30];
            txOptFunc.Value = '';
            
            btn2 = uibutton(fig,'push', 'ButtonPushedFcn',...
                @(btn,event) obj.handleOptFunc(txOptFunc));
            btn2.Text = 'submit';
            btn2.Position = [400 160 50 25];
            %uiwait(fig);
        end
        
        function obj = handleNumMat(obj, txNumMat)
            temp = txNumMat.Value;
            temp = char(temp);
            temp2 = temp(find(temp=='[')+1:find(temp==']')-1);
            temp2 = char(temp2);
            temp2 = split(temp2, ',');
            temp2 = char(temp2);
            temp2 = str2num(temp2);
            temp2 = temp2.';
            temp3 = temp(find(temp==']')+1:size(temp,2));
            temp3 = temp3(find(temp3=='[')+1:find(temp3==']')-1);
            temp3 = char(temp3);
            temp3 = split(temp3, ',');
            temp3 = char(temp3);
            temp3 = str2num(temp3);
            temp3 = temp3.';
            obj = obj.myFunc(obj.bufCap,temp2,temp3);
            disp('Finish generating numeric matrix');
        end
        
        function obj = handleOptFunc(obj, txOptFunc)
            temp = txOptFunc.Value;
            temp = char(temp);
            temp = temp(find(temp=='(')+1:find(temp==')')-1);
            temp = split(temp, ',');
            temp = char(temp);
            temp = str2num(temp);
            temp = temp.';
            %temp = num2cell(temp);
            obj = obj.generateNewOptimals(temp);
        end
        
        function paraMatrix = InputParaGUI(obj,startState,endState,labels,machine)
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
            
            btn = uibutton(fig,'push', 'ButtonPushedFcn', @(btn,event) obj.printinput(rb1,rb2,tx1,rb3,rb4,rb5,txSpecialBoundary));
            btn.Text = 'submit';
            btn.Position = [300 50 50 25];
            
            uiwait(fig);
            paraMatrix = [obj.spboundary,obj.changeable,obj.prob,obj.bufferchange];
            disp(obj)
        end
        
        function obj = printinput(obj,rb1,rb2,tx1,rb3,rb4,rb5,txSpecialBoundary)
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
            stringoutput="("+txSpecialBoundary.Value+num2str(obj.changeable)+")"+...
                '{'+string(obj.prob)+'}'+'['+int2str(obj.bufferchange)+']';
            % disp(stringoutput);
            closereq();
        end
        
        function obj = myFunc(obj, N, varargin)
            obj = obj.setBufferNumbers(N);
            obj = obj.substituteValuesDirectly_m1(cell2mat(varargin(1)));
            obj = obj.substituteValuesDirectly_m2(cell2mat(varargin(2)));
            obj = obj.generateTransitionMatrixbyNum();
        end
        
        function obj = setBufferNumbers(obj, bufCap)
            obj.bufCap = bufCap;
        end
        
        function obj = substituteValuesDirectly_m1(obj, varargin)
            in = num2cell(cat(2, varargin{:}));
            obj.m1_to_num1 = matlabFunction(obj.m1);
            obj.num1 = obj.m1_to_num1(in{:});
        end
        
        function obj = substituteValuesDirectly_m2(obj, varargin)
            in = num2cell(cat(2, varargin{:}));
            obj.m2_to_num2 = matlabFunction(obj.m2);
            obj.num2 = obj.m2_to_num2(in{:});
        end
        
        function obj = generateNewOptimals(obj,varargin)
            % if the probability is -1, means it's a varaible to be
            % optimized, otherwise it's a fixed varaible
            % it's a one-direction function, if you fixed a varaible, it
            % will be the fixed value for any further input and you cannot
            % change it again
            
            % Example:  obj=obj.generateNewOptimals(0.1,0.1,-1,-1)
            if (length(varargin)==1)
                varargin=cell2mat(varargin);
                varargin=num2cell(varargin);
            end
            paraNameString = func2str(obj.optimalFunc);
            paraNames = paraNameString(find(paraNameString=='(')+1:find(paraNameString==')')-1);
            paraNames = split(paraNames,',');
            probs = zeros(1,length(varargin));
            for i=1:length(varargin)
                probs(i)=cell2mat(varargin(i));
            end
            for i=1:length(probs)
                if probs(i)~=-1
                    para = char(paraNames(i));
                    para_sym = str2sym(para);
                    [r,c] = size(obj.Ts);
                    for j=1:r
                        for k=1:c
                            if has(obj.Ts(j,k),para)
                                obj.Ts(j,k)=subs(obj.Ts(j,k),para_sym,probs(i));
                            end
                        end
                    end
                    
                end
            end
            obj.Tf = matlabFunction(obj.Ts);
            obj.optimalFunc = obj.Tf;
            disp('Finishing generating new optimize function handler');
        end
        
        function state = findFinalState(obj,buf,m1,m2)
            state = -1;
            for i=1:length(obj.svm)
                if (buf==obj.svm(i,1) && m1==obj.svm(i,2) && m2==obj.svm(i,3))
                    state=i;
                    break;
                end
            end
        end
        
        function obj = generateTransitionMatrixbyNum(obj)
            MAX = obj.bufCap;
            obj.svm = obj.genStateVecMatrix();
            obj = obj.genGroups();
            obj = obj.pruneSVM_tarjan();
            dim = length(obj.svm);
            obj.T = zeros(dim);
            disp ("Generating numeric transition matrix directly" )
            for i=1:dim
                for j=1:dim
                    target = j;
                    bufStart = obj.svm(i, 1);
                    bufStop  = obj.svm(j, 1);
                    
                    m1Start  = obj.svm(i, 2);
                    m1Stop   = obj.svm(j, 2);
                    m2Start  = obj.svm(i, 3);
                    m2Stop   = obj.svm(j, 3);
                    
                    t1 = obj.b1(m1Stop, m1Start);
                    t2 = obj.b2(m2Stop, m2Start);
                    
                    p1 = obj.num1(m1Stop, m1Start);
                    p2 = obj.num2(m2Stop, m2Start);
                    
                    % if machine2 is starved, m2Start to m2Stop may happen
                    % even num is 0 because it may comes from other state
                    if bufStart == 0
                        temp = 0;
                        for k=1:length(obj.sub2)
                            if obj.sub2(k, m2Start) == m2Stop
                                temp = temp + obj.num2(k, m2Start);
                            end
                        end
                        p2 = temp;
                    end
                    
                    % check whether we are going to another state
                    if bufStart == 0 && obj.sub2(m2Stop, m2Start) ~=  m2Stop && obj.c2(m2Start, m2Stop)
                        target = obj.findFinalState(bufStop, m1Stop, obj.sub2(m2Stop, m2Start));
                    end
                    % if the machine2 is starved, we need to check whether
                    % it can reach the state
                    if bufStart == 0 && m2Start == m2Stop && obj.op2(m2Start) == 1
                        t2 = 0;
                        p2 = 1;
                    else
                        if bufStart == 0 && m2Start~=m2Stop && obj.op2(m2Start) == 1
                            p2 = 0;
                        end
                    end
                    
                    % if machine1 is blockd, m1Start to m1Stop may happen
                    % even num is 0 because it may comes from other state
                    if bufStart == MAX
                        temp = 0;
                        for k=1:length(obj.sub1)
                            if obj.sub1(k, m1Start) == m1Stop
                                temp = temp + obj.num1(k, m1Start);
                            end
                        end
                        p1 = temp;
                    end
                    
                    % check whether we are going to another state
                    if bufStart == MAX && obj.sub1(m1Stop, m1Start) ~= m1Stop && obj.c1(m1Start, m1Stop)
                        target = obj.findFinalState(bufStop, obj.sub1(m1Stop, m1Start), m2Stop);
                    end
                    % if the machine1 is blocked, we need to check whether
                    % it can reach the state
                    if bufStart == MAX && m1Start == m1Stop  && obj.op1(m1Start) == 1
                        t1 = 0;
                        p1 = 1;
                    else
                        if bufStart == MAX && m1Start ~= m1Stop  && obj.op1(m1Start) == 1
                            p1 = 0;
                        end
                    end
                    
                    if (bufStop-bufStart) ~= t1+t2
                        continue;
                    end
                    
                    obj.T(j, i) = p1*p2;
                end
            end
        end
        
        function obj = generateTransitionMatrix(obj, bufCap)
            MAX = obj.bufCap;
            obj.svm = obj.genStateVecMatrix();
            obj = obj.genGroups();
            obj = obj.pruneSVM_tarjan();
            dim = length(obj.svm);
            obj.Ts = zeros(dim);
            obj.Ts = sym(obj.Ts);
            disp ("Generating symbolic matrix" )
            startindex = zeros(MAX,1);
            for i=2:dim
                if (obj.svm(i,1)~=obj.svm(i-1,1))
                    startindex(obj.svm(i,1))=i;
                end
            end
            count=0;
            for i=1:dim
                % To improve speed, we only look at the states which buffer
                % capacity difference not exceed 1
                bufi = obj.svm(i, 1);
                startj=0;
                if (bufi==0||bufi==1)
                    startj=1;
                else
                    startj=startindex(bufi-1);
                end
                endj=0;
                if (bufi==MAX||bufi==MAX-1)
                    endj=dim;
                else 
                    endj=startindex(bufi+2)-1;
                end
                for j=startj:endj
                    %tic
                    count=count+1;
                    target = j;
                    bufStart = obj.svm(i, 1);
                    bufStop  = obj.svm(j, 1);
                    if (bufStart-bufStop>1 || bufStop-bufStart>1)
                        continue;
                    end
                    m1Start  = obj.svm(i, 2);
                    m1Stop   = obj.svm(j, 2);
                    m2Start  = obj.svm(i, 3);
                    m2Stop   = obj.svm(j, 3);
                    
                    t1 = obj.b1(m1Stop, m1Start);
                    t2 = obj.b2(m2Stop, m2Start);
                    
                    p1 = obj.m1(m1Stop, m1Start);
                    p2 = obj.m2(m2Stop, m2Start);
                    
                    % if machine2 is starved, m2Start to m2Stop may happen
                    % even num is 0 because it may comes from other state
                    
                    % comment to improve speed for testing, must umcomment
                    % after that!
                    
                    if bufStart == 0
                        temp = 0;
                        for k=1:length(obj.sub2)
                            if obj.sub2(k, m2Start) == m2Stop
                                temp = temp + obj.m2(k, m2Start);
                            end
                        end
                        p2 = temp;
                    end
                    
                    % check whether we are going to another state
                    if bufStart == 0 && obj.sub2(m2Stop, m2Start) ~=  m2Stop && obj.c2(m2Start, m2Stop)
                        target = obj.findFinalState(bufStop, m1Stop, obj.sub2(m2Stop, m2Start));
                    end
                    % if the machine2 is starved, we need to check whether
                    % it can reach the state
                    if bufStart == 0 && m2Start == m2Stop && obj.op2(m2Start) == 1
                        t2 = 0;
                        p2 = 1;
                    else
                        if bufStart == 0 && m2Start~=m2Stop && obj.op2(m2Start) == 1
                            p2 = 0;
                        end
                    end
                    
                    % if machine1 is blockd, m1Start to m1Stop may happen
                    % even num is 0 because it may comes from other state
                    
                    % comment for speed, remember to umcomment!
                    if bufStart == MAX
                        temp = 0;
                        for k=1:length(obj.sub1)
                            if obj.sub1(k, m1Start) == m1Stop
                                temp = temp + obj.m1(k, m1Start);
                            end
                        end
                        p1 = temp;
                    end
                    
                    % check whether we are going to another state
                    if bufStart == MAX && obj.sub1(m1Stop, m1Start) ~= m1Stop && obj.c1(m1Start, m1Stop)
                        target = obj.findFinalState(bufStop, obj.sub1(m1Stop, m1Start), m2Stop);
                    end
                    % if the machine1 is blocked, we need to check whether
                    % it can reach the state
                    if bufStart == MAX && m1Start == m1Stop  && obj.op1(m1Start) == 1
                        t1 = 0;
                        p1 = 1;
                    else
                        if bufStart == MAX && m1Start ~= m1Stop  && obj.op1(m1Start) == 1
                            p1 = 0;
                        end
                    end
                    
                    % Check delta buffer matches
                    if (bufStop-bufStart) ~= t1+t2
                        % Some corner cases in the boundary
                        if (bufStop==0&&bufStart==0&&t1+t2==-1||...
                            bufStop==MAX&&bufStart==MAX&&t1+t2==1||...
                            bufStop==1&&bufStart==0&&t1==1&&t2==-1||...
                            bufStop==MAX-1&&bufStart==MAX&&t1==1&&t2==-1)
                            % do nothing
                        else
                        continue;
                        end
                    end
                    
                    if (bufStop-bufStart) == t1+t2
                        % Even delta buffer matches, the corner cases may
                        % happen in the boundary
                        if (bufStop==0&&bufStart==0&&t1==1&&t2==-1||...
                            bufStop==MAX&&bufStart==MAX&&t1==1&&t2==-1)
                            continue
                        end
                    end
                    
                    obj.Ts(j, i) = p1*p2;
                    %toc
                end
            end
            % disp( "Generating matlabFunction from T" )
            disp(count);
        end
        
        function obj = generateOptimizeFunction(obj)
            obj = obj.generateTransitionMatrix(obj.bufCap);
            obj.Tf = matlabFunction(obj.Ts);
            % global optimalFunc;
            obj.optimalFunc = obj.Tf;
        end
        
        function svm = genStateVecMatrix(obj)
            m1Dim = length( obj.m1 );
            m2Dim = length( obj.m2 );
            
            svm = zeros((obj.bufCap+1)*m1Dim*m2Dim, 3);
            ind = 1;
            for i = 1:(obj.bufCap+1)
                for j = 1:m1Dim
                    for k = 1:m2Dim
                        svm(ind, 1) = i-1;
                        svm(ind, 2) = j;
                        svm(ind, 3) = k;
                        ind = ind + 1;
                    end
                end
            end
        end
        
        function obj=pruneSVM_tarjan(obj)
            tic
            obj.svm = obj.genStateVecMatrix();
            m1Dim = length(obj.m1);
            m2Dim = length(obj.m2);
            oneLine = m1Dim*m2Dim;
            twoLines = m1Dim*m2Dim*2;
            threeLines = m1Dim*m2Dim*3;
            
            % prune lower boundary equations
            matlabQueue = zeros(threeLines,1);
            vectorMatrix = zeros(threeLines, 5);
            for i=1:threeLines
                vectorMatrix(i,1)=i;
                vectorMatrix(i,2)=obj.svm(i,1);
                vectorMatrix(i,3)=obj.svm(i,2);
                vectorMatrix(i,4)=obj.svm(i,3);
                % 0 means unused,1 means used
                vectorMatrix(i,5)=0;
            end
            queueHead=1;
            queueTail=1;
            for i=twoLines+1:threeLines
                matlabQueue(queueTail)=i;
                % set this as visited
                vectorMatrix(i,5)=1;
                queueTail = queueTail+1;
            end
            
            while (queueHead<queueTail)
                curIndex=matlabQueue(queueHead);
                curState=vectorMatrix(curIndex:curIndex,2:4);
                curBuffer=curState(1);
                lowerBuffer=0;
                upperBuffer=2;
                if (curBuffer==0)
                    % search for buffer is 0 or 1
                    lowerBuffer=0;
                    upperBuffer=1;
                else
                    if (curBuffer==1)
                        % search for buffer 0 or 1
                        lowerBuffer=0;
                        upperBuffer=1;
                    else
                        if (curBuffer==2)
                            lowerBuffer=1;
                            upperBuffer=1;
                        end
                    end
                end
                for desiredBuffer=lowerBuffer:upperBuffer
                    for m1State=1:m1Dim
                        for m2State=1:m2Dim
                            indexVector=desiredBuffer*m1Dim*m2Dim+(m1State-1)*m2Dim+m2State;
                            if (vectorMatrix(indexVector,5)==1)
                                continue;
                            end
                            desiredState=vectorMatrix(indexVector:indexVector,2:4);
                            bufChange=desiredBuffer-curBuffer;
                            if (obj.isAdjacent(bufChange,curState,desiredState))
                                matlabQueue(queueTail)=indexVector;
                                queueTail=queueTail+1;
                                vectorMatrix(indexVector,5)=1;
                            end
                        end
                    end
                end
                queueHead=queueHead+1;
            end
            
            prunedSVM=zeros(size(obj.svm,1),3);
            index=0;
            for i=1:size(vectorMatrix,1)
                if (vectorMatrix(i,5)==1&&vectorMatrix(i,2)~=2)
                    index=index+1;
                    prunedSVM(index,1:3)=vectorMatrix(i:i,2:4);
                end
            end
            % copy internal states from 2 to N-2
            internalStatesSize=(obj.bufCap-3)*m1Dim*m2Dim;
            prunedSVM(index+1:index+internalStatesSize,1:3)=obj.svm(twoLines+1:(obj.bufCap-1)*oneLine,1:3);
            index=index+internalStatesSize;
            % prune upper boundary equations
            matlabQueue = zeros(threeLines,1);
            vectorMatrix = zeros(threeLines, 5);
            start=(obj.bufCap-2)*m1Dim*m2Dim;
            for i=1:threeLines
                vectorMatrix(i,1)=start+i;
                vectorMatrix(i,2)=obj.svm(start+i,1);
                vectorMatrix(i,3)=obj.svm(start+i,2);
                vectorMatrix(i,4)=obj.svm(start+i,3);
                % 0 means unused,1 means used
                vectorMatrix(i,5)=0;
            end
            queueHead=1;
            queueTail=1;
            for i=1:oneLine
                matlabQueue(queueTail)=i;
                % set this as visited
                vectorMatrix(i,5)=1;
                queueTail = queueTail+1;
            end
            
            while (queueHead<queueTail)
                curIndex=matlabQueue(queueHead);
                curState=vectorMatrix(curIndex:curIndex,2:4);
                curBuffer=curState(1);
                lowerBuffer=obj.bufCap-2;
                upperBuffer=obj.bufCap;
                if (curBuffer==obj.bufCap-2)
                    % search for buffer is bufCap-1
                    lowerBuffer=obj.bufCap-1;
                    upperBuffer=obj.bufCap-1;
                else
                    if (curBuffer==obj.bufCap-1)
                        % search for buffer bufCap-1 or bufCap
                        lowerBuffer=obj.bufCap-1;
                        upperBuffer=obj.bufCap;
                    else
                        if (curBuffer==obj.bufCap)
                            lowerBuffer=obj.bufCap-1;
                            upperBuffer=obj.bufCap;
                        end
                    end
                end
                for desiredBuffer=lowerBuffer:upperBuffer
                    for m1State=1:m1Dim
                        for m2State=1:m2Dim
                            indexVector=(desiredBuffer+2-obj.bufCap)*m1Dim*m2Dim+(m1State-1)*m2Dim+m2State;
                            if (vectorMatrix(indexVector,5)==1)
                                continue;
                            end
                            desiredState=vectorMatrix(indexVector:indexVector,2:4);
                            bufChange=desiredBuffer-curBuffer;
                            if (obj.isAdjacent(bufChange,curState,desiredState))
                                matlabQueue(queueTail)=indexVector;
                                queueTail=queueTail+1;
                                vectorMatrix(indexVector,5)=1;
                            end
                        end
                    end
                end
                queueHead=queueHead+1;
            end
            
            for i=1:size(vectorMatrix,1)
                if (vectorMatrix(i,5)==1&&vectorMatrix(i,2)~=obj.bufCap-2)
                    index=index+1;
                    prunedSVM(index,1:3)=vectorMatrix(i,2:4);
                end
            end
            obj.svm=prunedSVM(1:index,1:3);
        end
        
        function obj=pruneSVM(obj)
            obj.svm = obj.genStateVecMatrix();
            m1Dim = length(obj.m1);
            m2Dim = length(obj.m2);
            
            maxes = obj.svm(obj.bufCap*m1Dim*m2Dim+1:(obj.bufCap+1)*m1Dim*m2Dim, :);
            maxesLessOne = obj.svm((obj.bufCap-1)*m1Dim*m2Dim+1:(obj.bufCap)*m1Dim*m2Dim, :);
            maxesLessTwo = obj.svm((obj.bufCap-2)*m1Dim*m2Dim+1:(obj.bufCap-1)*m1Dim*m2Dim, :);
            newMaxesLessOne = obj.pruneFrom(1, maxesLessOne, maxesLessTwo);
            
            newMaxesLessOne = obj.expand(0, newMaxesLessOne, maxesLessOne);
            newMaxes = obj.pruneFrom(1, maxes, newMaxesLessOne);
            
            change = true;
            while change
                change   = false;
                oldLO = newMaxesLessOne;
                oldM = newMaxes;
                newMaxesLessOne = obj.expand(0, newMaxesLessOne, maxesLessOne);
                newMaxes = obj.pruneFrom(1, maxes, newMaxesLessOne);
                newMaxesLessOne  = [newMaxesLessOne; obj.expand(1, newMaxes, maxesLessOne)];
                newMaxesLessOne(newMaxesLessOne(:, 1) == obj.bufCap, :) = [];
                newMaxesLessOne = unique(newMaxesLessOne, 'rows');
                
                if ~isequal(oldLO, newMaxesLessOne) || ~isequal(oldM, newMaxes)
                    change = true;
                end
            end
            
            obj.svm((obj.bufCap-1)*m1Dim*m2Dim+1:(obj.bufCap+1)*m1Dim*m2Dim, :) = [];
            obj.svm = [obj.svm; newMaxesLessOne; newMaxes];
            
            zeros = obj.svm(1:m1Dim*m2Dim, :);
            ones  = obj.svm(m1Dim*m2Dim+1:2*m1Dim*m2Dim, :);
            twos  = obj.svm(2*m1Dim*m2Dim+1:3*m1Dim*m2Dim, :);
            
            newOnes = obj.pruneFrom(-1, ones, twos);
            newZeros = obj.pruneFrom(-1, zeros, newOnes);
            
            change = true;
            while change
                change   = false;
                oldO = newOnes;
                oldZ = newZeros;
                newOnes  = obj.expand(0, newOnes, ones);
                newZeros = obj.pruneFrom(-1, zeros, newOnes);
                newOnes  = [newOnes; obj.expand(1, newZeros, ones)];
                newOnes(newOnes(:, 1) == 0, :) = [];
                newOnes = unique(newOnes, 'rows');
                
                if ~isequal(oldO, newOnes) || ~isequal(oldZ, newZeros)
                    change = true;
                end
            end
            
            obj.svm(1:2*m1Dim*m2Dim, :) = [];
            obj.svm = [newZeros; newOnes; obj.svm];
            
            obj.svm = unique(obj.svm, 'rows');
        end
        
        
        function mat = substituteValues(obj, varargin)
            % REQUIRES: Vectors input must be in alphanumeric order,
            % grouped by the first letter of each variable, for example
            % substituteValues([p1, p2, ..., pn], [q1, q2, ..., qm], ...)
            % is acceptable input.
            % MODIFIES: obj
            % EFFECTS: Calls genTransitionMatrix after substituting the
            % values provided in the vectors. Produces the transition
            % matrix of these respective values.
            
            
            % Error checking comes first. This can go wrong in some ways,
            % so let's make a list.
            % 1. Not enough input arguments
            % 2. Provided arrays aren't of respective sizes
            
            % So we need to have some expectation of what our input looks
            % like. Let's create a function for that.
            
            % Check number of arguments is correct
            %             if (nargin-1) ~= length(keys(obj.groups))
            %                 disp("Error: incorrect number of input arguments")
            %                 return;
            %             end
            %
            %             % Check each vector has the correct number of keys
            %             k = keys(obj.groups);
            %             for i=1:length(k)
            %                 if length(obj.groups(k{i})) ~= length(varargin{i})
            %                     disp("Error: incorrect length of vector " + i)
            %                     return;
            %                 end
            %             end
            %
            % substitute arguments into anonymous function handle
            tic
            disp(varargin)
            in = num2cell(cat(2, varargin{:}));
            mat = obj.Tf(in{:});
            toc
        end
        
        function obj=genGroups(obj)
            obj.groups = containers.Map('KeyType', 'char', 'ValueType', 'any');
            for i=1:numel(obj.m1)
                if obj.m1(i) == 0
                    continue
                end
                var = obj.m1(i);
                symbols = symvar(var);
                for j=1:length(symbols)
                    c = string(symbols(j));
                    c = convertStringsToChars(c);
                    c = c(1);
                    if ~isKey(obj.groups, c)
                        obj.groups(c) = symbols(j);
                    else
                        obj.groups(c) = [obj.groups(c); symbols(j)];
                    end
                end
            end
            
            for i=1:numel(obj.m2)
                if obj.m2(i) == 0
                    continue
                end
                var = obj.m2(i);
                symbols = symvar(var);
                for j=1:length(symbols)
                    c = string(symbols(j));
                    c = convertStringsToChars(c);
                    c = c(1);
                    if ~isKey(obj.groups, c)
                        obj.groups(c) = symbols(j);
                    else
                        obj.groups(c) = [obj.groups(c); symbols(j)];
                    end
                end
            end
            
            % sort the syms in alphanumeric order
            k = keys(obj.groups);
            for i=1:length(k)
                obj.groups(k{i}) = unique(obj.groups(k{i}));
            end
        end
        
        function pruned=pruneFrom(obj, bufChange, ...
                statesToPrune, internalStates)
            % prunes statesToPrune from internalStates with respect to
            % bufChange
            toKeep   = [];
            toRemove = [];
            
            for i=1:size(internalStates,1)
                for j=1:size(statesToPrune,1)
                    if ( obj.isAdjacent(bufChange, internalStates(i, :), statesToPrune(j, :) ))
                        toKeep   = [toKeep; statesToPrune(j, :)];
                        toRemove = [toRemove; j];
                    end
                end
                if (~isempty(toRemove))
                    for j=length(toRemove):-1:1
                        statesToPrune(toRemove(j), :) = [];
                    end
                    toRemove = [];
                end
            end
            pruned = toKeep;
        end
        
        function expanded=expand(obj, bufChange, toExpand, expansionDomain)
            expanded = toExpand;
            toAdd    = [];
            toRemove = [];
            change   = true;
            while change
                change = false;
                for i=1:size(expanded,1)
                    for j=1:size(expansionDomain,1)
                        if isequal(expanded(i, :), expansionDomain(j, :))
                            continue
                        end
                        if ( obj.isAdjacent(bufChange, expanded(i, :), expansionDomain(j, :)) )
                            toAdd = [toAdd; expansionDomain(j, :)];
                            toRemove = [toRemove; j];
                        end
                    end
                    if ~isempty(toRemove)
                        for j=length(toRemove):-1:1
                            expansionDomain(toRemove(j), :) = [];
                        end
                        toRemove = [];
                    end
                end
                if ~isempty(toAdd)
                    change = true;
                    expanded = [expanded; toAdd];
                    toAdd = [];
                end
            end
        end
        
        function val=isAdjacent(obj, bufChange, state1, state2)
            change1 = obj.b1(state2(2), state1(2));
            change2 = obj.b2(state2(3), state1(3));
            
            val = false;
            
            % bufChange does not match
            if change1 + change2 ~= bufChange
                return
            end
            
            % if m2 is starved and it should go to another state instead of
            % the state it arrows to, we should mark it
            specialLowerBoundary = false;
            if state1(1) == 0
                for i = 1:length(obj.sub2)
                    if obj.sub2(i,state1(3)) == state2(3) && obj.sub2(i,state1(3)) ~= i
                        specialLowerBoundary = true;
                        break;
                    end
                end
            end
            
            % if m2 is starved and it this change can't happen
            if state1(1) == 0 && obj.c2(state2(3), state1(3)) == 0 && specialLowerBoundary == false
                return
            end
            
            % if m2 is starved and it should not go to this state, instead
            % it should go to another state (like C->B instead of C->D)
            if state1(1) == 0 && obj.sub2(state2(3), state1(3)) ~= state2(3)
                return
            end
            
            % if m2 is starved and the buffer is still 0 but m1 produces(in
            % this situation buffer should be 1 instead because of
            % Gershwin's hypothesis)
            if state1(1) == 0 && state2(1) == 0 && change1 ~= 0
                return
            end
            
            % if m1 is blockd and it should go to another state instead of
            % the state it arrows to, we should mark it
            specialUpperBoundary = false;
            if state1(1) == obj.bufCap
                for i = 1:length(obj.sub1)
                    if obj.sub1(i,state1(2)) == state2(2) && obj.sub1(i,state1(2)) ~= i
                        specialUpperBoundary = true;
                        break;
                    end
                end
            end
            
            % if m1 is blockd and it this change can't happen
            if state1(1) == obj.bufCap && obj.c1(state2(2), state1(2)) == 0 && specialUpperBoundary == false
                return
            end
            
            % if m1 is blockd and it should not go to this state, instead
            % it should go to another state (like C->B instead of C->D)
            if state1(1) == obj.bufCap && obj.sub1(state2(2), state1(2)) ~= state2(2)
                return
            end
            
            % if m1 is blockd and the buffer is still N but m2 subtracts(in
            % this situation buffer should be N-1 instead because of
            % Gershwin's hypothesis)
            if state1(1) == obj.bufCap && state2(1) == obj.bufCap && change1~=0
                return
            end
            
            
            m1Connected = ( obj.m1(state2(2), state1(2)) ~= 0 || specialUpperBoundary);
            m2Connected = ( obj.m2(state2(3), state1(3)) ~= 0 || specialLowerBoundary);
            
            val = m1Connected && m2Connected;
            
        end
    end
end
