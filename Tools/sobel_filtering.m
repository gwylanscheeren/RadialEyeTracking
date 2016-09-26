% sobel example 


frame = 9100; 

%Create example image as grayscale and ONLY OVER MASK AREA 
example = Queue(1).cfg.Eyetrack.ROImask.*mat2gray(matMovie_h(:,:,frame));

example_sobel = edge(example,'sobel');
figure; 
imshow(example_sobel)
title(frame)