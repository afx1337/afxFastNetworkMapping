clear
clc

addpath('scripts');

connectome = 'connectomes/GSP1000/dataset_info.mat';

rois(1).name = 'aIFG';
rois(1).type = 'sphere';
rois(1).coords = [-54 26 4];
rois(1).radius = 7;
rois(2).name = 'aMTG';
rois(2).type = 'sphere';
rois(2).coords = [-54 -7 -14];
rois(2).radius = 7;
rois(3).name = 'pMTG';
rois(3).type = 'sphere';
rois(3).coords = [-51 -31 4];
rois(3).radius = 7;

options.gmMask = 'masks/gmmask_20_ext.nii';
options.maxParticipants = 3;
options.compressNii = true;

destFolder = 'results/test1';

afxFastNetworkMapping(connectome, rois, options, destFolder);

clear options;
options.maxParticipants = 3;
options.compressNii = false;

destFolder = 'results/test2';
afxFastNetworkMapping(connectome, rois, options, destFolder);

clear options;
options.maxParticipants = 3;
options.compressNii = false;
options.targetRois = rois;

destFolder = 'results/test3';

afxFastNetworkMapping(connectome, rois, options, destFolder);

rmpath('scripts');
