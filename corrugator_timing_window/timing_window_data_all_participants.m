% For Dutch participants, first remove the folders P03, P10, P17, P22 (incomplete data)
% Total 40 participants - 9 English, 31 Dutch (after removing 4 incomplete ones)

% Input and output directories
inputdir_eng = 'path_to_english_participants_data (with \ at the end)'
outputdir_eng = 'output_directory_for_english_participants (with \ at the end)'
outputdir = 'output_directory_all_participants (with \ at the end)'

% Processing the data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% English
participants_eng = dir(inputdir_eng);
cd(inputdir_eng)
for i = 3:length(participants_eng)
    participant = participants_eng(i).name;
    cd(participant);
    processOneParticipant(participant, outputdir);
    cd ..
end

% Dutch
participants_dutch = dir(inputdir_dutch);
cd(inputdir_dutch)
for i = 3:length(participants_dutch)
   participant = participants_dutch(i).name;
   cd(participant);
   processOneParticipant(participant, outputdir);
   cd ..
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function processOneParticipant(participant, outputdir)
    outputPath = strcat(outputdir, participant);
    % Comment below line out after you have created the output directories once.
    mkdir(outputPath);
    outputPath = strcat(outputPath, '\');
    data.fEMG2 = dlmread('fEMG_2.tab');
    data.shock = dlmread('Shock_is_given.tab');
    data.reliefMarker = dlmread('No_shock.tab');
 
    % Create shock markers
    data.shock(data.shock(:,2) == 0) = 0; % Make all 0s in second column 0 again
    data.shock = floor(data.shock); % For time, remove data after decimal point
    
    % Signal start and end information (#TRIAL_FLOW.tab)
    trialfileid = fopen('#TRIAL_FLOW.tab');
    data.signalinfo = textscan(trialfileid,'%f %s');
    sig_start = floor(data.signalinfo{1}(7)); % Start of signal
    sig_end = floor(data.signalinfo{1}(13)); % End of signal
    % Markers
    data.shock(data.shock(:,1) < sig_start | data.shock(:,1) > sig_end) = 0; % Make markers before start of exp and after 0
    data.shock = [nonzeros(data.shock(:,1));ones(length(nonzeros(data.shock(:,1))),1)]; % Remove all 0s
    data.shock = reshape(data.shock,[],2);

    % Create relief markers - same steps
    data.reliefMarker(data.reliefMarker(:,2) == 0, :) = [];
    data.reliefMarker = floor(data.reliefMarker);
    data.reliefMarker(data.reliefMarker < sig_start | data.reliefMarker > sig_end) = 0;
    data.reliefMarker = [nonzeros(data.reliefMarker(:,1));ones(length(nonzeros(data.reliefMarker(:,1))),1)];
    data.reliefMarker = reshape(data.reliefMarker, [],2);

    % Remove noisy parts of signal
    data.fEMG2(:,1) = floor(data.fEMG2(:,1)); %For time, remove data after decimal point
    data.fEMG2(1:sig_start,:) = [];
    data.fEMG2((sig_end-sig_start):end,:) = [];

    % Removing spikes
    for i = abs(data.fEMG2(:,2)) >= 3  
        data.fEMG2(i,2) = mean(data.fEMG2(:,2));
    end
    
    CurrData.raw = data.fEMG2;
    CurrData.time = CurrData.raw(:,1);
    CurrData.signal = CurrData.raw(:,2); 
    
    % Bandpass filter due to harmonics - at 50, 100, 150 Hz
    CurrData.filtered1 = bandstop(CurrData.signal,[48 52],1000);
    CurrData.filtered2 = bandstop(CurrData.filtered1,[98 102],1000);
    CurrData.filtered3 = bandstop(CurrData.filtered2,[148 152],1000);
    
    % Bandpass Butterworth filter 20-500 Hz
    CurrData.filtered4 = M_SimpleButterFilterZeroPhase(CurrData.filtered3 , 1000, 'bandpass', [20 499], 1);
    
    % Rectify data
    CurrData.rect = abs(CurrData.filtered4);
     
    % Lowpass Butterworth filter at 40 Hz
    CurrData.rectfilt =  M_SimpleButterFilterZeroPhase(CurrData.rect, 1000, 'low', 40, 1);
    
    %% Average values
    % Try with window size of 100 and 500 first, and then try all values.
    k_values = [100 500];
    % k_values = [5 10 20 50 100 200 300 400 500];
    for k = k_values
        %% Average(shock)
        shock_mean=zeros(1,18);
        for i = 1:18
            % For forward bin analysis
            %n = int32(data.shock(i,1)-sig_start);
            %p = mean(CurrData.rectfilt(n:n+k));
            % For timing window analysis
            n = int32(data.shock(i,1)-sig_start-(0.5*k));
            p = mean(CurrData.rectfilt(n:n+(0.5*k)));
            shock_mean(i)=p;

        end
        dlmwrite(strcat(outputPath, 'shock_', string(k), '.txt'), shock_mean, 'delimiter', '\t', 'precision',6);
        %% Average(omission)
        omission_mean=zeros(1,36);
        for j = 1:36
            % For forward bin analysis
            %n = int32(data.reliefMarker(j,1)-sig_start);
            %q = mean(CurrData.rectfilt(n:n+k));
            % For time window analysis
            n = int32(data.reliefMarker(j,1)-sig_start-(0.5*k));
            q = mean(CurrData.rectfilt(n:n+(0.5*k)));
            omission_mean(j)=q;
        end
        dlmwrite(strcat(outputPath, 'omission_', string(k), '.txt'), omission_mean, 'delimiter', '\t', 'precision', 6);
    end
end

%% Butterworth filter function
function [output] = M_SimpleButterFilterZeroPhase(input, SR, type, low, order)
    [b,a]=butter(order,low/(SR/2),type);
    output = filtfilt(b,a,input);  %filtered signal
end
