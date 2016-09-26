# Radial Eye-Tracking
A complete toolbox for performing eye tracking in rodents. 

The root folder with the data should contain the folder 'Raw' in which video files (AVI, MP4 and MPG are supported) are organized in subfolders per experiment. The script BuildPreProBatch will scan the Raw folder for video files and create a Queue file in the root directory, this file keeps track of all the sessions that need to be processed. After creation of a Queue-file the script BatchProcess uses this information to first pre-process the raw video files and then execute the eye tracking algorithm. 

During pre-processing the user should define a rectangular cropping window around the eye, smaller windows result in smaller file sizes. After the initial rectangular window a custom shaped selection of the eye itself should be made, make sure to make the selection as precise as possible to guarantee best tracking results. After cropping of the video file and saving to a MAT file, the user should indicate the start and end times of the eye-tracking video. This is done by selecting the first and last frame in which there was an image on the video, so you can indicate the start and end of the experiment by either turning the camera on and off or by switching your IR illumination off before and after the recording session.

The eye tracking algorithm works as follows. Every frame is smoothed using a Gaussian filter algorithm. To find the center of the pupil a fast radial symmetry transform is implemented (FRST; Loy and Zelinsky, 2003) and the center point is determined as the highest value of the FRST. A sobel filter is applied to find the edge of the pupil. From the center a number of rays is projected in different directions with equal radial distance (Li et al, 2005). Per ray the edge of the pupil is determined as the maximum value of the sobel transform, edge points with a distance > 2 S.D. from the center are excluded. An ellipse is fitted on the remaining edge points using an ellipse fitting algorithm written by Richard Brown.

After eye-tracking is complete the results are saved in /CroppedVideos and can be evaluated using the script runPupilPostProcessing.

Contributors

Guido Meijer, Stephan Grzelkowski, Gwylan Scheeren, Jorrit Montijn

Cognitive & Systems Neuroscience Lab, University of Amsterdam

References

Li, D., Winfield, D., and Parkhurst, D.J. (2005). Starburst: A hybrid algorithm for video-based eye tracking combining feature-based and model-based approaches. In 2005 IEEE Computer Society Conference on Computer Vision and Pattern Recognition (CVPR’05)-Workshops, (IEEE), pp. 79–79.

Loy, G., and Zelinsky, A. (2003). Fast radial symmetry for detecting points of interest. IEEE Transactions on Pattern Analysis and Machine Intelligence 25, 959–973.


