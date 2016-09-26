function str = sec2hmsstring(t)
[hours, mins, secs]= sec2hms(t);
if hours > 0
    str = sprintf('%d hours %d minutes and %5.3f seconds', hours, mins, secs);
elseif mins > 0
    str = sprintf('%d minutes and %5.3f seconds',mins, secs);
else
    str = sprintf('%5.3f seconds',secs);
end
end