function [meanZ] = afxConn(connectome, roiData, targetRoiData, nParticipants)

    % initialize group mean/M2 (total ram usage per roi ~ 2.2 Mb)
    if ~isempty(targetRoiData)
        nVox = size(targetRoiData,2);        % seed to target
    else
        nVox = numel(connectome.vol.outidx); % seed to whole brain
    end
    meanZ = zeros(nVox, size(roiData,2), 'single');
    %var  = zeros(nVox, size(roiData,2), 'single');

    progress1pct = (numel([connectome.vol.subIDs{1:nParticipants}])-nParticipants) * .01;
    lastLen = afxPrintProgress(20, 0, 0, 0);
    totRun = 0;
    t = tic;
    for iParticipant = 1:nParticipants        
        % load preprocessed bold signal for all available runs
        boldBrain = [];
        for iRun = 2:numel(connectome.vol.subIDs{iParticipant})
            totRun = totRun + 1;
            load(fullfile(connectome.dir, connectome.vol.subIDs{iParticipant}{iRun}),'gmtc');
            boldBrain = [boldBrain; gmtc']; % concat runs
        end
        
        % extract roi timeseries
        boldRois = boldBrain * roiData;
        if ~isempty(targetRoiData)
            boldBrain = boldBrain * targetRoiData;
        end
        
        % prepare calculation
        if ~isfield(connectome,'isScaled') || ~connectome.isScaled
            boldRois = boldRois - mean(boldRois);
            boldRois = boldRois ./ vecnorm(boldRois);
            boldBrain = boldBrain - mean(boldBrain);
            boldBrain = boldBrain ./ vecnorm(boldBrain);
        else
            boldRois = boldRois ./ sum(roiData);
        end
        
        % corrcoeff
        z =  boldBrain' * boldRois;
        
        % fisher transformation
        z = min(z, 1-1e-9); % -> max(z) = 10.7082
        z = atanh(z);
        
        if ~isfield(connectome,'isScaled') || ~connectome.isScaled
            % Welford algorithm
            %N = N + 1;
            %delta = z - meanZ;
            %meanZ = meanZ + delta / N;
            %var = var + delta .* (z - meanZ);
            meanZ = meanZ + (z - meanZ) / iParticipant;            
        else
            meanZ = meanZ + z;
        end
        
        % progress bar
        if mod(totRun,progress1pct) < 1
            lastLen = afxPrintProgress(20, round(totRun/progress1pct), toc(t)/60, lastLen);
        end
    end
    %var = var / (N - 1); -> could be used for one smaple t-test
end
