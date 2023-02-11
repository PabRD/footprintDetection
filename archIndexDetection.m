%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
%        NAME: Footprint Detection                                        %
%        AUTHOR: Pabdawan Matlab                                          %
%        DATE: Novembre 2022                                              %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Description: footprint detection and Arch Index calculation
tic
clear
close all
clc

initialPath = pwd;
currentDir = dir(initialPath);
fileList = {currentDir.name};
fileList = fileList(3:end);
name = cellfun(@(x) extractBefore(x,'.'),fileList,'uni',0);

ds = imageDatastore(initialPath);
for i = 1:length(ds.Files)

    [data,imInfo] = readimage(ds,i);
    % imshow(data)

    %% Pre Processing
    % close all
    % f= figure;
    % f.WindowState = 'maximized';
    % t =tiledlayout(2,3);
    %
    % nexttile
    % imshow(data);
    % title('Original Image', 'Interpreter', 'latex');
    %
    % nexttile([1 2])
    % histogram(data(data>0), 256);
    % grid on;
    % title('Histogram of Image Gray Levels', 'Interpreter', 'latex');



    %% Binarize
    grayIMG=im2gray(data);

    % improve contrast
    edgeThreshold = 0.8;   % 0.8  a la base
    amount = 0.4;   % 0.4  a la base
    AdjGrayIMG = localcontrast(grayIMG, edgeThreshold, amount);

    % contrastIM = imadjust(AdjGrayIMG);
    % nexttile
    % imshow(contrastIM)
    % I = contrastIM;
    % title('Contrasted image', 'Interpreter', 'latex');
    % [counts,x] = imhist(I,16);

    % OtsuMask = otsuthresh(counts);
    % BW = imbinarize(I,OtsuMask);
    % nexttile
    % imshow(BW)
    % title('Otsu Thresholding Method', 'Interpreter', 'latex');


    BW = imbinarize(AdjGrayIMG,"adaptive","ForegroundPolarity","dark");
    % nexttile
    % imshow(BW)
    % title('Bradley Thresholding Method', 'Interpreter', 'latex');
    %
    % t.TileSpacing = 'compact';
    % t.Padding = 'compact';

    %% Erode, Dilate and smooth
    % f2 = figure;
    % f2.WindowState = 'maximized';
    % t2 = tiledlayout(2,4);

    windowSize = 20;
    se = zeros(windowSize,windowSize);
    se(ceil(windowSize/2), :) = 1;
    se(:, ceil(windowSize/2)) = 1;
    mask = imerode(BW, se);                                                     % Erode
    % nexttile
    % imshow(mask)
    % title('Erode','Interpreter','latex')

    windowSize = 25;
    se = zeros(windowSize,windowSize);
    se(ceil(windowSize/2), :) = 1;
    se(:, ceil(windowSize/2)) = 1;
    mask = imdilate(mask, se);                                                  % Dilate
    mask = imclearborder(not(mask));                                            % Clear borders
    % nexttile
    % imshow(mask)
    % title('dilate and clear borders','Interpreter','latex')


    % Fill in the mask.
    mask = imfill(mask, 'holes');
    % nexttile
    % imshow(mask)
    % title('fill holes','Interpreter','latex')

    % Smooth it some more.
    windowSize = 21;            % 21 de base
    kernel = ones(windowSize)/ windowSize^2;
    mask = conv2(double(mask), kernel, 'same');
    mask = mask > 0.5;

    % erode again
    windowSize = 18;
    se = zeros(windowSize,windowSize);
    se(ceil(windowSize/2), :) = 1;
    se(:, ceil(windowSize/2)) = 1;
    mask = ~imerode(~mask,se);

    mask = imfill(mask, 'holes');
    % nexttile
    % imshow(mask)
    % title('smooth','Interpreter','latex')

    %% Removing what's not feet

    imProps = regionprops(mask,'basic');                                        % properties of objects : aerea, bounding box and centroids
    objectsAera = [imProps.Area];                                               % objects area
    nbGrossesFormes = sum(objectsAera>100000);                                  % how many big objects we have ?

    imCentroids = [imProps.Centroid];                                           % centroids
    imDim = size(data);                                                         % image dimension

    if nbGrossesFormes>2
        fourObjects = bwareafilt(mask,nbGrossesFormes);
        finalImage = fourObjects;
    else
        twoObjects = bwareafilt(mask,2);
        finalImage = twoObjects;
    end

    % nexttile
    % imshow(finalImage)
    % hold on
    % title('keep biggest forms','Interpreter','latex')
    % info = regionprops(finalImage,'Boundingbox') ;
    % for k = 1 : length(info)
    %      BB = info(k).BoundingBox;
    %      rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2) ;
    %      xCentroid{k} = BB(1) + BB(3)/2;
    %      yCentroid{k} = BB(2) + BB(4)/2;
    % end

    %% Watershed transform to remove toes
    D = -bwdist(~finalImage);
    mask = imextendedmin(D,20);
    D2 = imimposemin(D,mask);
    Ld2 = watershed(D2);

    Lrgb = label2rgb(Ld2,'jet','w','shuffle');

    bw3 = finalImage;
    bw3(Ld2 == 0) = 0;
    % nexttile
    % imshow(bw3)
    % title('Watershed segmented image','Interpreter','latex')
    % hold on
    % himage = imshow(Lrgb);
    % himage.AlphaData = 0.3;

    % above image middle we detect small objects (toes)
    midImage = size(bw3,1)/2-200;

    prepNumZone = ones(size(bw3));
    prepNumZone(Ld2 == 0) = 0;
    prepNumZone = prepNumZone(1:floor(midImage),:);

    zonesBoundaries = bwboundaries(prepNumZone);
    numZones = size(zonesBoundaries, 1);
    zoneaRetirer = numZones-2;

    scndAreaFilt = regionprops(bw3,"basic");
    numberObjects = numel([scndAreaFilt.Area]);
    threshold = 0.05*sum([scndAreaFilt.Area]);


    if zoneaRetirer==0
        newImage=finalImage;
    else
        sansorteils2 = bwareafilt(bw3,[0 threshold]);                           %Detect small objects
        newImage = finalImage - sansorteils2;
    end

    newImage = bwareaopen(newImage,400);                                        % remove last small objects

    % nexttile
    % imshow(newImage)
    % title('final footprint ready to process','Interpreter','latex')

    %% Plot footprint edge on original image
    % nexttile
    % imshow(data)
    % boundaries = bwboundaries(newImage);
    % numberOfBoundaries = size(boundaries, 1);
    % hold on;
    % for k = 1 : numberOfBoundaries
    %     thisBoundary = boundaries{k};
    %     x = thisBoundary(:,2);
    %     y = thisBoundary(:,1);
    %     plot(x, y, 'r-', 'LineWidth', 2);
    % end
    % hold off;
    % caption = sprintf('Original image and its %d edges', numberOfBoundaries);
    % title(caption,'Interpreter','latex');
    % axis('on', 'image');
    % t2.Padding ="compact";
    % t2.TileSpacing = "compact";

    %% Arch index (AI) Cavagnah et al., 1987
    % AI = B / (A + B + C)
    % Interpretation: (Chu et al., 1995) Arch Index <0.17 high | >0.25 low

    %figure
    AIdata = logical(newImage);
    %title('Foot divided in three parts to calculate Arch Index')
    %hold on
    
    %area of 2 differents objects
    footprintProps = regionprops(AIdata,'basic');
    globalArea = [footprintProps.Area];

    footprintBoundigBox = {footprintProps.BoundingBox};
    rectangleHeight = cellfun(@(x) x(4),footprintBoundigBox);
    rectangleWidth = cellfun(@(x) x(3),footprintBoundigBox);

    positionInitialePied = cell2mat(cellfun(@(x) x(1:2)',footprintBoundigBox,'uni',0));
    coordXInitialePied = cell2mat(cellfun(@(x) x(1)',footprintBoundigBox,'uni',0));

    %% Cluster data
    T1 = clusterdata(coordXInitialePied',2); % 2 clusters (un cluster de forme a gauche , et un cluster de formes a droite
    meanXcoordBaseRectangle = splitapply(@mean,coordXInitialePied',T1);
    [~,indPosRectangleGauche] = min(coordXInitialePied);
    coordXSplitImage = (min(coordXInitialePied) + rectangleWidth(indPosRectangleGauche)) + abs((min(coordXInitialePied) + rectangleWidth(indPosRectangleGauche)) - max(meanXcoordBaseRectangle))/2;

    %% Dividing in two separate images
    [AIpiedIndiv{1:2}] = deal(zeros(size(AIdata)),zeros(size(AIdata)));

    AIpiedIndiv{1}(:,1:floor(coordXSplitImage)) = AIdata(:,1:floor(coordXSplitImage));
    AIpiedIndiv{2}(:,floor(coordXSplitImage):end) = AIdata(:,floor(coordXSplitImage):end);
    
    indDeb = 1;
    indFin = floor(coordXSplitImage);

    [AIDeuxTiers{1:2}] = deal(zeros(size(AIdata)),zeros(size(AIdata)));
    [aireTotale,footprintTiers,aireDeuxtiers,archIndex] = deal(cell(1,2));
    for k = 1:2

        aireTotale{k} = bwarea(AIpiedIndiv{k});
        [yAI, ~] = find(AIpiedIndiv{k});
        hMaxAI = max(yAI);
        hMinAI = min(yAI);
        longueurGauche = hMaxAI - hMinAI;
        footprintTiers{k} = round(longueurGauche/3);
        AIDeuxTiers{k}(hMinAI + footprintTiers{k} : hMaxAI-footprintTiers{k},indDeb:indFin) = AIpiedIndiv{k}(hMinAI + footprintTiers{k} : hMaxAI-footprintTiers{k},indDeb:indFin);
        aireDeuxtiers{k} = bwarea(AIDeuxTiers{k});
        archIndex{k} = aireDeuxtiers{k} / aireTotale{k};

        indDeb = indDeb + indFin;
        indFin = size(AIdata,2);

    end


    %% visualisation / debug
    prepVisuPied = AIDeuxTiers{1}+AIDeuxTiers{2};
    tiersrgb = label2rgb(AIdata+prepVisuPied,[0.4 0.4 0.4;0.2 0.2 0.2],'k','noshuffle');
%     maskTiers = imshow(tiersrgb);
%     maskTiers.AlphaData = 0.6;

    captionAI1 = sprintf('Arch Index = %1.2f ', archIndex{1});
    captionAI2 = sprintf('Arch Index = %1.2f ', archIndex{2});

%     text(meanXcoordBaseRectangle(1),200,captionAI1,'Color','w','Interpreter','latex','FontWeight','bold','FontSize',10)
%     text(meanXcoordBaseRectangle(2),200,captionAI2,"Color",'w','Interpreter','latex','FontWeight','bold','FontSize',10)

%     [xCentroid,yCentroid] = deal(cell(1,length(globalArea)));
%     for k = 1 : length(globalArea)
%         BB = footprintProps(k).BoundingBox;
%         rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],'EdgeColor','r','LineWidth',2) ;
%         xCentroid{k} = BB(1) + BB(3)/2;
%         yCentroid{k} = BB(2) + BB(4)/2;
%     end

result(i).AIleft = archIndex{1};
result(i).AIright = archIndex{2};

end
toc
