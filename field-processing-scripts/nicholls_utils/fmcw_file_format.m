function fmt = fmcw_file_format(filename)

% fmt = fmcw_file_format(filename)
%
% Determine fmcw file format from burst header using keyword presence

% Craig Stewart
% 2013-10-20
%
% Updated by Keith Nicholls, 2014-10-22: RMB2

[fid, msg] = fopen(filename,'rt');
if fid == -1
    error(msg)
end
MaxHeaderLen = 2000;
A = fread(fid,MaxHeaderLen,'*char');
fclose(fid);
A = A';
if contains(A, 'IQ=1', 'IgnoreCase',true) % IQ data
    fmt = 6;
elseif contains(A, 'SW_Issue=', 'IgnoreCase',true) % Data from RMB2 after Oct 2014
    fmt = 5;
elseif contains(A, 'SubBursts in burst:', 'IgnoreCase',true) % Data from after Oct 2013
    fmt = 4;
elseif contains(A, '*** Burst Header ***', 'IgnoreCase',true) % Data from Jan 2013
    fmt = 3;
elseif contains(A, 'RADAR TIME', 'IgnoreCase',true) % Data from Prototype FMCW radar (nov 2012)
    fmt = 2;
else
    %fmt = 0; % unknown file format
    error('Unknown file format - check file')
end
