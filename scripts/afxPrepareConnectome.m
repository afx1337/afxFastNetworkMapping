function dataset = afxPrepareConnectome(connectome)
    
    % load connectome info
    load(connectome,'dataset');
    
    % calculate MNI coordinates of mask
    [R,C,P] = ndgrid(1:dataset.vol.space.dim(1),1:dataset.vol.space.dim(2),1:dataset.vol.space.dim(3));
    RCP     = [R(:)';C(:)';P(:)';ones(1,numel(R))];
    clear R C P;
    dataset.vol.XYZmm   = dataset.vol.space.mat(1:3,:)*RCP(:,dataset.vol.outidx);
    clear RCP;
    dataset.vol.XYZmm = [dataset.vol.XYZmm; ones(1,size(dataset.vol.XYZmm,2))];
end