function roiData = afxLoadRois(rois, connectome, gmMask)
  
    % preallocate
    roiData = false(numel(connectome.vol.outidx),numel(rois));
    atlasCache = struct('file',[],'dat',[]);
    
    % load/generate roi masks
    progress1pct = numel(rois) * .01;
    lastLen = afxPrintProgress(20, 0, 0, 0);
    t = tic;
    for i = 1:numel(rois)
        switch (rois(i).type)
            case 'sphere'
                D = vecnorm(connectome.vol.XYZmm(1:3,:) - rois(i).coords(:), 2, 1);
                roiData(:,i) = D < rois(i).radius;
                clear D;
            case 'image'
                roiData(:,i) = afxVolumeResample(rois(i).file, connectome.vol.XYZmm,0) ~= 0;
            case 'atlas'
                atlasCache = getResampledData(atlasCache, rois(i).file, connectome.vol.XYZmm);
                roiData(:,i) = abs(atlasCache.dat - rois(i).pick) < .5;
            otherwise
                error('Unknown roi type: %s', rois(i).type);
        end
        
        % progress bar
        if mod(i,progress1pct) < 1
            lastLen = afxPrintProgress(20, round(i/progress1pct), toc(t)/60, lastLen);
        end
    end

    % gm masking
    if ~isempty(gmMask)
        roiData = roiData & gmMask';
    end
end

function cache = getResampledData(cache, file, XYZmm)
    if ~strcmp(cache.file, file)
        cache.dat = afxVolumeResample(file, XYZmm, 0);
        cache.file = file;
    end
end