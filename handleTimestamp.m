
clear all; clc



loop_record_file1 = "E:\basicmath_1\basicmath_ref_timelog.txt";
fileID = fopen(loop_record_file1,'w');
normal_period = 100;
attack_period = 100;
for idx = 1:20
    c = ['E:\\basicmath_1\\basicmath_normal_timelog_',num2str(idx), '.txt'];
    filename = sprintf(c);
    loop_record = load(filename);
    startTime = int64(fix(loop_record(1,1)*1000000+ loop_record(1,2)));
    endTime = int64(fix(loop_record(1,3)*1000000+ loop_record(1,4)));
    normal_period= min(normal_period , double(endTime - startTime)/(10*10*10*300));
    fprintf(fileID,unixTimestampToSecondsAndMilliseconds(startTime,endTime));
end

display(['normal loop period = ', num2str(normal_period)]);
fclose(fileID);
loop_record_file2 = "E:\basicmath_1\basicmath_memory_timelog.txt";
fileID = fopen(loop_record_file2,'w');
for idx = 1:5
    c = ['E:\\basicmath_1\\basicmath_attack_timelog_',num2str(idx), '.txt'];
    filename = sprintf(c);
    loop_record = load(filename);
    startTime1 = loop_record(1,1)*1000000+ ceil(loop_record(1,2));
    endTime1 = loop_record(1,3)*1000000+ ceil(loop_record(1,4));
    startTime2 = loop_record(2,1)*1000000+ ceil(loop_record(2,2));
    endTime2 = loop_record(2,3)*1000000+ ceil(loop_record(2,4));
    attack_period= min(attack_period , double(endTime1 - startTime1)/(10*10*10*300));
    fprintf(fileID,unixTimestampToSecondsAndMilliseconds(startTime1,endTime1));
    fprintf(fileID,unixTimestampToSecondsAndMilliseconds(startTime2,endTime2));
end
fclose(fileID);
display(['attack loop period = ', num2str(attack_period)]);
function formatted_time = unixTimestampToSecondsAndMilliseconds(unix_time1,unix_time2)
    % Convert Unix timestamp to datetime with milliseconds
    dt1 = datetime(unix_time1, 'ConvertFrom', 'epochtime','TicksPerSecond',1e6, 'Format','ss.SSSSSS');
    dt2 = datetime(unix_time2, 'ConvertFrom', 'epochtime','TicksPerSecond',1e6, 'Format','ss.SSSSSS');

    formatted_time = sprintf('%s, %s\n', dt1,dt2);
end
