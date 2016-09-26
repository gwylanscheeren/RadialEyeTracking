%RunEyeDetectPrePro pre-processing procedure that crops and reformats video's that can subsequently be evaluated by the Eye-Tracking algorithm
%
%   SYNTAX
%     sVideoAll = RunEyeDetectPrePro(cfg)
%
%   INPUT
%     cfg: Configuration struct containing metadata and settings for the session that will be processed. 
%          As found in the Queuefile created by BuildPreProBatch.
%
%   OUTPUT
%         sVideoAll: struct containing eye tracking video and metadata
%             width: video width in pixels
%            height: video height in pixels
%     nrFramesTotal: total number of frames recorded
%              rate: overall average frame rate in frames per second (nrFramesTotal/totalDuration)
%     totalDuration: total video duration in seconds
%             times: vector containing frame time-stamps in seonds (since the start of the recording)
%          matMovie: width x height x nrFramesTotal -matrix containig the cropped and reformatted video frames
%           ROImask: selection mask created by getMovieROI to constrain the Eye-Tracking by masking definite non-pupil pixels 
%
%   DEPENDS ON
%     getTime
%     mmread
%     progressbar
%     sec2hmsstring
%
%   REVISIONS
%     Modified by Gwylan Scheeren |21|4|2015| Universiteit van Amsterdam
%     Modified by Gwylan Scheeren |26|11|2015| Universiteit van Amsterdam
%     Modified by Guido Meijer |09|02|2016| Universiteit van Amsterdam

function [sVideoAll, matMovie] = RunEyeDetectPrePro(cfg)
tic;
 % Update or create progressbars
    if exist('progressbar','file')
        status = progressbar('status');
        currenttext = sprintf('PreProcessing session %s%s',cfg.strSes,cfg.strRec);
        if ~isempty(status.progfig)
                progressbar('changelabel',3,currenttext); % Change label of bar that indicate this session's progress
                progressbar([],[],[],0,0);
        else
            progressbar(currenttext,'Cropping video','Concatenating files'); % Init 3 bars
        end
    end

%% Preproces
strSes = cfg.strSes;
strRec = cfg.strRec;
intRec = cfg.intRec;
%source/target data
strTargetPath = cfg.FileSavePath;
vecRect = cfg.PreProParam.vecRect;
ROImask = cfg.PreProParam.ROImask;
% strTempPath = [strTargetPath '\temp'];
strSourceFile = cfg.RawVideosourceFile;

%make target dir
if ~isdir(strTargetPath)
    mkdir(strTargetPath);
end
% 
% %make temp dir
% if ~isdir(strTempPath)
%     mkdir(strTempPath);
% end

% Cropping movie
intMaxFrameLoad = 1000;
set(0,'DefaultFigureWindowStyle','normal')

%get initial video metadata
clear sVideoInit
sVideoInit = mmread(strSourceFile,100); %# the nrFramesTotal field value is based on default framerate and total duration
% intFramesTot = round(.80 * abs(sVideoInit.nrFramesTotal)); %# calculate estimated number of frames taking into account an average frame loss of 20%
intFramesTot = round(abs(sVideoInit.nrFramesTotal)); %# calculate estimated number of frames taking into account an average frame loss of 20%

%# find actual nrFramesTotal by letting mmread exceed the total number of frames
% disable warnings
warning('off','mmread:general');
increment = 10000;
intFrame = (intFramesTot-increment):intFramesTot;
lastFrameIdentified = 0;
while ~lastFrameIdentified
    intFrame = intFrame+increment;
    sVideoInit = mmread(strSourceFile,intFrame); 
    if numel(intFrame) > size(sVideoInit.frames,2)
        lastFrameIdentified = 1;
        strDuration = sec2hmsstring(sVideoInit.totalDuration);
        fprintf('Video metadata\nSession: %s%s\nnrFrames: %1.0f\nDuration: %s\nFramerate: %1.2f fps\n',strSes,strRec,sVideoInit.nrFramesTotal,strDuration,sVideoInit.nrFramesTotal/sVideoInit.totalDuration);
    end
end
intFramesTot = sVideoInit.nrFramesTotal;

%crop whole video or just part
if cfg.PrePro && isfield(cfg.PreProParam,'rawTimeFrame')
    rawTimeFrame = cfg.PreProParam.rawTimeFrame;
    intFramesTot = rawTimeFrame(2)-rawTimeFrame(1)+1;
else
    rawTimeFrame = [1 intFramesTot];
end


%calc how many parts to split into, given certain max frame load
intTotSteps = ceil(intFramesTot/intMaxFrameLoad);
vecMaxFrame = linspace(rawTimeFrame(1),rawTimeFrame(2),intTotSteps);
vecMaxFrame = round(vecMaxFrame);
vecMaxFrame(end) = vecMaxFrame(end)+1;
    
%% loop through video for cropping

%Initialize
intTotParts = (length(vecMaxFrame)-1);
matMovie = [];
vecTimes = [];

for intPart=1:intTotParts
    %get video
    sVideo = mmread(strSourceFile,vecMaxFrame(intPart):(vecMaxFrame(intPart+1)-1));
    matCrop = zeros(vecRect(4)+1,vecRect(3)+1,numel(sVideoInit.frames),'uint8');
    
    %crop video
    for intFrame = 1:length(sVideo.frames)
        matCrop(:,:,intFrame) = imcrop(sVideo.frames(intFrame).cdata(:,:,1),vecRect);
    end
    
    %append
    matMovie = cat(3, matMovie, matCrop);
    vecTimes = cat(2, vecTimes, sVideo.times);
    
    clear sVideo; 
    if intPart == 1 || mod(intPart,10) == 0 || intPart == intTotParts
        fprintf('Cropped part %d of %d [%s] for file %s%s%s\n',intPart,intTotParts,getTime,strSes,'\',strRec);
    end
    
end

%Get video meta data 
sVideoAll = mmread(strSourceFile,1);
sVideoAll = rmfield(sVideoAll, 'frames');
sVideoAll.times = vecTimes;

%store cropped polygon ROImask in output struct
sVideoAll.ROImask = ROImask;

%update video meta-data
sVideoAll.rate = sVideoAll.nrFramesTotal./sVideoAll.totalDuration;
sVideoAll.width = size(matMovie,1);
sVideoAll.height = size(matMovie,2);
sVideoAll = rmfield(sVideoAll,'skippedFrames');


    
%     %save data to temp file
%     sVideo = rmfield(sVideo,'frames');
%     strSaveTempFile = [strTempPath filesep 'TMP_videopart_' sprintf('%03d',intPart) '.mat'];
%     save(strSaveTempFile, 'sVideo', 'matMovie');
%     
%     %print progress every 10 parts and for the last part & update progress bar
%     if intPart == 1 || mod(intPart,10) == 0 || intPart == intTotParts
%         fprintf('Cropped part %d of %d [%s] for file %s%s%s\n',intPart,intTotParts,getTime,strSes,'\',strRec);
%     end
%     if exist('progressbar','file') == 2; progressbar([],[],intPart/intTotSteps,intPart/intTotParts); end % Update 2nd bar
% end

% %% concatenate everything
% %get files
% sDir = dir(sprintf('%s%sTMP_videopart_*.mat',strTempPath,filesep));
% sVideoAll = rmfield(sVideo,'frames');
% clear sVideo;
% matMovie = [];
% sVideoAll.times =[];
% 
% %loop through files and put results in sVideoAll
% for intPart = 1:intTotParts
%     %get file, load it & append to end of aggregate
%     strFile = [strTempPath filesep sDir(intPart).name];
%     sTemp = load(strFile);
%     if ~isfield(sTemp.sVideo,'matMovie')
%         sTemp.sVideo.matMovie = sTemp.matMovie;
%     end
%     matMovie = cat(3, matMovie, sTemp.sVideo.matMovie);
%     sVideoAll.times = cat(2, sVideoAll.times, sTemp.sVideo.times);
%     
%     %delete temp file
%     delete(strFile);
%     
%     %print progress every 10 parts and for the last part & update progress bars
%     if intPart == 1 || mod(intPart,10) == 0 || intPart == intTotParts
%         fprintf('Concatenated part %d of %d [%s] for file %s%s%s\n',intPart,intTotParts,getTime,strSes,'\',strRec);
%     end
%     if exist('progressbar','file') == 2; progressbar([],[],[],[],intPart/intTotParts); end % Update 3rd bar
%     if exist('progressbar','file') == 2; progressbar([],[], (intTotParts + (intPart/intTotParts)) /intTotSteps); end % Update 1st bar
% end
% if exist('progressbar','file') == 2; progressbar([],[],intTotSteps/intTotSteps); end % Update 1st bar
% 
% %remove empty frames
% vecM=squeeze(mean(mean(matMovie,1),2));
% matMovie = matMovie(:,:,vecM~=0);
% 
% %store cropped polygon ROImask in output struct
% sVideoAll.ROImask = ROImask;
% 
% %update video meta-data
% sVideoAll.rate = sVideoAll.nrFramesTotal./sVideoAll.totalDuration;
% sVideoAll.width = size(matMovie,1);
% sVideoAll.height = size(matMovie,2);
% sVideoAll = rmfield(sVideoAll,'skippedFrames');
% 
% %remove temporary directory
% % disable warnings
% warning('off','MATLAB:RMDIR:RemovedFromPath');
% rmdir(strTempPath);

t = toc;
strDuration = sec2hmsstring(t);
fprintf('Finished cropping video for session %s%s in %s [%s]\n',strSes,strRec,strDuration,getTime);
end