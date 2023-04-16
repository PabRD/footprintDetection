# footprintDetection
This script proposes footprints detection and Arch Index calculation (Cavanagh et al. 1987) from footprint photographs`.
25 images are available. You can run the code with the .m file directly in the raw image folder.


There is different steps with figures:
rbg image to gray image and improving contrast :

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_Binarize.png)

Erode, dilate, smooth, watershed segmentation:

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_Steps.png)

Arch Index calculation:

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_ArchIndexFinal.png)

Other exemple with the watershed transform:

![alt text](https://github.com/PabRD/footprintDetection/blob/main/gitHub_WatershedExemple.png)
