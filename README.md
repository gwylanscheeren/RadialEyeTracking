# StarburstEyeTracking
Toolbox for performing eye tracking in rodents. 

Every frame is cropped using a manually fitted rectangle around the eye and a region of interest masks consisting of freely connected points fitted onto the eye, decreasing the required processing power of the algorithm. The resulting frames are smoothed using a Gaussian filter algorithm. To find the center of the pupil a fast radial symmetry transform is implemented (FRST; Loy and Zelinsky, 2003) and the center point is determined as the highest value of the FRST. A sobel filter is applied to find the edge of the pupil.
         
From the center a number of rays is projected in different directions with equal radial distance (Li et al, 2005). Per ray the edge of the pupil is determined as the maximum value of the sobel transform, edge points with a distance > 2 S.D. from the center are excluded. An ellipse is fitted on the remaining edge points using an ellipse fitting algorithm written by Richard Brown.



References

Li, D., Winfield, D., and Parkhurst, D.J. (2005). Starburst: A hybrid algorithm for video-based eye tracking combining feature-based and model-based approaches. In 2005 IEEE Computer Society Conference on Computer Vision and Pattern Recognition (CVPR’05)-Workshops, (IEEE), pp. 79–79.

Loy, G., and Zelinsky, A. (2003). Fast radial symmetry for detecting points of interest. IEEE Transactions on Pattern Analysis and Machine Intelligence 25, 959–973.


