function lastLen = afxPrintProgress(barWidth, pct, elapsedMin, lastLen)
    %PRINTPROGRESS Print single-line console progress bar with ETA.
    %   lastLen = PRINTPROGRESS(barWidth, pct, elapsedMin, lastLen)
    %   Pass lastLen from the previous call (use 0 initially).

    nEqual = round(barWidth * pct / 100);
    backStr = repmat('\b',1,lastLen);
    barStr = ['[', repmat('=',1,nEqual), repmat(' ',1,barWidth-nEqual), ']'];
    outStr = sprintf('  %3d %% %s', pct, barStr);
    
    if pct > 0 && pct < 100
        totalEst   = elapsedMin / (pct/100);
        totalSeconds = round(max(0, totalEst - elapsedMin)*60);
        mm = floor(totalSeconds / 60);
        ss = mod(totalSeconds, 60);
        outStr = [outStr, sprintf(' (%d:%02d min left)', mm, ss)];
    end

    fprintf([backStr '%s'], outStr);
    lastLen = length(outStr);

    if pct == 100
        fprintf(' done.\n');
        lastLen = 0;
    end
end