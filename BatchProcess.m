%BatchProcess Performs batch processing off presented Queue file containing meta data and instructions for pre-processing and eye-tracking
%
%   SYNTAX
%     BatchProcess(strQueueFile)
%
%   INPUT
%     strQueueFile: location and name of Queue-file as created by BuildPreProBatch
%
%   OUTPUT
%     Performs pre-processing/eye-tracking on user-selected sessions in Queue-file and saves the results
%
%   DEPENDS ON
%     RunEyeDetectPrePro
%     detectStartStop
%     getPupilcenter
%     FramePupilDetect
%     progressbar
%     getTime
%
%   VERSIONS
%     Created by Gwylan Scheeren |12|7|2015| Universiteit van Amsterdam
%     Modified by Gwylan Scheeren |26|11|2015| Universiteit van Amsterdam

function BatchProcess(strQueueFile)
% strQueueFile = 'D:\Internship\Gwylan\Two Photon\Processed\imagingvideo\Queuefile.mat';
% strQueueFile = 'D:\Internship\Guido\EyeTracking\Queuefile.mat'
if nargin == 1
    pathparts = regexp(strQueueFile, '\', 'split');
    QueuePath = strQueueFile(1:(end-numel(pathparts{end})));
else
    [FileName, QueuePath, NotUsed] = uigetfile('*Queuefile*.mat', 'Please select a valid source file to inspect');
    strQueueFile = [QueuePath FileName];
end
fLoad = load(strQueueFile);
Queue = fLoad.Queue;
%% check existing
croppedvideoindex = ones(1,size(fLoad.Queue,2));
eyetrackvideoindex = ones(1,size(fLoad.Queue,2));

for i = 1:size(fLoad.Queue,2)
    if numel(dir([Queue(i).cfg.FileSavePath sprintf('%s_%s%s','croppedvideo',Queue(i).cfg.strSes,Queue(i).cfg.strRec) '.mat'])) == 1
        croppedvideoindex(i) = 0;
        if ~isfield(Queue(i).cfg, 'CroppedVideo')
            Queue(i).cfg.CroppedVideo = [Queue(i).cfg.FileSavePath sprintf('%s_%s%s','croppedvideo',Queue(i).cfg.strSes,Queue(i).cfg.strRec) '.mat'];
            Queue(i).cfg.Eyetrack.useROImaskArea = false;
            Queue(i).cfg.Eyetrack.useTimeselection = false;
            Queue(i).cfg.Eyetrack.ROImask = Queue(i).cfg.PreProParam.ROImask;
            Queue(i).cfg.PrePro = false;
        end
    end
    if numel(dir([Queue(i).cfg.FileSavePath sprintf('EyeTrackData_%s%s',Queue(i).cfg.strSes,Queue(i).cfg.strRec) '.mat'])) == 1
        eyetrackvideoindex(i) = 0;
    end
end
croppedQueuelist = arrayfun(@(x) [x.cfg.FileSavePath sprintf('%s_%s%s','croppedvideo',x.cfg.strSes,x.cfg.strRec) '.mat'],Queue,'UniformOutput',0);
eyetrackQueuelist = arrayfun(@(x) [x.cfg.FileSavePath sprintf('EyeTrackData_%s%s',x.cfg.strSes,x.cfg.strRec) '.mat'],Queue,'UniformOutput',0);
croppedvideoindex = find(croppedvideoindex);
eyetrackvideoindex = find(eyetrackvideoindex);

v = 0;
while ~v
[croppedSelection,v] = listdlg('PromptString',{'Previously saved cropped videos found for unselected entries,','select them to re-prepocess and overwrite:','select cancel to reset to initial automatic selection'},...
                'InitialValue',croppedvideoindex,...
                'SelectionMode','multiple',...
                'ListString',croppedQueuelist,...
                'ListSize',[500 300]);
end
v = 0;
while ~v
[eyetrackSelection,v] = listdlg('PromptString',{'Previously saved eye tracking files found for unselected entries,','select them to re-perform eye tracking and overwrite:','select cancel to reset to initial automatic selection'},...
                'InitialValue',eyetrackvideoindex,...
                'SelectionMode','multiple',...
                'ListString',eyetrackQueuelist,...
                'ListSize',[500 300]);
end

%% create progressbar
if exist('progressbar','file') == 2 && exist('Queue','var')
    progressbar(sprintf('Batch evaluating %d pre-processing sessions and %d eye tracking sessions',numel(croppedSelection),numel(eyetrackSelection)), sprintf('Pre-processing %d video files',numel(croppedSelection)),'PreProcessing session','Cropping movie','Concatenating movie',sprintf('Performing Eye-Tracking for %d sessions',numel(eyetrackSelection)),'Blur all frames','Performing Eye-Tracking'); % Init 8 bars
end

%% get time selection, ROI selection and pupil centre and location parameters for sessions that where previously pre-processed
for i = eyetrackSelection(not(ismember(eyetrackSelection,croppedSelection)))
    getEyeTrackMeta;
end

%% Start Pre-Processing of selected files
cnt1 = 0;
if numel(croppedSelection) > 0
    fprintf('Started pre-processing of %d sessions [%s]\n',numel(croppedSelection),getTime);
    for i = croppedSelection
        cnt1 = cnt1 + 1;
        progressbar([],[],0,0);
        progressbar('changelabel',3,sprintf('Pre-Processing session %s%s',Queue(i).cfg.strSes,Queue(i).cfg.strRec));
        fprintf('\nStarted pre-processing %s%s [%d/%d] [%s]\n',Queue(i).cfg.strSes,Queue(i).cfg.strRec,cnt1,numel(croppedSelection),getTime);
        [sVideoAll, matMovie] = RunEyeDetectPrePro(Queue(i).cfg);
        fprintf('Saving croppedvideo for session %s%s to %s [%s]\n',Queue(i).cfg.strSes,Queue(i).cfg.strRec,Queue(i).cfg.FileSavePath,getTime);
        Queue(i).cfg.CroppedVideo = [Queue(i).cfg.FileSavePath sprintf('%s_%s%s','croppedvideo',Queue(i).cfg.strSes,Queue(i).cfg.strRec) '.mat'];
        save(Queue(i).cfg.CroppedVideo,'sVideoAll','matMovie','-v7.3');
        %clear sVideoAll matMovie
        Queue(i).cfg.Eyetrack.useROImaskArea = false;
        Queue(i).cfg.Eyetrack.useTimeselection = false;
        Queue(i).cfg.Eyetrack.ROImask = Queue(i).cfg.PreProParam.ROImask;
        Queue(i).cfg.PrePro = false;
        
        %save meta data to queue-file
        save(strQueueFile,'Queue','-v7.3');
        fprintf('Saved as %s [%s]\n',Queue(i).cfg.CroppedVideo,getTime);
        if exist('progressbar','file') == 2; progressbar(cnt1/(numel(croppedSelection)+numel(eyetrackSelection))); end % Update primary bar
        if exist('progressbar','file') == 2; progressbar([],cnt1/numel(croppedSelection)); end % Update 2nd bar
    end
    
    save(strQueueFile,'Queue','-v7.3');
    fprintf('\nFinished cropping video files\nUpdated queue file %s [%s]\n',[QueuePath strQueueFile],getTime);
    
end

%% get time selection, ROI selection and pupil center and location parameters for sessions that where previously pre-processed
% for i = eyetrackSelection(ismember(eyetrackSelection,croppedSelection))
%     getEyeTrackMeta;
% end
% 
% %% Batch process the eye tracking of selected sessions
% if numel(eyetrackSelection) > 0
%     fprintf('\nStarted eye tracking for %d sessions [%s]\n',numel(eyetrackSelection),getTime);
%     cnt2 = 0;
%     for i = eyetrackSelection
%         cnt2 = cnt2 + 1;
%         % update progressbar
%         progressbar('changelabel',8,'Performing Eye-Tracking on session %s%s',Queue(i).cfg.strSes,Queue(i).cfg.strRec)
%         
%         %perform eye-tracking for this session
%         fprintf('\nStarted Eye-Tracking procedure for %s%s [%d/%d] [%s]\n',Queue(i).cfg.strSes,Queue(i).cfg.strRec,cnt2,numel(eyetrackSelection),getTime);
%         sEyeTracking = FramePupilDetectStarburst(Queue(i).cfg);
%         
%         %make target dir
%         if ~isdir(Queue(i).cfg.FileSavePath)
%             mkdir(Queue(i).cfg.FileSavePath);
%         end
%         
%         %save EyeTracking result to file and update Queuefile
%         strFileEyeTracking = sprintf('EyeTrackData_%s%s',sEyeTracking.strSes,sEyeTracking.strRec);
%         Queue(i).cfg.EyeTrackingFile = [Queue(i).cfg.FileSavePath strFileEyeTracking];
%         save(strQueueFile,'Queue','-v7.3');
%         save(Queue(i).cfg.EyeTrackingFile,'sEyeTracking','-v7.3'); 
%         fprintf('\nSaved as %s [%s]\n',Queue(i).cfg.EyeTrackingFile,getTime);
%         if exist('progressbar','file') == 2; progressbar((cnt1+cnt2)/(numel(croppedSelection)+numel(eyetrackSelection))); end % Update primary bar
%         if exist('progressbar','file') == 2; progressbar([],cnt2/numel(eyetrackSelection)); end % Update 2nd bar
%     end
% end
% fprintf('Finished batch evaluating %d pre-processing sessions and %d eye tracking sessions [%s]\n',numel(croppedSelection),numel(eyetrackSelection),getTime)
% 
%     function getEyeTrackMeta
%         if ~isfield(Queue(i).cfg,'Eyetrack') || ~isfield(Queue(i).cfg.Eyetrack,'CropFrame')
%             if isfield(Queue(i).cfg,'sOldEyeTracking') && isfield(Queue(i).cfg.sOldEyeTracking,'Frame')
%                 Queue(i).cfg.Eyetrack.CropFrame = Queue(i).cfg.sOldEyeTracking.Frame;
%             else
%                 CroppedMovie = load([Queue(i).cfg.CroppedVideo]);
%                 Queue(i).cfg.Eyetrack.CropFrame = detectStartStop(CroppedMovie.matMovie,Queue(i).cfg);
%             end
%             
%             %save meta data to queuefile            
%             save(strQueueFile,'Queue','-v7.3');
%         end
%         
%         if ~isfield(Queue(i).cfg,'Eyetrack') || ~isfield(Queue(i).cfg.Eyetrack,'vecBaseLocation') || ~isfield(Queue(i).cfg.Eyetrack,'intPupilLuminance')
%             if ~isfield(Queue(i).cfg.Eyetrack,'TimeFrame') || Queue(i).cfg.Eyetrack.TimeFrame(1) == 1;
%                 if ~exist('CroppedMovie','var'); CroppedMovie = load([Queue(i).cfg.CroppedVideo]); end
%                 [Queue(i).cfg.Eyetrack.vecBaseLocation, Queue(i).cfg.Eyetrack.intPupilLuminance] = getPupilcenter(CroppedMovie.matMovie,Queue(i).cfg);
%                 
%                 %save meta data to queuefile
%                 save(strQueueFile,'Queue','-v7.3');
%             end
%         end
%     end

end