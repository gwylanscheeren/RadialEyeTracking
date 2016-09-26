# StarburstEyeTracking
Toolbox for performing eye tracking in rodents. 

Every frame is cropped using a manually fitted rectangle around the eye and a region of interest masks consisting of freely connected points fitted onto the eye, decreasing the required processing power of the algorithm. The resulting frames are smoothed using a Gaussian filter algorithm. To find the center of the pupil a fast radial symmetry transform is implemented (FRST; Loy and Zelinsky, 2003) and the center point is determined as the highest value of the FRST. A sobel filter is applied to find the edge of the pupil.
         
From the center a number of rays is projected in different directions with equal radial distance. Per ray the edge of the pupil is determined as the maximum value of the sobel transform, edge points with a distance > 2 S.D. from the center are excluded. An ellipse is fitted on the remaining edge points using an ellipse fitting algorithm written by Richard Brown (2015).  

