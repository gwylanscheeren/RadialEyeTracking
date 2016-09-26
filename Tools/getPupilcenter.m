%getPupilcenter Get user input on where the pupil centre is on the first
%   frame that is use in the Eye-Tracking procedure.
% 
%   SYNTAX
%     [vecBaseLocation intPupilLuminance] = getPupilcenter(matMovie,cfg)
%
%   INPUT
%     matMovie: matrix containing the movie
%     cfg: Configuration struct containing metadata and settings for the session that 
%          will be processed. As found in the Queuefile created by BuildPreProBatch.
%
%   OUTPUT
%     vecBaseLocation: vector containing [X, Y] coordinates of pupil centre location in the first frame
%     intPupilLuminance: initial pupil luminance at pixel of chosen pupil centre

function [vecBaseLocation intPupilLuminance] = getPupilcenter(matMovie,cfg)   
        if isfield(cfg.Eyetrack,'ROImask') 
            ROImask = cfg.Eyetrack.ROImask;
        else
            ROImask = cfg.PreProParam.ROImask;
        end
        
        %% pupil center input
        %request pupil center for initial pupil color definition
        h2 = figure('units','normalized','outerposition',[0 0 1 1]);
        if ~isfield(cfg.Eyetrack,'TimeFrame');
            Frame = cfg.Eyetrack.CropFrame(1) + 99;
            RealFrame = 100;
        elseif isfield(cfg,'PreProParam')
            Frame = 1;
            RealFrame = Frame;
        else
            Frame = cfg.Eyetrack.CropFrame(1)-1 + cfg.Eyetrack.TimeFrame(1);
            RealFrame = cfg.Eyetrack.TimeFrame(1);
        end
        
        matMovie = uint8(matMovie(:,:,Frame));
        image(matMovie,'CDataMapping','scaled');
%         colormap(bone(255));
        colormap(bone);
%         hold on; r = imagesc(ROImask); alpha = not(ROImask)*0.4; set(r, 'AlphaData', alpha); hold off;
        title(sprintf('Pupil center and initial luminance selection for Recording %s%s at frame %1.0d',cfg.strSes,cfg.strRec,RealFrame));
        drawnow;
        vecBaseLocation = [0 0];
        while vecBaseLocation(1) <= 0 && vecBaseLocation(2) <= 0
            vecBaseLocation = round(ginput(1));
        end
        intPupilLuminance = matMovie(vecBaseLocation(2),vecBaseLocation(1));
        
        %close figures
        close(h2);
%         drawnow;
end