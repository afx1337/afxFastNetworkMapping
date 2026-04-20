function rois = afxSaveNetworkMaps(dat,outidx,dim,mat,rois,compress,destFolder)

    progress1pct = numel(rois) * .01;
    lastLen = afxPrintProgress(20, 0, 0, 0);
    if ~exist(destFolder,'dir'), mkdir(destFolder); end
    img = nan(prod(dim),1,'single');
    t = tic;
    for iRoi = 1:numel(rois)
        img(outidx) = dat(:,iRoi);
        fname = fullfile(destFolder, strcat(rois(iRoi).name,'.nii'));

        % in case of sub directoris in roi names
        if contains(rois(iRoi).name, filesep)
            [pth, ~, ~] = fileparts(fname);
            if ~exist(pth, 'dir')
                mkdir(pth);
            end
        end
        
        afxVolumeWrite(fname,img,dim,'int16',mat,'network map',true);
        if compress
            gzip(fname);
            delete(fname);
            fname = strcat(fname,'.gz');
        end
        rois(iRoi).network = fname;
        
        % progress bar
        if mod(iRoi,progress1pct) < 1
            lastLen = afxPrintProgress(20, round(iRoi/progress1pct), toc(t)/60, lastLen);
        end
    end
end