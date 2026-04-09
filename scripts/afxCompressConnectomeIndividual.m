function afxCompressConnectomeIndividual(connectomeFile, destDir, varThr)
    % afxCompressConnectomeIndividual(connectomeFile, destDir, varThr)
    %
    % Compress connectome using low rank matrix approximation by truncated 
    % principal component analysis preserving group structure.
    % Compressed connectomes are smaller (50 - 90 %) and thus save I/O
    % operations. Additionally, connectivity estimation can be performed in
    % PCA space which is faster and saves RAM (especially for resting-state
    % sessions with many scans).
    %
    % Inputs:
    % - connectomeFile: uncompressed connectome (dataset_info.mat)
    % - destDir:        directory for compressed connectome
    % - varThr:         compressed connectome shall account for at least
    %                   this amount of variance in bold timeseries
    %                   (default: 0.95)
    %
    % Outputs:
    % - Compressed connectome in destDir (*.mat)

    if ~exist('varThr','var'), varThr = 0.95; end
    
    fprintf('Calculating individual PCAs ...\n');
    
    % load connectome
    load(connectomeFile,'dataset');
    datasetDir = fileparts(connectomeFile);
    nParticipants = numel(dataset.vol.subIDs);

    if ~exist(destDir,'dir'), mkdir(destDir); end
    
    % progress bar
    progress1pct = (numel([dataset.vol.subIDs{1:nParticipants}])-nParticipants) * .01;
    lastLen = afxPrintProgress(20, 0, 0, 0);
    totRun = 0;
    t = tic;
    
    for iParticipant = 1:nParticipants
        pName = strcat('sub_', dataset.vol.subIDs{iParticipant}{1});
        
        % load preprocessed bold signal for all available runs
        nRuns = numel(dataset.vol.subIDs{iParticipant});
        allRuns = cell(nRuns-1,1);
        for iRun = 2:nRuns
            totRun = totRun + 1;
            load(fullfile(datasetDir, dataset.vol.subIDs{iParticipant}{iRun}),'gmtc');
            allRuns{iRun-1} = gmtc';
        end
        boldBrain = vertcat(allRuns{:});
        
        % mean center
        boldBrain = boldBrain - mean(boldBrain, 1);

        % eigenvalues of covariance matrix
        [U, D] = eig(boldBrain * boldBrain');
        U = real(U);
        
        % sort (absteigend)
        [d, idx] = sort(diag(D), 'descend');
        U = U(:, idx);
        
        % numerical stability
        tol = max(d) * 1e-8;
        keep = d > tol;
        d = d(keep);
        U = U(:, keep);

        % number of components
        explained = d / sum(d);
        cumExplained = cumsum(explained);
        k = find(cumExplained >= varThr, 1);
        
        % truncation
        U_k = U(:,1:k);
        d_k = d(1:k);

        % time domain
        T = U_k .* sqrt(d_k)';      % (nT × k)
        % spatial domain
        V = (boldBrain' * U_k) ./ sqrt(d_k)';   % (nVox × k)

        % save
        fname = strcat(pName,'.mat');
        save(fullfile(destDir,fname), 'T', 'V', '-v7.3', '-nocompression');
        dataset.vol.subIDs{iParticipant} = { pName fname };
        
        % progress bar
        if mod(totRun,progress1pct) < 1
            lastLen = afxPrintProgress(20, round(totRun/progress1pct), toc(t)/60, lastLen);
        end
    end
    
    dataset.descrip = 'functional connectome';
    dataset.type = 'fMRI_pca';
    dataset.isPCA = true;
    dataset.PCAvarThr = varThr;
    save(fullfile(destDir,'dataset_info.mat'),'dataset');

    fprintf('Done.\n');
end