%FramePupilDetect acquires pupil metrics, such as position, roundness, weight and luminance using getPupilColor
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


function sEyeTracking = FramePupilDetect(cfg,N,radii,o)
t = tic; 

%Initialize default settings
if nargin < 2
    N = 16;
    radii = 5:2:21;
    o = 2;
elseif nargin < 3
    radii = 5:2:21;
    o = 2;
elseif nargin < 4
    o = 2;
end    

%Preassign directional filters for Sobel filtering
filterX = [-1 0 1;-2 0 2;-1 0 1];
filterY = [-1 -2 -1;0 0 0;1 2 1];

warning('off','all')

%supress warnings about graphics versions
if verLessThan('matlab', '8.4')
    warning('off','YMA:export_fig:issue45')
else
    warning('off','MATLAB:graphicsversion:GraphicsVersionRemoval')
end

%Load video data 
fprintf('Loading in cropped video data..\n')
sLoad = load(cfg.CroppedVideo);

CropFrame = cfg.Eyetrack.CropFrame;
FirstEyetrackFrameOffset = CropFrame(1)-1;

if isfield(cfg.Eyetrack,'TimeFrame')
    TimeFrame = cfg.Eyetrack.TimeFrame;
else
    TimeFrame = [1 CropFrame(2)-CropFrame(1)+1];
end

% determine the cut -off point that was used in the pre-processing step of cropping the movie size- and time-wise
intFrames = TimeFrame(2)-TimeFrame(1)+1;
FrameStart = TimeFrame(1); FrameStop = TimeFrame(2);
intPupFrameRange = 15;

%% Perform Eye-tracking on specified Time-Frame

%crop movie to selected time points +/- intPupFrameRange, using the frame offset between cropped movie and first frame used for eye-tracking
if TimeFrame(1) == 1
    matMovie = uint8(sLoad.matMovie(:,:,CropFrame(1):CropFrame(2)));
else
    croppingStart = FirstEyetrackFrameOffset + FrameStart - intPupFrameRange;
    croppingEnd = FirstEyetrackFrameOffset + FrameStop + intPupFrameRange;
    if croppingEnd > size(sLoad.matMovie,3); croppingEnd = size(sLoad.matMovie,3); end
    matMovie = uint8(sLoad.matMovie(:,:,croppingStart:croppingEnd));
end

matMovie = im2double(matMovie);
ROImask = cfg.Eyetrack.ROImask;
clear sLoad

% pre allocate for gaussian filter
matMovie_h = zeros(size(matMovie));

% apply gaussian filter for every frame
fprintf('Applying Gaussian filter to all frames..\n');
hFilt = fspecial('gaussian', [3 3], 1);
for f = 1 : size(matMovie,3)
    matMovie_h(:,:,f) = imfilter(matMovie(:,:,f), hFilt);
end

%pre-allocate output
vecPosX(FrameStart:FrameStop) = nan(1,intFrames);
vecPosY(FrameStart:FrameStop) = nan(1,intFrames);
vecArea(FrameStart:FrameStop) = nan(1,intFrames);
vecZ(FrameStart:FrameStop,:) = NaN(size(matMovie,3),2);
vecA(FrameStart:FrameStop) = NaN(size(matMovie,3),1);
vecB(FrameStart:FrameStop) = NaN(size(matMovie,3),1);
vecAlpha(FrameStart:FrameStop) = NaN(size(matMovie,3),1);
[m,n,~] = size(matMovie);
    
%create meshgrid with size equal to the selected area
intFrames = TimeFrame(2)-TimeFrame(1)+1;

%Init current progress for progress display
curProg = 5;
figure(1);

%loop through frames for detection
fprintf('Starting pupil detection..\n')
for k = FrameStart : FrameStop
    
    %apply the ROI mask to the current frame 
    matFrame = ROImask.*mat2gray(matMovie_h(:,:,k));
    
    %apply radial transform on the current frame
    if strcmp(cfg.strPupilColor, 'white')
        f = frst2d(matFrame,radii,10, 0.25, 'bright');
    elseif strcmp(cfg.strPupilColor, 'black')
        f = frst2d(matFrame,radii,10, 0.25, 'dark');
    else
        error('strPupilColor should be set to white or black');
    end
    
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
        
        %find points that are on a certain ray from center point        
        idxRay = find(theta >= i - 0.1 & theta <= i + 0.1);
        
        %assign intensitiy values of current frame
        rayInt = matFrame(idxRay);
        
        %remove indeces that lie outside ROI
        idxRay = idxRay(rayInt ~= 0);
        
        %apply directional filters for sobel transform (edge detection)
        Sx = imfilter(matFrame,filterX);
        Sy = imfilter(matFrame,filterY);
        S = sqrt(Sx.^2 + Sy.^2);
        
        %create a combined array of distance to center and idx of image and
        %sort based on distance to center point. This solves issues when finding the maximum, where
        %rays go in different directions 
        rho_idx_comb = zeros(length(idxRay),2);
        rho_idx_comb(:,1) = rho(idxRay);
        rho_idx_comb(:,2) = idxRay;
        rho_idx_sort = sortrows(rho_idx_comb);
        idx_sort = rho_idx_sort(:,2);
        
        %remove upper quartile of the array to find the maximum (if not the
        %maximum of the Sobel image can be the edge of the ROI mask
        rest = 1 : floor(length(idx_sort) * 0.75) ;
        idx_rest = idx_sort(rest);
        idx_thresh = idx_rest(S(idx_rest) == max(S(idx_rest)));
        
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
    
    %calculate mean and standard deviation and exclude outliers based on
    %distance to center point and std.dev multiplier "o"
    mean_dist = nanmean(dist);
    std_dist = nanstd(dist);
        
    idx_outliers = find(dist <= mean_dist - (std_dist * o) | dist >= mean_dist + (std_dist * o) );
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
    
    
    %calculate the ellipse points using fitellipse and save up fitellipse
    %can cause errors when data is not fittable. 
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
    
    %Print progress in command window 
    progress = round(((k - FrameStart + 1) / intFrames) * 100);
    
    if (mod(progress,5) == 0) && progress == curProg
        fprintf('%d%% of the pupil detection has been completed\n',progress)
        curProg = curProg + 5;
        figure(1); hold on; 
        imagesc(matMovie_h(:,:,k)); 
        colormap('grey'); axis ij; axis off;
        scatter(ellipse_coord(1,:),ellipse_coord(2,:),'xg');
        h = plotellipse(z,a,b,alpha);
        set(h, 'LineWidth', 2, 'Color', [1 0 0]);
        title(sprintf('Frame %d of %d [%d%%]', k, intFrames, progress));
        hold off;
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
sEyeTracking = sNewEyeTracking;

strDuration = sec2hmsstring(t);
fprintf('Finished processing %s%s in %s [%s]\n',cfg.strSes,cfg.strRec,strDuration,getTime);

% restore warnings
warning('on','all')
end