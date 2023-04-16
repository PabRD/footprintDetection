# footprintDetection
This script detect footprints and calculates Arch Index (Cavanagh et al. 1987)
25 images are available. You can run the code with the .m directly in the raw image folder.

There is different steps with figures:
rbg image to gray image and improving contrast :

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_Binarize.png)

Erode, dilate, smooth, watershed segmentation:

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_Steps.png)

Arch Index calculation:

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_ArchIndexFinal.png)

