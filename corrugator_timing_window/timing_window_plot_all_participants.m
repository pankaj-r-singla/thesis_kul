% This file generates timing window graphs for all participants for shock and omission trials, for all 54 trials.
% Before running this, you need to run the timing_window_data_all_participants.m file, to generate the binned data.
outputdir = 'output_directory_for_all_participants (with \ at the end)'

% All participants
participants = dir(outputdir);
cd(outputdir)
for i = 3:length(participants)
   participant = participants(i).name;
   cd(participant);
   plotOneParticipant(participant, outputdir);
   cd ..
end

%% Function to plot for each participant
function plotOneParticipant(participant, outputdir)
    outputPath = strcat(outputdir, participant);
    cd(outputPath);
    % Use the same k values used in the previous file for generating the binned data.
    k_values = [100 500];
    % k_values = [5 10 20 50 100 200 300 400 500];
    for k = k_values
        shock_file = strcat('shock_', string(k), '.txt');
        shock_data = fscanf(fopen(shock_file), '%f');
        shock_data = shock_data';
        shock_data = [shock_data zeros(1,18)];
        omission_file = strcat('omission_', string(k), '.txt');
        omission_data = fscanf(fopen(omission_file), '%f');
        omission_data = omission_data';
        figure (1);
        plot(shock_data);
        hold on;
        plot(omission_data);
        hold off;
        legend('Shock Trials', 'Omission Trials');
        title(strcat('Corrugator (frowning) Activity for Participant', " ", participant, '. Timing window size', " ", string(k)));
        saveas(1, strcat('plot_', string(k), '.png'));
        close(1);
    end
end
