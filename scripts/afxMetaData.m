function meta = afxMetaData()
    meta.date = datestr(now);
    meta.version = afxVersion();
    meta.matlab = version();
    meta.toolboxes = ver();
end

function version = afxVersion()
    thisFile = mfilename('fullpath');
    thisDir = fileparts(thisFile);
    versionFile = fullfile(thisDir,'..', 'VERSION');
    if exist(versionFile, 'file')
        version = strtrim(fileread(versionFile));
    else
        version = 'unknown';
        warning('VERSION file not found.');
    end
end