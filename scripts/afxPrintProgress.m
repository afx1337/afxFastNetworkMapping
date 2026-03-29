function lastLen = afxPrintProgress(barWidth, pct, elapsedMin, lastLen)
    %PRINTPROGRESS Print single-line console progress bar with ETA.
    %   lastLen = PRINTPROGRESS(barWidth, pct, elapsedMin, lastLen)
    %   Pass lastLen from the previous call (use 0 initially).

    nEqual = round(barWidth * pct / 100);
    backStr = repmat('\b',1,lastLen);
    barStr = ['[', repmat('=',1,nEqual), repmat(' ',1,barWidth-nEqual), ']'];
    outStr = sprintf('  %3d %% %s', pct, barStr);
    
    if pct > 0 && pct < 100
        totalEst = elapsedMin / (pct/100);
        remSecs = max(0, totalEst - elapsedMin)*60;
        outStr = [outStr, sprintf(' (%s min left)', sec2mmss(remSecs))];
    end

    fprintf([backStr '%s'], outStr);
    lastLen = length(outStr);

    if pct == 100
        fprintf(' done (%s min).\n',sec2mmss(elapsedMin*60));
        lastLen = 0;
    end
end

function str = sec2mmss(sec)
    mm = floor(sec / 60);
    ss = mod(sec, 60);
    str = sprintf('%d:%02d', mm, round(ss));
end
