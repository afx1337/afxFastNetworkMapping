clc
clear

dArchive = '\\folder\to\archive\GSP1000';

d = dir('*.tar');

for i = 1:numel(d)
    tic;
    fprintf('Processing %i/%i (%s)\n - Untar ... ',i,numel(d),d(i).name);
    untar(d(i).name);
    fprintf('done\n - Move to archive ... ');
    movefile(d(i).name,dArchive);
    fprintf('done\n - Time: %.1f minutes\n',toc/60);
end
