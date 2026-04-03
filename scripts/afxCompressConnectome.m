function afxCompressConnectome(connectomePtrn, dimensions, nTotal, nComponents, destDir)
    % afxCompressConnectome: Use RAM-efficient Group PCA (MIGP) to achieve
    % low rank matrix approximation of connectome
    %
    % This function implements a memory-efficient, incremental group-level PCA
    % (MIGP, Smith et al., 2014, NeuroImage) across multiple subjects.
    % It avoids storing all subjects' time-series simultaneously, which is
    % crucial for large datasets such as HCP.
    %
    % afxCompressConnectome(connectomePtrn, dimensions, nTotal, nComponents, destDir)
    %
    % Inputs:
    %   connectomePtrn   pattern for bold files (.mat), date needs to have
    %                    meen of 0 and 2-norm of 1 per voxel
    %   dimensions       [nTimepoints nVox] (needed for RAM management)
    %   nTotal           sum of timepoints in all runs (for proper scaling)
    %   nComponents      number of components to retain (~ RAM)
    %   destDir          directory for compressed connectome
    %
    % Outputs:
    %   batchxxx.mat
    %   dataset_info.mat
    %
    % Example:
    %   afxCompressConnectome('connectomes\HCP98_GSR_FWHM5\*_Rest_*.mat',[1200 222060],232595,150,'connectomes\HCP98_GSR_FWHM5_PCA150');
    %
    % References:
    %   Smith, S. M., Hyvärinen, A., Varoquaux, G., Miller, K. L., & Beckmann, C. F.
    %   (2014). Group-PCA for very large fMRI datasets. NeuroImage, 101, 738-749.
    %   https://doi.org/10.1016/j.neuroimage.2014.07.051

    d = dir(connectomePtrn);
    
    %% randomized order of included runs
    nRuns = numel(d);
    d = d(randperm(nRuns));

    fprintf('Calculating group PCA (MIGP) ...\n');
    
    %% initialize W
    W = nan((ceil(nComponents/dimensions(1))+1)*dimensions(1),dimensions(2),'single');
    i = 1;
    idxEnd = 1;
    while idxEnd-1 < nComponents+1
        fprintf('Run %i/%i\n',i,nRuns);
        load(fullfile(d(i).folder,d(i).name),'gmtc');
        idxCur = size(gmtc,2);
        W(idxEnd:idxEnd+idxCur-1,:) = (gmtc * sqrt(idxCur / nTotal))'; %  -> global norm
        idxEnd = idxEnd+idxCur;
        i = i + 1;
    end
    fprintf('--\n');
    
    %% MIGP loop over all other subjects
    for j = i:nRuns
        fprintf('Run %i/%i\n',j,nRuns);
        load(fullfile(d(j).folder,d(j).name),'gmtc');
        idxCur = size(gmtc,2);
        W(idxEnd:idxEnd+idxCur-1,:) = (gmtc * sqrt(idxCur / nTotal))';
        idxEnd = idxEnd+idxCur;
        
        %Wc = [W; gmtc'];
        
        [Utemp, ~] = eigs(double(W(1:idxEnd-1,:)*W(1:idxEnd-1,:)'), nComponents*3, 'largestreal');
        W(1:nComponents*3,:) = Utemp' * W(1:idxEnd-1,:);
        idxEnd = nComponents*3 + 1;
    end
    
    %% keep nComponents, scale
    W_group = W(1:nComponents,:);
    clear W;

    %% load old dataset_info.mat
    [p,~,~] = fileparts(connectomePtrn);
    load(fullfile(p,'dataset_info.mat'),'dataset');
    dataset.vol.subIDs = {};
    dataset.descrip = 'functional connectome';
    dataset.type = 'fMRI_pca';
    dataset.isScaled = true;
    
    %% save spatial loadings normalized to std to nii
    fprintf('Save data ...\n');
    blockSize = 600; % (~ 500 MB per ~250000 voxels)
    if ~exist(destDir,'dir')
        mkdir(destDir);
    end
    for i = 1:ceil(nComponents/blockSize)
        gmtc = W_group((i-1)*blockSize+1:min(i*blockSize,nComponents),:)';
        fname = sprintf('batch_%03i.mat',i);
        save(fullfile(destDir, fname), 'gmtc', '-v7.3', '-nocompression');
        dataset.vol.subIDs{i}{1} = i;
        dataset.vol.subIDs{i}{2} = fname;
    end
    save(fullfile(destDir,'dataset_info.mat'),'dataset');

    fprintf('Done.\n');
end
