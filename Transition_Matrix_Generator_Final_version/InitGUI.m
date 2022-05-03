classdef InitGUI < handle
    properties
        machineName;
        upStream;
        downStream;
        bufCap;
    end
    methods
        % eg: InitGUI()
        function obj = InitGUI()
            % Create a figure window:
            DEBUG = 1;
            fig = uifigure('Name', 'init', 'Position',[300 300 500 500]);
            lbtitle = uilabel(fig);
            lbtitle.Text='StateFlow Information Input';
            lbtitle.Position = [120,450,900,20];
            lbtitle.FontWeight = 'bold';
            lbtitle.FontSize = 16;
            
            lbMachineName = uilabel(fig);
            lbMachineName.Text='Machine Name';
            lbMachineName.Position = [50,400,90,20];
            
            txMachineName = uitextarea(fig);
            txMachineName.Position = [200,400,250,30];
            txMachineName.Value = '';
            if DEBUG
                txMachineName.Value = 'figure11';
            end
            
            lbUpStream=uilabel(fig);
            lbUpStream.Text = 'UpStream Name';
            lbUpStream.Position = [50,310,90,20];
            
            txUpStreamName = uitextarea(fig);
            txUpStreamName.Position = [200,310,250,30];
            txUpStreamName.Value = '';
            
            if DEBUG
                txUpStreamName.Value = 'Upstream';
            end
            
            lbDownStream=uilabel(fig);
            lbDownStream.Text = 'DownStream Name';
            lbDownStream.Position = [50,220,250,20];
            
            
            txDownStreamName = uitextarea(fig);
            txDownStreamName.Position = [200,220,250,30];
            txDownStreamName.Value = '';
            if DEBUG
                txDownStreamName.Value = 'Downstream';
            end
            
            lbBufCap=uilabel(fig);
            lbBufCap.Text = 'Max Buffer';
            lbBufCap.Position = [50,130,250,20];
            
            txBufCap = uitextarea(fig);
            txBufCap.Position = [200,130,250,30];
            txBufCap.Value = '';
            
            if DEBUG
                txBufCap.Value = '4';
            end
            
            btn = uibutton(fig,'push', 'ButtonPushedFcn',...
                @(btn,event) obj.printinput(txMachineName,txUpStreamName,txDownStreamName,txBufCap));
            btn.Text = 'submit';
            btn.Position = [300 50 50 25];
            
            uiwait(fig);
            
            % disp(obj)
        end
        
        function obj = printinput(obj,txMachineName,txUpStreamName,txDownStreamName,txBufCap)
            obj.machineName=txMachineName.Value;
            obj.upStream=txUpStreamName.Value;
            obj.downStream=txDownStreamName.Value;
            obj.bufCap=txBufCap.Value;
            closereq();
        end
        
    end
end