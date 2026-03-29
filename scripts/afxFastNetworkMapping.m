function afxFastNetworkMapping(connectomeFile, rois, options, destFolder)
    % afxFastNetworkMapping(connectomeFile, rois, options, destFolder)
    %
    % A very fast network mapping implementation compatible with LeadDBS connectomes
    % (tested with GSP1000).     % Features mean seed to whole brain and seed to
    % target connectivity. Computation times depend on used hardware, but are mostly
    % in the range of 0.5 - 3 hours for typical setups and up to several 1,000 ROIs.
    %
    % connectomeFile   - LeadDBS compatible connectome file
    %
    % rois             - struct array of regions of interest
    % .name            - name will become filename of nifti
    % .type            - 'image'|'sphere'|'atlas'
    % .file            - filname for image or atlas
    % .coords          - 1x3 vec: MNI coordinates for spheres
    % .radius          - radius for spheres
    % .pick            - label for atlas (numeric value)
    %
    % options:
    % .gmMask          - filename of gm mask (default: empty)
    % .compressNii     - true|false (default: false)
    % .targetRois      - struct array of target rois (default: empty)
    %                    no whole brain maps are calculated if set
    % .maxParticipants - decrease connectome for testing purposes (default: Inf)
    %
    % destFolder       - results folder
    
    if ~isfield(options,'gmMask') options.gmMask = []; end
    if ~isfield(options,'targetRois') options.targetRois = []; end
    if ~isfield(options,'compressNii') options.compressNii = false; end
    if ~isfield(options,'maxParticipants') options.maxParticipants = Inf; end

    t0 = tic;
    fprintf('Fast network mapping\n - ROIs: %i\n',numel(rois));
    fprintf(' - gmMask: %s\n',options.gmMask);
    
    % load space
    connectome = afxPrepareConnectome(connectomeFile);
    connectome.dir = fileparts(connectomeFile);
    nParticipants = min(numel(connectome.vol.subIDs),options.maxParticipants);
    fprintf(' - connectome: %s\n',connectome.dir);
    fprintf(' - participants: %i/%i\n',nParticipants,numel(connectome.vol.subIDs));

    % load gm mask
    if ~isempty(options.gmMask)
        gmMask = afxVolumeResample(options.gmMask,connectome.vol.XYZmm,0) ~= 0;
    else
        gmMask = [];
    end
    
    % load roi masks
    roiData = afxLoadRois(rois, connectome, gmMask);
    if ~isempty(options.targetRois)
        targetRoiData = afxLoadRois(options.targetRois, connectome, gmMask);
    else
        targetRoiData = [];
    end

    % network mapping
    fprintf('\nNetwork mapping ...\n  ');
    conn = afxConn(connectome, roiData, targetRoiData, nParticipants);

    % saving
    if ~exist(destFolder,'dir') mkdir(destFolder); end
    if ~isempty(options.targetRois)
        % save conn matrix
        save(fullfile(destFolder,'conn.mat'),'conn');
    else
        % save all roi maps
        fprintf('\nWrite data to disk ...\n  ');
        rois = afxSaveNetworkMaps(conn,connectome.vol.outidx,connectome.vol.space.dim,connectome.vol.space.mat,rois,options.compressNii,destFolder);
    end
    
    % save further data
    siz = num2cell(sum(roiData,1));
    [rois.size] = deal(siz{:});
    meta = afxMetaData();
    meta.totalTimeMin = toc(t0)/60;
    save(fullfile(destFolder,'info.mat'), 'connectomeFile', 'rois', 'options', 'meta')
    
    fprintf('\nTotal time: %.1f minutes\n\n',meta.totalTimeMin);
end
