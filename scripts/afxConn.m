function meanZ = afxConn(connectome, roiData, targetRoiData, nParticipants)
    % meanZ = afxConn(connectome, roiData, targetRoiData, nParticipants)
    %
    % Calculates functional connectivity across whole connectomes.
    % Two formats of connectomes are supported defined by
    % connectome.isPCA:
    %
    %  false (default)  Preprocessed BOLD timeseries (LeadDBS compatible).
    %
    %  true             (Truncated) PCA representation of preprocessed BOLD
    %                   timeseries. This approach saves I/O operations due
    %                   to compression of the connectome data as well as
    %                   computation time as functional connectivity is
    %                   calculated in PCA (latent) space directly.
    
    if ~isfield(connectome,'isPCA'), connectome.isPCA = false; end

    % initialize group mean (total ram usage per roi ~ 2.2 Mb)
    if ~isempty(targetRoiData)
        nVox = size(targetRoiData,2);        % seed to target
    else
        nVox = numel(connectome.vol.outidx); % seed to whole brain
    end
    meanZ = zeros(nVox, size(roiData,2), 'single');

    % progress bar
    progress1pct = (numel([connectome.vol.subIDs{1:nParticipants}])-nParticipants) * .01;
    lastLen = afxPrintProgress(20, 0, 0, 0);
    totRun = 0;
    t = tic;

    for iParticipant = 1:nParticipants
        if connectome.isPCA
            % load PCA representation of bold signal
            totRun = totRun + 1;
            load(fullfile(connectome.dir, connectome.vol.subIDs{iParticipant}{2}), 'T', 'V');

            % Projection
            R = V' * roiData;   % (k x nROI)
            % Gram
            G = T' * T;   % (k x k)
            % Norm ROIs
            GR = G * R;
            sigma_roi = sqrt(sum(R .* GR, 1));

            if ~isempty(targetRoiData)
                % new "target" V in Roi-2-Roi mode
                V = targetRoiData' * V;   % (nTargetROI x k)
            end
            
            % Norm voxels/targets
            VG = V * G;
            sigma_target = sqrt(sum(VG .* V, 2));
            sigma_target(sigma_target < eps) = eps;
            sigma_roi(sigma_roi < eps) = eps;
            
            % correlation
            z = V * GR ./ (sigma_target * sigma_roi);
        else
            % load preprocessed bold signal for all available runs
            nRuns = numel(connectome.vol.subIDs{iParticipant});
            allRuns = cell(nRuns-1,1);
            for iRun = 2:nRuns
                totRun = totRun + 1;
                load(fullfile(connectome.dir, connectome.vol.subIDs{iParticipant}{iRun}),'gmtc');
                allRuns{iRun-1} = gmtc';
            end
            boldBrain = vertcat(allRuns{:});
            clear gmtc allRuns;
        
            % extract roi timeseries (sum)
            boldRois = boldBrain * roiData;
            if ~isempty(targetRoiData)
                boldBrain = boldBrain * targetRoiData;
            end

            % prepare calculations
            boldRois = boldRois - mean(boldRois);
            boldRois = boldRois ./ vecnorm(boldRois);
            boldBrain = boldBrain - mean(boldBrain);
            boldBrain = boldBrain ./ vecnorm(boldBrain);

            % corr coefficient
            z =  boldBrain' * boldRois;
        end
        
        % fisher transformation
        z = min(z, 1-1e-9); % -> max(z) = 10.7082
        z = atanh(z);
        % streaming mean
        meanZ = meanZ + (z - meanZ) / iParticipant;            
        
        % progress bar
        if mod(totRun,progress1pct) < 1
            lastLen = afxPrintProgress(20, round(totRun/progress1pct), toc(t)/60, lastLen);
        end
    end
end