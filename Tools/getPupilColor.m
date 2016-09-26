%getPupilColor Calculate average pupil luminance over provided range of frames, given the pupil center location
% 
%   SYNTAX
%     dblPupilLuminance = getPupilColor(intFrame,intPupFrameRange,dblPosX,dblPosY,matMovie)
%
%   INPUT
%     intFrame: frame to evaluate 
%     intPupFrameRange: range of frames to use
%     dblPosX: x coördinate of user defined pupil center location for determining initial luminance
%     dblPosY: y coördinate of user defined pupil center location for determining initial luminance
%     matMovie: matrix containing the movie
% 
%   OUTPUT
%     dblPupilLuminance: average pupil luminance around provided pupil center over provided frame range
%     
%   VERSION HISTORY
%     12-7-2015 added wheighted evaluation of average to current frame luminance in ratio of 1:4
%               this addition aims to alleviate problems with video flickering that results in 
%               alternating dark and light frames.

function dblPupilLuminance = getPupilColor(intFrame,intPupFrameRange,dblPosX,dblPosY,matMovie)

	verbose = 0;
   
	%get frame range
	intStartFrame = round(intFrame-(0.5*intPupFrameRange));
	intStopFrame = round(intFrame+(0.5*intPupFrameRange)-1);
	intMaxFrame = size(matMovie,3);
	if intStartFrame<1
		intStartFrame=1;
		intStopFrame=intFrame+intPupFrameRange-1;
	elseif intStopFrame>intMaxFrame
		intStartFrame=intMaxFrame-intPupFrameRange+1;
		intStopFrame=intMaxFrame;
	end
	
	%get pixel locations surrounding middle of pupil
	matSelect = false(size(matMovie,1),size(matMovie,2));
	matSelect(round(dblPosY-2):round(dblPosY+2),round(dblPosX-2):round(dblPosX+2)) = true;
	matVals = nan(25,length(intStartFrame:intStopFrame));
	intCounter = 0;
	for thisFrame=intStartFrame:intStopFrame
		intCounter = intCounter + 1;
		matFrame = matMovie(:,:,thisFrame);
		matVals(:,intCounter) = matFrame(matSelect);
    end
    if verbose && mod(intFrame,500) == 0; makefigure; end
    
    thisPupilFrame = matMovie(:,:,intFrame);
	dblPupilLuminance = (abs(mean(matVals(:))) * .2) + (.8 * abs(mean(thisPupilFrame(matSelect))));
    
    function makefigure
        PF = figure('units','normalized','Position',[.19 .1 .6 .79]);
        subplot(2,2,1,'position', [0.075 .54 .4 .4])
        hold on
        imagesc(matMovie(:,:,intFrame));
        [row,col] = find(matSelect);
        rectangle('Position',[min(col)-.5 min(row)-.5 max(col)-min(col)+1 max(row)-min(row)+1]);
        m = imagesc(matSelect); alpha = not(matSelect)*0.2; set(m, 'AlphaData', alpha);
        hold off
        axis off;
        title('Frame for wich luminance is calculated');
        subplot(2,2,2,'position', [.575 .54 .4 .4])
        imagesc(matVals);
        colorbar
        title('Luminance values per frame');
        subplot(2,2,3,'position', [0.075 0.05 .4 .4])
        plot(matVals(:));
        title('Luminance values vector');
        subplot(2,2,4,'position', [.575 0.05 .4 .4])
        hold on
        plot(matVals(:));
        plot(median(xlim),abs(mean(matVals(:))),'rx','LineWidth',3)
        hold off
        title('Average Pupil Luminance');
        
        export_fig 'D:\Internship\Report\Eye Tracking Pictures\Determine Pupil luminance value' -tiff -pdf -eps
    end
end