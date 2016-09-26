%detectStartStop Semi-automatically detects the beginning and end of the recording
%     session in an eyetracking video, using overall video brightness.
%
%   SYNTAX
%     Frame = detectStartStop(matMovie,cfg)
%
%   INPUT
%     matMovie: matrix containing the video frames
%     cfg: Configuration struct containing metadata and settings for the session that 
%          will be processed. As found in the Queuefile created by BuildPreProBatch.
%
%   OUTPUT
%     Frame: two-element vector containing the first and last frame 
%
%   DEPENDS ON
%     export_fig
%     Image Processing Toolbox
%
%   REVISIONS
%     Adapted by Gwylan Scheeren |9|4|2015| Universiteit van Amsterdam
%     Modified by Gwylan Scheeren |26|11|2015| Universiteit van Amsterdam

function Frame = detectStartStop(matMovie,cfg)
%detect start + end; define step size
        %ask which cut-off to use

        
        vecMean = squeeze(mean(mean(matMovie,1),2));        
        %make sure a viable selection can be made, by shifting datapoints
        %after 200 frames, that are lower than the minimum value in the first two hundred frames
        %upwards with half the distance between the mean and minimum. While
        %preserving the eventual drop at the last 15 percent of the frames
%         minimum = min(vecMean(1:200));
%         shift = (vecMean <= minimum+0.5*(mean(vecMean)-minimum));
%         shift(1:200) = false;
%         shift(numel(vecMean)-round(0.15*numel(vecMean)):numel(vecMean)) = false;
%         vecMean(shift) = minimum+0.5*(mean(vecMean)-minimum);
%         
        %display figure and ask for rectangle
        h=figure('units','normalized','outerposition',[0 0 1 1]);
        plot(vecMean);
        xlim([0 length(vecMean)+1]);
        title(sprintf('Time-point selection for Recording %s%s (Right-click to accept selection and continue)',cfg.strSes,cfg.strRec));
        
        %pre-alloc
        dblCutOff = -1;
        hX1 = [];
        hX2 = [];
        hX3 = [];
        boolAccept = false;
        while ~boolAccept
            
            %ask for cut off
            [dummy,dblCutOff,intButton] = ginput(1);
            
            %check if done
            if intButton ~= 1 && dblCutOff ~= -1
                boolAccept = true;
                break
            end
            
            %take point in-between two means as cut-off point, tranform to logical and
            %get time points of largest bright epoch
            indBright = vecMean > dblCutOff;
            sCC = bwconncomp(indBright);
            [intSize,intIndex] = max(cellfun(@numel,sCC.PixelIdxList));
            intStart = sCC.PixelIdxList{intIndex}(1);
            intStop = sCC.PixelIdxList{intIndex}(end);
            
            %remove old lines
            if ~isempty(hX1)
                delete(hX1);
                delete(hX2);
                delete(hX2label);
                delete(hX3);
                delete(hX3label);
                hX1 = [];
                hX2 = [];
                hX3 = [];
                hX2label = [];
                hX3label = [];
            end
            
            %plot selection
            yLim = get(gca,'YLim');
            hX1 = line(get(gca,'XLim'),[dblCutOff dblCutOff],'Color','k','LineWidth',1,'LineStyle','--');
            hX2 = line([intStart intStart]-0.5,get(gca,'YLim'),'Color','g','LineWidth',1,'LineStyle','--');
            hX2label = text(intStart,dblCutOff-2,sprintf('<-- First frame: %1.0f',intStart));
            hX3 = line([intStop intStop]+0.5,get(gca,'YLim'),'Color','r','LineWidth',1,'LineStyle','--');
            hX3label = text(intStop,dblCutOff-2,sprintf('Last frame: %1.0f -->',intStop),'HorizontalAlignment','right');
        end
        
        Frame(1) = intStart;
        Frame(2) = intStop;
        
        %save example image
        strFigName = sprintf('TimeFrameSelection_%sxyt%02d',cfg.strSes,cfg.intRec);
        strTargetDir = [cfg.FileSavePath 'TimeFrameSelectionFigs' filesep];
        strTotName = [strTargetDir strFigName];
        
        %make sure target dir exists
        if ~isdir(strTargetDir)
            mkdir(strTargetDir);
        end
        
        %                     %supress warning about graphics version
%                             warning('on','MATLAB:graphicsversion:GraphicsVersionRemoval')
        %save example figure
        %export_fig(strTotName, '-pdf', '-tiff');
        %fprintf(' > Saved visual time selection to %s [%s]\n',strFigName,strTotName);
        
        close(h);
        clear sVideoAll;
end