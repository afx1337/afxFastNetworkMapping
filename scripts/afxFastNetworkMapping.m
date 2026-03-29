function afxFastNetworkMapping(connectomeFile, rois, options, destFolder)
    % afxFastNetworkMapping(connectomeFile, rois, options, destFolder)
    
    if ~isfield(options,'gmMask') options.gmMask = []; end
    if ~isfield(options,'compressNii') options.compressNii = false; end
    if ~isfield(options,'maxParticipants') options.maxParticipants = Inf; end

    t0 = tic;
    fprintf('Fast network mapping\n - ROIs: %i\n',numel(rois));
    fprintf(' - gmMask: %s\n',options.gmMask);
    
    % load space
    connectomeDir = fileparts(connectomeFile);
    connectome = afxPrepareConnectome(connectomeFile);
    nParticipants = min(numel(connectome.vol.subIDs),options.maxParticipants);
    fprintf(' - connectome: %s\n',connectomeDir);
    fprintf(' - participants: %i/%i\n',nParticipants,numel(connectome.vol.subIDs));

    % load gm mask
    if ~isempty(options.gmMask)
        gmMask = afxVolumeResample(options.gmMask,connectome.vol.XYZmm,0) ~= 0;
    else
        gmMask = [];
    end
    
    % load roi masks
    roiData = afxLoadRois(rois, connectome, gmMask);

    % network mapping
    fprintf('\nNetwork mapping ...\n  ');
    meanZ = afxConn(connectome, connectomeDir, rois, roiData, nParticipants);

    % save all roi maps
    fprintf('\nWrite data to disk ...\n  ');
    rois = afxSaveNetworkMaps(meanZ,connectome.vol.outidx,connectome.vol.space.dim,connectome.vol.space.mat,rois,options.compressNii,destFolder);
    
    % save further data
    siz = num2cell(sum(roiData,1));
    [rois.size] = deal(siz{:});
    meta = afxMetaData();
    meta.totalTimeMin = toc(t0)/60;
    save(fullfile(destFolder,'info.mat'), 'connectomeFile', 'rois', 'options', 'meta')
    
    fprintf('\nTotal time: %.1f minutes\n',toc(t0)/60);
end