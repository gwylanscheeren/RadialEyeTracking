%test write video file

%NEEDS to have loaded the cropped video file and gaussian filtering as in
%ray_projection.m

close all
%Assign number of rays
N = 16;


%Outliers detection factor of std dev (of mean distance to center point 
o = 1; 



%Assign timewindow of video capture in frames
start = 13300;
stop = 14000;

%assign video writer and open for writing
v = VideoWriter('exampleVideo_gray_max_2');
open(v)

filterX = [-1 0 1;-2 0 2;-1 0 1];
filterY = [-1 -2 -1;0 0 0;1 2 1];

%preassign pupil area matrix
pupilArea_all = NaN((1 + (stop - start)),1);
%distance std 
dist_std = NaN((1 + (stop - start)),1);

for k = start : stop
    
    %apply mask
    example = sVideoAll.ROImask.*mat2gray(matMovie_h(:,:,k));
    
    %apply radial transform
    f = frst2d(example,[5 : 2 : 21],10, 0.25, 'bright');
    
    %find the center point of the pupil from symmetry transform
    [cy,cx] = find(f == max(max(f)));
    [m,n] = size(f);
    
    %create meshgrid
    [x,y] = meshgrid(1:n,1:m);
    
    
    %center meshgrid for the centerpoint
    x = x - cx;
    y = y - cy;
    
    
    %polar transform around center point
    [theta,rho] = cart2pol(x,y);
    
    
    %% Ray Projection
    
    
    %preassign matrices
    idx_threshhold = NaN(N,1);
    xcoord = NaN(N,1);
    ycoord = NaN(N,1);
    dist = NaN(N,1);
    j = 1;
    
    %create video file for writing
    
    % loop through all the rays with N number of rays
    for i = -pi + (pi / (N / 2)): (pi / (N / 2))  : pi
        
        idxRay = find(theta >= i - 0.1 & theta <= i + 0.1);
        
        rayInt = example(idxRay);
        
        idxNotZero = find(rayInt ~= 0);
        rayInt = rayInt(idxNotZero);
        example_ray = example(idxRay(idxNotZero));
        idxRay = idxRay(idxNotZero);
        
        
        %normalization of data
        example_ray_norm = example_ray / max(example_ray);
        
        
        %apply directional filters
        Sx = imfilter(example,filterX);
        Sy = imfilter(example,filterY);
        S = sqrt(Sx.^2 + Sy.^2);
        
        
        rho_idx_comb = zeros(length(idxRay),2);
        rho_idx_comb(:,1) = rho(idxRay);
        rho_idx_comb(:,2) = idxRay;
        rho_idx_sort = sortrows(rho_idx_comb);
        idx_sort = rho_idx_sort(:,2);
        
        
        rest = 1 : floor(length(idx_sort) * 0.75) ;
        idx_rest = idx_sort(rest);
        idx_thresh = idx_rest(S(idx_rest) == max(S(idx_rest)));
        
        if isempty(idx_thresh)
            idx_thresh = idx_sort(length(idx_sort));
        end
        
        idx_threshhold(j) = idx_thresh;
        dist(j) = rho(idx_thresh);
        xcoord(j) = x(idx_thresh);
        ycoord(j) = y(idx_thresh);
        
        %update n
        j = j + 1;
        
    end
    
    
    %% Ellipse fitting
    
    
    mean_dist = mean(dist);
    std_dist = std(dist);
    dist_std(k-start+1) = std_dist;
    
    idx_outliers = find(dist <= mean_dist - (std_dist * o) | dist >= mean_dist + (std_dist * o) );
    dist(idx_outliers) = [];
    xcoord(idx_outliers) = [];
    ycoord(idx_outliers) = [];
    
    %Decenter the data back to original coordinates
    xcoord = xcoord + cx;
    ycoord = ycoord + cy;
    
    
    
    %store coordinates in ellipse for fit function
    ellipse_coord = NaN(2,length(xcoord));
    ellipse_coord(1,:) = xcoord';
    ellipse_coord(2,:) = ycoord';
    
    
    
    %plot the ellipse if its plottable 
    try
        [z, a, b, alpha] = fitellipse(ellipse_coord);
        %calculate and save pupil area
        pupilArea = a * b * pi;
        pupilArea_all(k - start +1) = pupilArea;

        %plot frame, x and y coordinates for ray intersections and ellipse fit
        close(gcf)
        
        figure;
        imshow(mat2gray(matMovie(:,:,k)));
        hold on
        
        if a > 0 && b > 0
            hold on
            handle = plotellipse(z,a,b,alpha,'r');
            set(handle,'LineWidth',3)
        end

        hold on
        plot(xcoord,ycoord,'gx')
        plot(cx,cy,'bx')
        title(k)
        saveas(gcf,'output.jpg')
    catch
        close(gcf)
        figure;
        imshow(mat2gray(matMovie(:,:,k)));
        hold on 
        plot(xcoord,ycoord,'gx')
        plot(cx,cy,'bx')
        title(k)
        saveas(gcf,'output.jpg')
        
    end
    
    %% Write the video file
    img = imread('output.jpg');
    writeVideo(v,img);
    
end
close(v);