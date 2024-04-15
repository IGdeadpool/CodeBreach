clear all; clc

%% read file
%{
data(1).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_1.sc16q11";
data(2).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_2.sc16q11";
data(3).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_3.sc16q11";
data(4).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_4.sc16q11";
data(5).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_5.sc16q11";
data(6).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_6.sc16q11";
data(7).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_7.sc16q11";
data(8).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_8.sc16q11";
data(9).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_9.sc16q11";
data(10).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_10.sc16q11";
data(11).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_11.sc16q11";
data(12).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_12.sc16q11";
data(13).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_13.sc16q11";
data(14).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_14.sc16q11";
data(15).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_15.sc16q11";
data(16).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_16.sc16q11";
data(17).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_17.sc16q11";
data(18).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_18.sc16q11";
data(19).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_19.sc16q11";
data(20).filename = "E:\basicmath\Raspberry_basicmath_ref_15s_20.sc16q11";
%}
parameter.data_count = 20;
for idx = 1:parameter.data_count
    c = ['E:\\basicmath_1\\Raspberry_basicmath_normal_10s_',num2str(idx), '.sc16q11'];
    data(idx).filename = sprintf(c);
end

% parameter.valid_data_count = 2;

%% make dataset
parameter.Fs = 10e6;            % sampling rate = 10Msps
parameter.Time_Read = 15;        % time length for FFT analysis

parameter.win_time = 0.005;
parameter.win_len = parameter.win_time*parameter.Fs;
parameter.win_slip= parameter.win_time/4 * parameter.Fs;

% parameter.period_size = 2500;
parameter.cut_off_fre = 2500;
%% define
start_file = "E:\basicmath_1\basicmath_ref_startTime.txt";
data_start = load(start_file);


loop_record_file = "E:\basicmath_1\basicmath_ref_timelog.txt";
loop_records = load(loop_record_file);

parameter.loop_count =1;

% 
for loop_num = 1:parameter.loop_count
    parameter.win_size(loop_num) = 10;
end
% get the start timestamp
for data_num  = 1:parameter.data_count
    data(data_num).start_time = data_start(data_num,1);
    % get the data of each loops
    for loop_num = 1:parameter.loop_count
        data(data_num).loops(loop_num).start = loop_records( ...
            (data_num-1)*parameter.loop_count + loop_num,1);
        
        data(data_num).loops(loop_num).end = loop_records( ...
            (data_num-1)*parameter.loop_count + loop_num,2);
        if data(data_num).loops(loop_num).end < data(data_num).loops(loop_num).start
            data(data_num).loops(loop_num).end = data(data_num).loops(loop_num).end + 60;
        end
        parameter.win_size(loop_num) = min(parameter.win_size(loop_num) ...
            , (data(data_num).loops(loop_num).end ...
            - data(data_num).loops(loop_num).start));
    end
end

%% build reference lib

for data_num = 1:parameter.data_count

    % load file
    data_recv = load_sc16q11(data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(data_recv);
    signal = data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = data(data_num).loops(loop_num).start - data(data_num).start_time;
        end_point = start_point + parameter.win_size(loop_num);

        loop_signal = signal(fix(start_point*parameter.Fs) ...
            :fix(end_point*parameter.Fs));
        ref = zeros(1,parameter.cut_off_fre);
        ii=1;
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_slip:(length(loop_signal)-parameter.win_len)
            avg_loops(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
            ii= ii+1;
        end
        ii =0;
        % silde windows
        for idx = 1:parameter.win_slip:(length(loop_signal)-parameter.win_len)
            win_start= idx;
            win_end  = win_start+parameter.win_len-1;

            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            ii= ii+1;
            avg_loops(loop_num).sts(ii).data(data_num).signal =ref;
        end
        parameter.win_count(loop_num) = ii;
        

    end

    
    
end

% show the fft result
parameter.reportThreshold = 5;

%% memory modification injection
% memeory modification
parameter.injection_data_count = 5;
for idx = 1:parameter.injection_data_count
    c = ['E:\\basicmath_1\\Raspberry_basicmath_attack_15s_',num2str(idx), '.sc16q11'];
    memory_data(idx).filename = sprintf(c);
end

memory_start_file = "E:\basicmath_1\basicmath_memory_startTime.txt";
memory_start = load(memory_start_file);

memory_record_file = "E:\basicmath_1\basicmath_memory_timelog.txt";
memory_records = load(memory_record_file);

for loop_num = 1:parameter.loop_count
    parameter.memory_adjust_win_size(loop_num) = 10;
    parameter.memory_injection_win_size(loop_num) = 10;
end

% get the start timestamp
for data_num  = 1:parameter.injection_data_count
    memory_data(data_num).start_time = memory_start(data_num,1);
    % get the data of each loops
    for loop_num = 1:parameter.loop_count
        % direct injection
        memory_data(data_num).loops(loop_num).injection_start = memory_records( ...
            (data_num-1)*parameter.loop_count*2  + loop_num*2-1,1);
        memory_data(data_num).loops(loop_num).injection_end = memory_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2-1,2);
        parameter.memory_injection_win_size(loop_num) = min(parameter.memory_injection_win_size(loop_num) ...
            , (memory_data(data_num).loops(loop_num).injection_end ...
            - memory_data(data_num).loops(loop_num).injection_start));
        % after modification
        memory_data(data_num).loops(loop_num).adjust_start = memory_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2,1);
        memory_data(data_num).loops(loop_num).adjust_end = memory_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2,2);
        parameter.memory_adjust_win_size(loop_num) = min(parameter.memory_adjust_win_size(loop_num) ...
            , (memory_data(data_num).loops(loop_num).adjust_end ...
            - memory_data(data_num).loops(loop_num).adjust_start));
    end
    
end

%% direct injection

for data_num = 1:parameter.injection_data_count

    % load file
    memory_data_recv = load_sc16q11(memory_data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(memory_data_recv);
    signal = memory_data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = memory_data(data_num).loops(loop_num).injection_start ...
            - memory_data(data_num).start_time;
        end_point = start_point + parameter.memory_injection_win_size(loop_num);

        loop_signal = signal(fix(start_point*parameter.Fs) ...
            :fix(end_point*parameter.Fs));
        ref = zeros(1,parameter.cut_off_fre);
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_count(loop_num)
            memory_direct(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
        end
        % silde windows
        for idx = 1:parameter.win_count(loop_num)
            win_start= (idx-1)*parameter.win_slip+1;
            win_end  = win_start+parameter.win_len-1;


            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            memory_direct(loop_num).sts(idx).data(data_num).signal =ref;
        end
         
    end
        
end


%% peak check 

for data_num  = 1:parameter.injection_data_count
    for loop_num = 1 :parameter.loop_count
        anomaly_spectrum =0;
        for spectrum  = 1:parameter.win_count(loop_num)
            isAnomaly = 1;
            for data_pos = 1:parameter.data_count
                if checkPeaks(avg_loops(loop_num).sts(spectrum).data(data_pos).signal, ...
                        memory_direct(loop_num).sts(spectrum).data(data_num).signal)
                    isAnomaly = 0;
                end
            end
            if isAnomaly
                    anomaly_spectrum = anomaly_spectrum +1;
            end
        end
        disp(['detection possibility of attack test case ',num2str(data_num), ' is ',num2str(anomaly_spectrum / parameter.win_count(loop_num))])
    end
end


%% modified injection

for data_num = 1:parameter.injection_data_count

    % load file
    memory_data_recv = load_sc16q11(memory_data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(memory_data_recv);
    signal = memory_data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = memory_data(data_num).loops(loop_num).adjust_start ...
            - memory_data(data_num).start_time;
        end_point = start_point + parameter.memory_adjust_win_size(loop_num);

        loop_signal = signal(fix(start_point*parameter.Fs) ...
            :fix(end_point*parameter.Fs));
        ref = zeros(1,parameter.cut_off_fre);
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_count(loop_num)
            memory_adjust(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
        end
        % silde windows
        for idx = 1:parameter.win_count(loop_num)
            win_start= (idx-1)*parameter.win_slip+1;
            win_end  = win_start+parameter.win_len-1;


            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            memory_adjust(loop_num).sts(idx).data(data_num).signal =ref;
        end
        
    end
        
end

x1 = 1:parameter.cut_off_fre;
figure(1)
subplot(3,1,1)
plot(x1*200+6.995e8, avg_loops(1).sts(100).data(1).signal'/max(avg_loops(1).sts(100).data(1).signal'));

subplot(3,1,2)
plot(x1*200+6.995e8, memory_direct(1).sts(100).data(1).signal'/max(memory_direct(1).sts(100).data(1).signal'));

subplot(3,1,3)
plot(x1*200+6.995e8, memory_adjust(1).sts(100).data(1).signal'/max(memory_adjust(1).sts(100).data(1).signal'));
%% peak check 

for data_num  = 1:parameter.injection_data_count
    for loop_num = 1 :parameter.loop_count
        anomaly_spectrum =0;
        for spectrum  = 1:parameter.win_count(loop_num)
            isAnomaly = 1;
            for data_pos = 1:parameter.data_count
                if checkPeaks(avg_loops(loop_num).sts(spectrum).data(data_pos).signal, ...
                        memory_adjust(loop_num).sts(spectrum).data(data_num).signal)
                    isAnomaly = 0;
                end
            end
            if isAnomaly
                    anomaly_spectrum = anomaly_spectrum +1;
            end
        end
        disp(['detection possibility of adjust test case ',num2str(data_num), ' is ',num2str(anomaly_spectrum / parameter.win_count(loop_num))])
    end

end


%{
%% function modification injection

% memeory modification
parameter.injection_data_count = 5;
for idx = 1:parameter.injection_data_count
    c = ['E:\\basicmath\\Raspberry_basicmath_function_20s_',num2str(idx), '.sc16q11'];
    function_data(idx).filename = sprintf(c);
end

function_start_file = "E:\basicmath\basicmath_function_startTime.txt";
function_start = load(function_start_file);

function_record_file = "E:\basicmath\basicmath_function_timelog.txt";
function_records = load(function_record_file);

for loop_num = 1:parameter.loop_count
    parameter.function_adjust_win_size(loop_num) = 10;
    parameter.function_injection_win_size(loop_num) = 10;
end

% get the start timestamp
for data_num  = 1:parameter.injection_data_count
    function_data(data_num).start_time = function_start(data_num,1);
    % get the data of each loops
    for loop_num = 1:parameter.loop_count
        % direct injection
        function_data(data_num).loops(loop_num).injection_start = function_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2-1,1);
        function_data(data_num).loops(loop_num).injection_end = function_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2-1,2);
        parameter.function_injection_win_size(loop_num) = min(parameter.function_injection_win_size(loop_num) ...
            , (function_data(data_num).loops(loop_num).injection_end ...
            - function_data(data_num).loops(loop_num).injection_start));
        % after modification
        function_data(data_num).loops(loop_num).adjust_start = function_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2,1);
        function_data(data_num).loops(loop_num).adjust_end = function_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2,2);
        parameter.function_adjust_win_size(loop_num) = min(parameter.function_adjust_win_size(loop_num) ...
            , (function_data(data_num).loops(loop_num).adjust_end ...
            - function_data(data_num).loops(loop_num).adjust_start));
    end
    
end

%% direct injection

for data_num = 1:parameter.injection_data_count

    % load file
    function_data_recv = load_sc16q11(function_data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(function_data_recv);
    signal = function_data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = function_data(data_num).loops(loop_num).injection_start ...
            - function_data(data_num).start_time;
        end_point = start_point + parameter.function_injection_win_size(loop_num);

        loop_signal = signal(start_point*parameter.Fs ...
            :end_point*parameter.Fs);
        ref = zeros(1,parameter.cut_off_fre);
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_count(loop_num)
            function_direct(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
        end
        % silde windows
        for idx = 1:parameter.win_count(loop_num)
            win_start= (idx-1)*parameter.win_slip+1;
            win_end  = win_start+parameter.win_len-1;


            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            function_direct(loop_num).sts(idx).data(data_num).signal =ref;
        end
        
    end
        
end


%% peak check 

for data_num  = 1:parameter.injection_data_count
    for loop_num = 1 :parameter.loop_count
        anomaly_spectrum =0;
        for spectrum  = 1:parameter.win_count(loop_num)
            isAnomaly = 1;
            for data_pos = 1:parameter.data_count
                if checkPeaks(avg_loops(loop_num).sts(spectrum).data(data_pos).signal, ...
                        function_direct(loop_num).sts(spectrum).data(data_num).signal)
                    isAnomaly = 0;
                end
            end
            if isAnomaly
                    anomaly_spectrum = anomaly_spectrum +1;
            end
        end
            disp([num2str(anomaly_spectrum / parameter.win_count(loop_num))])
    end
    %{
    if anomaly_spectrum > parameter.reportThreshold
        disp(['found anomaly in loop ',num2str(loop_num), ', data ', num2str(data_num)]);
    else
        disp(['no anomaly in test set ', num2str(data_num)]);
    end
    %}
end


%% modified injection

for data_num = 1:parameter.injection_data_count

    % load file
    function_data_recv = load_sc16q11(function_data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(function_data_recv);
    signal = function_data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = function_data(data_num).loops(loop_num).adjust_start ...
            - function_data(data_num).start_time;
        end_point = start_point + parameter.function_adjust_win_size(loop_num);

        loop_signal = signal(start_point*parameter.Fs ...
            :end_point*parameter.Fs);
        ref = zeros(1,parameter.cut_off_fre);
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_count(loop_num)
            function_adjust(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
        end
        % silde windows
        for idx = 1:parameter.win_count(loop_num)
            win_start= (idx-1)*parameter.win_slip+1;
            win_end  = win_start+parameter.win_len-1;


            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            function_adjust(loop_num).sts(idx).data(data_num).signal =ref;
        end
        
    end
        
end


%% peak check 

for data_num  = 1:parameter.injection_data_count
    for loop_num = 1 :parameter.loop_count
        anomaly_spectrum =0;
        for spectrum  = 1:parameter.win_count(loop_num)
            isAnomaly = 1;
            for data_pos = 1:parameter.data_count
                if checkPeaks(avg_loops(loop_num).sts(spectrum).data(data_pos).signal, ...
                        function_adjust(loop_num).sts(spectrum).data(data_num).signal)
                    isAnomaly = 0;
                end
            end
            if isAnomaly
                    anomaly_spectrum = anomaly_spectrum +1;
            end
        end
            disp([num2str(anomaly_spectrum / parameter.win_count(loop_num))])
    end
    %{
    if anomaly_spectrum > parameter.reportThreshold
        disp(['found anomaly in loop ',num2str(loop_num), ', data ', num2str(data_num)]);
    else
        disp(['no anomaly in test set ', num2str(data_num)]);
    end
    %}
end

%}
%{
%% long injection

% long modification
parameter.injection_data_count = 5;
for idx = 1:parameter.injection_data_count
    c = ['E:\\basicmath\\Raspberry_basicmath_long_30s_',num2str(idx), '.sc16q11'];
    long_data(idx).filename = sprintf(c);
end

long_start_file = "E:\basicmath\basicmath_long_startTime.txt";
long_start = load(long_start_file);

long_record_file = "E:\basicmath\basicmath_long_timelog.txt";
long_records = load(long_record_file);

for loop_num = 1:parameter.loop_count
    parameter.long_adjust_win_size(loop_num) = 10;
    parameter.long_injection_win_size(loop_num) = 10;
end

% get the start timestamp
for data_num  = 1:parameter.injection_data_count
    long_data(data_num).start_time = long_start(data_num,1);
    % get the data of each loops
    for loop_num = 1:parameter.loop_count
        % direct injection
        long_data(data_num).loops(loop_num).injection_start = long_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2-1,1);
        long_data(data_num).loops(loop_num).injection_end = long_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2-1,2);
        parameter.long_injection_win_size(loop_num) = min(parameter.long_injection_win_size(loop_num) ...
            , (long_data(data_num).loops(loop_num).injection_end ...
            - long_data(data_num).loops(loop_num).injection_start));
        % after modification
        long_data(data_num).loops(loop_num).adjust_start = long_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2,1);
        long_data(data_num).loops(loop_num).adjust_end = long_records( ...
            (data_num-1)*parameter.loop_count*2 + loop_num*2,2);
        parameter.long_adjust_win_size(loop_num) = min(parameter.long_adjust_win_size(loop_num) ...
            , (long_data(data_num).loops(loop_num).adjust_end ...
            - long_data(data_num).loops(loop_num).adjust_start));
    end
    
end

%% direct injection

for data_num = 1:parameter.injection_data_count

    % load file
    long_data_recv = load_sc16q11(long_data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(long_data_recv);
    signal = long_data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = long_data(data_num).loops(loop_num).injection_start ...
            - long_data(data_num).start_time;
        end_point = start_point + parameter.long_injection_win_size(loop_num);

        loop_signal = signal(start_point*parameter.Fs ...
            :end_point*parameter.Fs);
        ref = zeros(1,parameter.cut_off_fre);
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_count(loop_num)
            long_direct(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
        end
        % silde windows
        for idx = 1:parameter.win_count(loop_num)
            win_start= (idx-1)*parameter.win_slip+1;
            win_end  = win_start+parameter.win_len-1;


            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            long_direct(loop_num).sts(idx).data(data_num).signal =ref;
        end
        
    end
        
end


%% peak check 

for data_num  = 1:parameter.injection_data_count
    for loop_num = 1 :parameter.loop_count
        anomaly_spectrum =0;
        for spectrum  = 1:parameter.win_count(loop_num)
            isAnomaly = 1;
            for data_pos = 1:parameter.data_count
                if checkPeaks(avg_loops(loop_num).sts(spectrum).data(data_pos).signal, ...
                        long_direct(loop_num).sts(spectrum).data(data_num).signal)
                    isAnomaly = 0;
                end
            end
            if isAnomaly
                    anomaly_spectrum = anomaly_spectrum +1;
            end
        end
            disp([num2str(anomaly_spectrum / parameter.win_count(loop_num))])
    end
    if anomaly_spectrum > parameter.reportThreshold
        disp(['found anomaly in loop ',num2str(loop_num), ', data ', num2str(data_num)]);
    else
        disp(['no anomaly in test set ', num2str(data_num)]);
    end

end


%% modified injection

for data_num = 1:parameter.injection_data_count

    % load file
    long_data_recv = load_sc16q11(long_data(data_num).filename);
    reading_start = parameter.Fs * 0 + 1;
    reading_end   = length(long_data_recv);
    signal = long_data_recv(reading_start:reading_end);

    for loop_num = 1:parameter.loop_count
        % loop file start point
        start_point = long_data(data_num).loops(loop_num).adjust_start ...
            - long_data(data_num).start_time;
        end_point = start_point + parameter.long_adjust_win_size(loop_num);

        loop_signal = signal(start_point*parameter.Fs ...
            :end_point*parameter.Fs);
        ref = zeros(1,parameter.cut_off_fre);
        % allocate the storageof  the signal data of mth sts of nth loop
        for idx = 1:parameter.win_count(loop_num)
            long_adjust(loop_num).sts(ii).data(data_num).signal=zeros(1,parameter.cut_off_fre);
        end
        % silde windows
        for idx = 1:parameter.win_count(loop_num)
            win_start= (idx-1)*parameter.win_slip+1;
            win_end  = win_start+parameter.win_len-1;


            sig_window = loop_signal(win_start:win_end);
            % FFT
            Freq_sig_win = fftshift((abs(fft(sig_window,parameter.win_len))));
            % get the left cut_off points
            ref = Freq_sig_win(parameter.win_len/2-parameter.cut_off_fre+1:parameter.win_len/2);
            % save the fft result
            long_adjust(loop_num).sts(idx).data(data_num).signal =ref;
        end
        
    end
        
end


%% peak check 

for data_num  = 1:parameter.injection_data_count
    for loop_num = 1 :parameter.loop_count
        anomaly_spectrum =0;
        for spectrum  = 1:parameter.win_count(loop_num)
            isAnomaly = 1;
            for data_pos = 1:parameter.data_count
                if checkPeaks(avg_loops(loop_num).sts(spectrum).data(data_pos).signal, ...
                        long_adjust(loop_num).sts(spectrum).data(data_num).signal)
                    isAnomaly = 0;
                end
            end
            if isAnomaly
                    anomaly_spectrum = anomaly_spectrum +1;
            end
        end
            disp([num2str(anomaly_spectrum / parameter.win_count(loop_num))])
    end
    if anomaly_spectrum > parameter.reportThreshold
        disp(['found anomaly in loop ',num2str(loop_num), ', data ', num2str(data_num)]);
    else
        disp(['no anomaly in test set ', num2str(data_num)]);
    end

end

%}

%% check function

function check_result = checkPeaks(ref_set, test_set)
    check_result = 1;
    
    % detect check
    peaks_num = 0;
    avg_energy = mean(ref_set);
    peak_length = 4;
    peak_gap = 5;
    pos = 0;
    diff_peaks = 0;
    while pos < length(ref_set)
        pos = pos +1;
        if ref_set(pos) >= 3 *avg_energy
            peaks_num = peaks_num +1;
            ref_peak(peaks_num).signal = zeros(1,peak_length*2);
            ref_peak(peaks_num).start_point = max(pos-peak_length +1, 1);
            ref_peak(peaks_num).end_point = min(pos + peak_length,length(ref_set));
            ref_peak(peaks_num).signal = ...
            ref_set(ref_peak(peaks_num).start_point:ref_peak(peaks_num).end_point);
            pos = pos + peak_gap;            
        end     
    end
    
    for peak = 1: peaks_num
        ref_distribution = zeros(1,peak_length*2);
        ref_distribution = ref_peak(peak).signal/max(ref_peak(peak).signal);
        test_peak = test_set(ref_peak(peak).start_point: ref_peak(peak).end_point);
        test_distribution = test_peak/max(test_peak);
        [h,p] = kstest2(test_distribution, ref_distribution, 'Alpha',0.1);
        if h ==1
            diff_peaks = diff_peaks +1;
        end
    end
    
    if diff_peaks> 0
        check_result = 0;
    end

end
 

