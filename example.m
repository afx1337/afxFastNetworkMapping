clear
clc

connectome = 'connectomes/GSP1000/dataset_info.mat';

rois(1).name = '10';
rois(1).type = 'image';
rois(1).file = '/path/10.nii';
rois(2).name = '11';
rois(2).type = 'image';
rois(2).file = '/path/11.nii';
rois(3).name = '12';
rois(3).type = 'image';
rois(3).file = '/path/12.nii';
rois(4).name = 'aIFG';
rois(4).type = 'sphere';
rois(4).coords = [-54 26 4];
rois(4).radius = 5;
rois(5).name = 'M1_right';
rois(5).type = 'atlas';
rois(5).file = '/path/BNA.nii';
rois(5).pick = 156;

options.gmMask = 'masks/gmmask_20_ext.nii';
options.maxParticipants = Inf;
options.compressNii = true;

destFolder = 'results/test1';

addpath('scripts');
afxFastNetworkMapping(connectome, rois, options, destFolder);
rmpath('scripts');
