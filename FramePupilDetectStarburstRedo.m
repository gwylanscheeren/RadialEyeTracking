function sEyeTracking = FramePupilDetectStarburstRedo(cfg,N,radii,o)
% Reprocesses the sEyeTracking for time frame chosen in
% runPupilPostProcessingStarburst
%
%   SYNTAX
%       sEyeTracking = FramePupilDetect(cfg,N,radii,o)
%       
%   INPUT
%       cfg: Configuration struct containing meta data and settings for the session that will be processed.
%           As found in the Queuefile created by BuildPreProBatch.
%       N: Number of rays used in starburst algorithm; The higher N the
%           more accurate the ellipse fit and outlier detection, in turn
%           increasing computation time. Advised values are 16 for initial
%           Process and 32 in reprocess
%       radii: used radii to calculate the point of highest symmetry using
%           the fast radial symmetry transform in number of pixels; choice 
%           depends on number of pixels expected to be containing the
%           pupil; advised default is 5:2:21;
%       o: multiplier of standard deviation used in the outlier detection
%           of edge detection procedure; A higher value results in better 
%           estimation of pupil area but can results in fitellipse not being 
%           able to find an ellipse fit; Choice depends on accuracy of edge
%           and center point detection; If both are accurate a higher
%           value can be chosen.
%           
%              
%
%   OUTPUT
%       sEyeTracking: struct containing the following fields
%           strSes: session name
%           strRec: consecutive recording name
%           intRec: number of recordings   
%           vecPosX: 1 x F vector with pupil centre x coördinate per frame F
%           vecPosY: 1 x F vector with pupil centre y coördinate per frame F
%           vecArea: 1 x F vector with pupil squared area per frame F
%           vecZ, vecA, vecB, vecAlpha: calculated by fitellipse, used for plotellipse and Area calulation 
%           vecEvents: vector for detecting eye saccades and blinks [formula: abs( zscore(vecPupilLuminance) .* zscore(vecArea) )]
%           indEvents: logical vector indicating eye saccades and blinks determined as vecEvent values above 4
%           Frame: frame selection cut-off points [start stop] frames
%
%   DEPENDS ON
%       getTime
%       sec2hmsstring
%       Image Processing Toolbox
%       Statistics Toolbox
%       fitellipse
%       frst2d
%
%   VERSIONS
%       Adapted by Gwylan Scheeren |21|3|2015| Universiteit van Amsterdam
%       18-4-2015 Added ROI selection mask
%       12-7-2015 Changed minimal number of pixels threshold for pupil requirement of 3.3%
%               from whole frame to 3.3% of the region of interest
%       Modified by Stephan Grzelkowski (07/03/2016) Universiteit van Amsterdam 
%               Changed pupil detection method using Sobel Transform for
%               edge detection and a starburst approach
%     
%      




warning('off','all')

%Preassign directional filters for Sobel filtering
filterX = [-1 0 1;-2 0 2;-1 0 1];
filterY = [-1 -2 -1;0 0 0;1 2 1];


%% 
%supress warnings about graphics versions
if verLessThan('matlab', '8.4')
    warning('off','YMA:export_fig:issue45')
else
    warning('off','MATLAB:graphicsversion:GraphicsVersionRemoval')
end




%%
sLoad = load(cfg.CroppedVideo);


CropFrame = cfg.Eyetrack.CropFrame;

if isfield(cfg.Eyetrack,'TimeFrame')
    TimeFrame = cfg.Eyetrack.TimeFrame;
else
    TimeFrame = [1 CropFrame(2)-CropFrame(1)+1];
end

if isfield(cfg.Eyetrack,'ROImask') && ~isempty(cfg.Eyetrack.ROImask)
    ROImask = cfg.Eyetrack.ROImask;
else
    ROImask = sLoad.sVideoAll.ROImask;
end

% determine the cut -off point that was used in the pre-processing step of cropping the movie size- and time-wise
intFrames = TimeFrame(2)-TimeFrame(1)+1;
FrameStart = TimeFrame(1); FrameStop = TimeFrame(2);


%% Perform Eye-tracking on specified Time-Frame

%crop movie to selected time points +/- intPupFrameRange, using the frame offset between cropped movie and first frame used for eye-tracking

matMovie = sLoad.matMovie(:,:,CropFrame(1):CropFrame(2));

clear sLoad

% pre allocate for gaussian filter
matMovie_h = zeros(size(matMovie));


% apply gaussian filter for every frame
for f = 1 : size(matMovie,3)
    matMovie_h(:,:,f) = imgaussfilt(matMovie(:,:,f),2);
end


%pre-allocate output

vecPosX = cfg.sOldEyeTracking.vecPosX;
vecPosY = cfg.sOldEyeTracking.vecPosY;
vecArea = cfg.sOldEyeTracking.vecArea;
vecZ = cfg.sOldEyeTracking.vecZ;
vecA = cfg.sOldEyeTracking.vecA;
vecB = cfg.sOldEyeTracking.vecB;
vecAlpha = cfg.sOldEyeTracking.vecAlpha;
dist_std_all = NaN(size(matMovie,3),1);

[m,n,~] = size(matMovie);

%Init progress display 
curProg = 5;

%loop through frames for detection
for k = FrameStart : FrameStop
    
    if ~isnan(vecArea(k))
        %apply the ROI mask to the current frame
        matFrame = ROImask.*mat2gray(matMovie_h(:,:,k));
        
        %apply radial transform on the current frame
        f = frst2d(matFrame,radii,10, 0.25, 'bright');
        
        %find the center point of the pupil from symmetry transform
        [cy,cx] = find(f == max(max(f)));
        
        
        [x,y] = meshgrid(1:n,1:m);
        
        %center meshgrid for the centerpoint of the symmetry transform
        x = x - cx;
        y = y - cy;
        
        
        %polar transform around center point
        [theta,rho] = cart2pol(x,y);
        
        
        %% Ray Projection
        
        
        %preassign matrices for sobel thressholding and intersect coordinates
        idx_threshhold = NaN(N,1);
        xcoord = NaN(N,1);
        ycoord = NaN(N,1);
        dist = NaN(N,1);
        j = 1;
        
        % loop through all the rays with N number of rays
        for i = -pi + (pi / (N / 2)): (pi / (N / 2))  : pi
            
            idxRay = find(theta >= i - 0.1 & theta <= i + 0.1);
            
            rayInt = matFrame(idxRay);
            
            idxRay = idxRay(rayInt ~= 0);
            
            
            %apply directional filters
            Sx = imfilter(matFrame,filterX);
            Sy = imfilter(matFrame,filterY);
            S = sqrt(Sx.^2 + Sy.^2);
            
            
            rho_idx_comb = zeros(length(idxRay),2);
            rho_idx_comb(:,1) = rho(idxRay);
            rho_idx_comb(:,2) = idxRay;
            rho_idx_sort = sortrows(rho_idx_comb);
            idx_sort = rho_idx_sort(:,2);
            
            
            rest = 1 : floor(length(idx_sort) * 0.75) ;
            idx_rest = idx_sort(rest);
            idx_thresh = idx_rest(S(idx_rest) == max(S(idx_rest)));
            
            if isempty(idx_thresh) && ~isempty(idx_sort)
                idx_thresh = idx_sort(length(idx_sort));
            end
            
            if ~isempty(idx_thresh)
                idx_threshhold(j) = idx_thresh(1);
                dist(j) = rho(idx_thresh(1));
                xcoord(j) = x(idx_thresh(1));
                ycoord(j) = y(idx_thresh(1));
            end
            
            %update n
            j = j + 1;
            
        end
        
        
        %% Ellipse fitting
        
        
        mean_dist = mean(dist);
        std_dist = std(dist);
        dist_std_all(k) = std_dist;
        
        idx_outliers = find(dist <= mean_dist - (std_dist * o) | dist >= mean_dist + (std_dist * o) );
        %dist(idx_outliers) = [];
        xcoord(idx_outliers) = [];
        ycoord(idx_outliers) = [];
        
        %Decenter the data back to original coordinates
        xcoord = xcoord + cx;
        ycoord = ycoord + cy;
        
        
        
        %store coordinates in ellipse for fit function
        ellipse_coord = NaN(2,length(xcoord));
        ellipse_coord(1,:) = xcoord';
        ellipse_coord(2,:) = ycoord';
        
        %remove columns with nans to avoid errors of ellipse fitting
        [~, column]=find(isnan(ellipse_coord));
        ellipse_coord(:,column) = [];
        
        
        %plot the ellipse if its plottable
        try
            [z, a, b, alpha] = fitellipse(ellipse_coord);
            %calculate and save pupil area
            pupilArea = a * b * pi;
            vecArea(k) = pupilArea;
            vecZ(k,:) = z;
            vecA(k) = a;
            vecB(k) = b;
            vecAlpha(k) = alpha;
            vecPosX(k) = z(1);
            vecPosY(k) = z(2);
        catch
            
        end
    end
    
    %Print progress in command window 
    progress = round(((k - FrameStart + 1) / intFrames) * 100);
    
    if (mod(progress,5) == 0) && progress == curProg 
        fprintf('%d%% of the pupil detection has been completed\n',progress)
        curProg = curProg + 5;
    end
    
    
end




%put in output structure
sNewEyeTracking = struct();
sNewEyeTracking.strSes = cfg.strSes;
sNewEyeTracking.strRec = cfg.strRec;
sNewEyeTracking.intRec = str2double(cfg.strRec(end-1:end));
sNewEyeTracking.vecZ = vecZ; 
sNewEyeTracking.vecPosX = vecPosX;
sNewEyeTracking.vecPosY = vecPosY;
sNewEyeTracking.vecA = vecA;
sNewEyeTracking.vecB = vecB;
sNewEyeTracking.vecArea = vecArea;
sNewEyeTracking.Frame = CropFrame;
sNewEyeTracking.vecAlpha = vecAlpha;
sNewEyeTracking.matMask = cfg.sOldEyeTracking.matMask;

sEyeTracking = sNewEyeTracking;

% restore warnings
warning('on','all')
end


















