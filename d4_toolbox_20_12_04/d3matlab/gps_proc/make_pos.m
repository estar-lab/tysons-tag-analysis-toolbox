function    [PP,info] = make_pos(POS,info,toffset)

%     [POS,info] = make_pos(POS,info)
%     or
%     [POS,info] = make_pos(POS,info,toffset)
%     Convert snapshot GPS positions into a sensor structure. The info
%     structure is adjusted to reflect the time error between the tag
%     reported time and the time inferred from processing the GPS grabs.
%     If make_pos is called with only two arguments, the time error is
%     taken as the mean difference between GPS and tag time in the first 10
%     processable grabs. If you want to specify a different time error, pass
%     it in the third argument to make_pos.
%
%     Inputs: 
%     POS is the GPS position structure output by gps_posns. 
%     info is the deployment metadata structure produced using make_info.
%     toffset is the optional time offset between GPS and tag-reported time
%      in seconds. If the tag is ahead of GPS, toffset is negative.
%
%     Returns:
%     POS is now a sensor structure containing the track data.
%     info is adjusted to reflect the GPS time at which the deployment started.
%      It has an additional field 'dephist_device_datetime_start_reported'
%      containing the start time reported by the tag.

if nargin<2 || ~isstruct(info) || ~isstruct(POS),
    help make_pos
    return
end

if nargin<3,
   n = min(length(POS.T),10) ;
   toffset = mean(POS.T(1:n)-POS.TT(1:n)) ;
else
   toffset = toffset/(24*3600) ;
end

rep_start_time = get_start_time(info) ;
if ~isfield(info,'dephist_device_regset'),
   info.dephist_device_regset = 'yyyy/mm/dd HH:MM:SS' ;
end

true_start_time = datestr(datenum(rep_start_time)+toffset,info.dephist_device_regset) ;

if isfield(info,'dephist_deploy_datetime_start'),
   info.dephist_deploy_datetime_start = true_start_time ;
   info.dephist_deploy_datetime_start_type = 'GPS corrected' ;
end

if isfield(info,'dephist_device_datetime_start'),
   info.dephist_device_datetime_start = true_start_time ;
   info.dephist_device_datetime_start_type = 'GPS corrected' ;
end

info.dephist_device_datetime_start_reported = datestr(datenum(rep_start_time),info.dephist_device_regset) ;

gpst = etime(datevec(POS.TT),repmat(datevec(true_start_time,info.dephist_device_regset),length(POS.T),1)) ;

PP = sens_struct([POS.lat,POS.lon],gpst,info.depid,'pos') ;
PP.data(:,end+1) = (POS.T-POS.TT)*(24*3600) ;
PP.column_name = [PP.column_name ',time_error'] ;
PP.time_description = 'tag time in seconds since start time' ;
PP.time_error_unit = 'seconds' ;
PP.time_error_description = 'gps time minus tag reported time for each grab' ; 
