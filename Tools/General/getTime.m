%getTime Retrieve current time in HH:mm:ss format
% 
%   SYNTAX
%     strTime = getTime
% 
%   OUTPUT
%     strTime: string with current time in HH:mm:ss format

function strTime = getTime

	
	vecTime = fix(clock);
	strTime = sprintf('%02d:%02d:%02d',vecTime(4:6));
end

