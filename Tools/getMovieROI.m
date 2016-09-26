function [vecRect, ROImask] = getMovieROI(strFile,cfg)
%getMovieROI Determine the square region of interest for the eyetracking processing
%
%   SYNTAX
%     vecRect = getMovieROI(strFile,vecPrevRect)
%
%   INPUT
%     strFile: video filename string inlcuding directories
%     cfg: Configuration struct containing metadata and settings for the session that 
%          will be processed. As found in the Queuefile created by BuildPreProBatch.
%
%   OUTPUT
%     vecRect: rectangular region of interest for further processing
%
%   REVISIONS
%     Modified by Gwylan Scheeren |21|4|2015| Universiteit van Amsterdam
%         - use three colour channels frame 1000 from start, median frame, frame 1000 from end
%         - use impoly to create a ROI selection mask and add to outputs and get rectangle for initial function
%     Modified by Guido Meijer 1-Dec-2015
%         - rewritten first and last frame selection
%         - set middle frame as one third of the movie because some videos contain very long blank ends because some nitwit forgot to turn the video off

vecRect = [];
ROImask = [];
%% Get cropping rectangle parameters for cropping of initial (raw) video
if ~isempty(strFile)
    VideoParam = mmread(strFile,1);
    FramesTotal = .8 * abs(VideoParam.nrFramesTotal);
    if isfield(cfg,'PreProParam')
        first = cfg.PreProParam.rawTimeFrame(1);
        middle = cfg.PreProParam.rawTimeFrame(2)-cfg.PreProParam.rawTimeFrame(1)+1;
        if cfg.PreProParam.rawTimeFrame(2) < FramesTotal
            last = cfg.PreProParam.rawTimeFrame(2);
        else
            last = FramesTotal;
        end
    else
        first = 500;
        middle = FramesTotal/3; %Set middle frame at one third of the movie
        last = FramesTotal;
    end
    
    % inform about progress
    if exist('progressbar','file') == 2; progressbar(sprintf('Preparing rectangular cropping selection window for session %s%s',cfg.strSes,cfg.strRec),'Loading first video frame','Loading middle video frame','Loading last video frame'); end % Init 4 bars
    
    % load in middle frame
    sVideo{2} = mmread(strFile,middle);
    dblMiddle = sum(sum(imadjust(sVideo{2}.frames.cdata(:,:,1)))); %Get total frame intensity
    if exist('progressbar','file') == 2; progressbar(1/3,[],1/1); end
    
    % load in first frame
    sVideo{1} = mmread(strFile,first);
    dblFirst = sum(sum(imadjust(sVideo{1}.frames.cdata(:,:,1)))); 
    while dblMiddle/dblFirst < 0.7 || dblMiddle/dblFirst > 1.3 %Continue reading in frames until illuminated frame found
        first = first + 500;
        if first > FramesTotal %No matching first frame found -> redefine middle frame
            first = 500;
            middle = middle + 500;
            sVideo{2} = mmread(strFile,middle);
            dblMiddle = sum(sum(imadjust(sVideo{2}.frames.cdata(:,:,1))));
        end 
        sVideo{1} = mmread(strFile,first);
        dblFirst = sum(sum(imadjust(sVideo{1}.frames.cdata(:,:,1)))); 
    end
    if exist('progressbar','file') == 2; progressbar(2/3,1/1); end
    
    % load in last frame
    sVideo{3} = mmread(strFile,last);
    dblLast = sum(sum(imadjust(sVideo{3}.frames.cdata(:,:,1)))); 
    while dblMiddle/dblLast < 0.7 || dblMiddle/dblLast > 1.3 
        last = last - 500; 
        sVideo{3} = mmread(strFile,last);
        dblLast = sum(sum(imadjust(sVideo{3}.frames.cdata(:,:,1)))); 
    end
    if exist('progressbar','file') == 2; progressbar(3/3,[],[],1/1); end
    
    %display figure and ask for rectangle
    p = figure('units','normalized','outerposition',[0 0 1 1]);
    matRGB = imadjust(sVideo{1}.frames.cdata(:,:,1));
    matRGB(:,:,2) = imadjust(sVideo{2}.frames.cdata(:,:,1));
    matRGB(:,:,3) = imadjust(sVideo{3}.frames.cdata(:,:,1));
    ip = imshow(matRGB,'InitialMagnification','fit');
    colormap(bone);
        
    title(sprintf('Rectangular cropping selection for session %s%s (double-click on selection to continue)',cfg.strSes,cfg.strRec));
    
    %get poly-point selection region
    h2 = imrect;
    
    %create rectangle from selection
    vecRect = round(wait(h2));
    
    %% Get polygonal selection and mask
    if ~isempty(vecRect)
        sFrameCropped = zeros(vecRect(4)+1,vecRect(3)+1,3,'uint8');
        for i = 1:3
            sFrameCropped(:,:,i) = mean(imcrop(sVideo{i}.frames(1).cdata,vecRect),3);
        end
        
        %display figure and ask for polygonal selection region
        p2 = figure('units','normalized','outerposition',[0 0 1 1]);
        newmatRGB = imadjust(sFrameCropped(:,:,1));
        newmatRGB(:,:,2) = imadjust(sFrameCropped(:,:,2));
        newmatRGB(:,:,3) = imadjust(sFrameCropped(:,:,3));
        imshow(newmatRGB,'InitialMagnification','fit');
        title(sprintf('ROImask selection for session %s%s (double-click on selection to continue)',cfg.strSes,cfg.strRec));
        
        %get poly-point selection region
        h3 = impoly;
        
        %create mask and rectangle from selection
        ROImask = createMask(h3);
        dummy = round(wait(h3));
        
        close(p);
        close(p2);
    end
    
end