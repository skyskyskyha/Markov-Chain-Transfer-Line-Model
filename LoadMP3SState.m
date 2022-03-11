function [TransitionMatrixMP3State,StateVecMatrix]=LoadMP3SState(systemModelFiles)
% evaluation usage T=TransitionMatrixMP3State{i}(ps,psu)
%
% commented out evaluation usage requires
% T=TransitionMatrixMP3State.(['N',num2str(i)]){1}(ps,psu) %note the cell array usage
% this approach uses a dynamic structure
%
% For Debug
systemModelFiles=['\HangtianPrograms\buffers'];
dirNow=pwd;

targetpath=[pwd,systemModelFiles];
filelist=dir([targetpath,'\buffer*.mat']);
for i=1:length(filelist)
    buffersize(i)=str2num(filelist(i).name(strfind(filelist(i).name,'r')+1:strfind(filelist(i).name,'.')-1));
end
minN=min(buffersize);
maxN=max(buffersize);

TransitionMatrixMP3State=cell(1,maxN);
StateVecMatrix=cell(1,maxN);
for i=1:minN-1
    %TransitionMatrixMP3State.(['N',num2str(i)])=[];
    TransitionMatrixMP3State{i}=[];
    StateVecMatrix{i}=[];
end
cd(targetpath);
for i=minN:maxN
    clear temp
    %filenameIn=([targetpath,'\buffer',num2str(i),'.mat']);
    %addpath(filenameIn);
    filenameIn=(['buffer',num2str(i),'.mat']);
    load(filenameIn)
    %rmpath([pwd,'\HangtianPrograms\buffers\']);
    %TransitionMatrixMP3State.(['N',num2str(i)])={temp.Tf};
    TransitionMatrixMP3State{i}=temp.Tf;
    StateVecMatrix{i}=temp.svm;
end
cd(dirNow)


