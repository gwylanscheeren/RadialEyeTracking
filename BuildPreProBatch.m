%BuildPreProBatch Generates Queue-file by checking the source directory and all its sub-directories for (eye-tracking) video's
%     Queue-file is then populated with metadata needed for preprocessing
% 
%   EYE-TRACKING PIPELINE
%     BuildPreProBatch -> getMovieROI
%          |
%     BatchProcess ---> RunEyeDetectPrePro
%          |        |
%          |        |   -> (detectStartStop)
%          |        |   -> (getPupilColor)
%          |        --> FramePupilDetect
%          |
%     runCreatePreDataAggregate -> getResampledEyeTrackingData
%                               -> buildMultiSesAggregate
%
%   SYNTAX
%     BuildPreProBatch
%
%   INPUT
%     set the appropriate directories and filename for Queue file
%     sourceDirectory: the general Eye-Tracking directory
%     sParams.strRawVideoPath: where the raw video's are located
%     sParams.QueuePath (optional, default: sourceDirectory): set directory to save queuefile to a directory other than sourceDirectory
%     sParams.SaveName: specify the filename for the Queuefile
%
%   OUTPUT
%     Creates a queue-file according to set filename (sParams.SaveName) in the directory specified in (sParams.QueuePath)
%
%   DEPENDS ON
%     getAllFiles
%     getMovieROI
%
%   VERSIONS
%     Created by Gwylan Scheeren |8|11|2015| Universiteit van Amsterdam
%     Modified by Gwylan Scheeren |26|11|2015| Universiteit van Amsterdam

function BuildPreProBatch
% set Directories
sourceDirectory = 'D:\Stage\BehaviourEyeTrackData\';
sParams.strRawVideoPath = 'D:\Stage\BehaviourEyeTrackData\Raw\';
sParams.saveDirectory = [sourceDirectory 'CroppedVideos\']; %# save directory to put cropped videos in
sParams.QueuePath = 'D:\Stage\BehaviourEyeTrackData\'; %# directory to save queue file in, if 'commented out' the 'sourceDirectory' is used.
sParams.SaveName = 'Queuefile';

%set parameters
sParams.boolQueueEntryOverwrite = 0;

% Initialize values
if ~exist('sParams.QueuePath','var')
    sParams.QueuePath = sourceDirectory;
end

%% generate file list from main- and sub- directories, restructure and remove all non-movie files
fileList = getAllFiles(sParams.strRawVideoPath); %# function that retrieves file list 
if ~isempty(fileList)
    for i = 1:size(fileList,1)
    [Files(i).dir, Files(i).name, ext] = fileparts(fileList{i});
    Files(i).filename = fileList{i};
    indNoMovie(i) = not(max(strcmp(ext,{'.avi', '.mp4', '.mpg'}))); %# indentify all non-movie files
    end
end
Files(indNoMovie) = []; %# remove all non-movie (.avi,.mp4,.mpg) files
flist = {Files.name}';
clearvars -except Files sParams flist

%% if required: check if files is already in queuefile    
if numel(dir(sprintf('%s%s%s',sParams.QueuePath,sParams.SaveName,'.mat'))) > 0
    qLoad = load(sprintf('%s%s%s',sParams.QueuePath,sParams.SaveName,'.mat'));
    FileQueue = qLoad.Queue;
    qlist = arrayfun(@(x) [x.cfg.strSes '_' x.cfg.strRec], FileQueue,'UniformOutput',0)';
    
    
    if ~sParams.boolQueueEntryOverwrite
        fduplicatelist = arrayfun(@(x) strcmp(x,qlist), flist,'UniformOutput',0); %#check for each element of the filename list wether it is already in the previously saved PrePro quefile
        fduplicatelist = arrayfun(@(x) sum(x{1,1}) > 0,fduplicatelist,'UniformOutput',0);
        
        qduplicatelist = arrayfun(@(x) strcmp(x,flist), qlist,'UniformOutput',0); %#check for each element of the queue list wether it is the current file list
        qduplicatelist = arrayfun(@(x) sum(x{1,1}) > 0,qduplicatelist,'UniformOutput',0);
    end
end

% clearvars -except Files sParams

%% Populate configuration structs for pre processing
for i = 1:size(flist,1)
    indQueue = [];
    if exist('qlist','var')
        indQueue = find(strcmp(qlist,flist(i)));
    end

    
    if sParams.boolQueueEntryOverwrite || (~sParams.boolQueueEntryOverwrite && isempty(indQueue))
        %prepare Qcfg struct
        Qcfg.PrePro = true;
        pathparts = regexp(Files(i).filename, '\', 'split');
        Qcfg.strSes = pathparts{end-1};
        Qcfg.strRec = pathparts{end}(end-8:end-4);
        Qcfg.intRec = str2double(pathparts{end}(end-5:end-4));
        Qcfg.RawVideosourceFile = Files(i).filename;
        Qcfg.FileSavePath = [sParams.saveDirectory Qcfg.strSes filesep];
        
        %get cropping parameters
        [Qcfg.PreProParam.vecRect, Qcfg.PreProParam.ROImask] = getMovieROI(Qcfg.RawVideosourceFile,Qcfg);
        if ~isempty(Qcfg.PreProParam.ROImask)
            Save_To_Queue(indQueue);
        end
        clear Qcfg
    end
end
fprintf('In order to start processing you can evaluate the following:\nBatchProcess(''%s%s.mat'')\n',sParams.QueuePath,sParams.SaveName);

    function Save_To_Queue(indQueue)
        Queue = [];
        if numel(dir(sprintf('%s%s%s',sParams.QueuePath,sParams.SaveName,'.mat'))) > 0
            qLoad = load(sprintf('%s%s%s',sParams.QueuePath,sParams.SaveName,'.mat'));
            Queue = qLoad.Queue;
        end
        if isempty(indQueue)
            Queue(size(Queue,2)+1).cfg = Qcfg;
        else
            Queue(indQueue).cfg = Qcfg;
        end
        save(sprintf('%s%s',sParams.QueuePath,sParams.SaveName),'Queue','-v7.3');
        fprintf('Added session %s%s to pre-processing que file in %s%s.mat [%s]\n',Qcfg.strSes,Qcfg.strRec,sParams.QueuePath,sParams.SaveName,getTime);
    end
end
