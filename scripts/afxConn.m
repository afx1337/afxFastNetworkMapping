function [meanZ] = afxConn(connectome, connectomeDir, rois, roiData, nParticipants)

    % initialize group mean/M2 (total ram usage per participant ~ 2.2 Mb)
    meanZ = zeros(numel(connectome.vol.outidx), numel(rois), 'single');
    %var   = zeros(numel(connectome.vol.outidx), numel(rois), 'single');
    N = 0;

    progress1pct = nParticipants * .01;
    lastLen = afxPrintProgress(20, 0, 0, 0);
    t = tic;
    for iParticipant = 1:nParticipants        
        % load preprocessed bold signal for all available runs
        boldBrain = [];
        for iRun = 2:numel(connectome.vol.subIDs{iParticipant})
            load(fullfile(connectomeDir, connectome.vol.subIDs{iParticipant}{iRun}),'gmtc');
            boldBrain = [boldBrain; gmtc']; % concat runs
        end
        
        % extract roi timeseries
        boldRois = boldBrain * roiData;
        
        % prepare calculation
        boldRois = boldRois - mean(boldRois);
        boldRois = boldRois ./ vecnorm(boldRois);
        boldBrain = boldBrain - mean(boldBrain);
        boldBrain = boldBrain ./ vecnorm(boldBrain);
        
        % corrcoeff
        z =  boldBrain' * boldRois;
        
        % fisher transformation
        z = min(z, 1-1e-9); % -> max(z) = 10.7082
        z = atanh(z);
        
        % Welford algorithm
        N = N + 1;
        %delta = z - mean;
        %mean = mean + delta / N;
        %var = var + delta .* (X - mean);
        meanZ = meanZ + (z - meanZ) / N;
        
        % progress bar
        if mod(iParticipant,progress1pct) < 1
            lastLen = afxPrintProgress(20, round(iParticipant/progress1pct), toc(t)/60, lastLen);
        end
    end
    %var = var / (N - 1);
end