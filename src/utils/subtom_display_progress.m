function [new_del_progress, new_timings] = subtom_display_progress(...
    del_progress, timings, message, op_type, num_ops, op_idx)
% SUBTOM_DISPLAY_PROGRESS displays a progress bar
%     SUBTOM_DISPLAY_PROGRESS(
%         DEL_PROGRESS,
%         TIMINGS,
%         MESSAGE,
%         OP_TYPE,
%         NUM_OPS,
%         OP_IDX)
%
%     Writes out a progress bar of the status of the operation currently being
%     done to the standard output. Here NUM_OPS is the total number of
%     operations that need to be completed and OP_IDX is the current number of
%     operations that have been completed. DEL_PROGRESS, delete progress, it is
%     a string that keeps track of the amount of backspaces needed to erase the
%     most recently written progress bar. MESSAGE is shown at the start of the
%     progress bar and OP_TYPE is a string describing the operation.
%
% Example:
%     SUBTOM_DISPLAY_PROGRESS(del_progress, timings, 
%         sprintf('Tomogram %d', process_idx), 'particles', num_ptcls, ptcl_idx)
%

% DRM 06-2018
    % We update the progress bar at most every half-percent
    progress_freq = max(floor(num_ops / 200), 1);

    % Check if we need to update the progress bar or just return early
    if mod(op_idx, progress_freq) ~= 0 && op_idx ~= num_ops
        new_del_progress = del_progress;
        new_timings = timings;
        return
    end

    % Stop and restart the timer
    elapsed_time = toc;
    tic;

    % Add the newly found elapsed time to the timings
    new_timings = [timings elapsed_time];

    % Calculate the total elapsed time in seconds; the sum of all timings.
    total_time_sec = sum(new_timings);

    % Convert the total time in seconds to hours, minutes and seconds.
    tt_hr = floor(total_time_sec / 3600);
    tt_min = floor((total_time_sec - (tt_hr * 3600)) / 60);
    tt_sec = round(total_time_sec - (tt_hr * 3600) - (tt_min * 60));

    % Create the string format for displaying the total time
    tt_str = sprintf('%d:%02d:%02d', tt_hr, tt_min, tt_sec);

    % Calculate the average time per operation and use it to estimate the time
    % to completion in seconds
    avg_time_sec = total_time_sec / op_idx;
    estimate_time_sec = avg_time_sec * num_ops;

    % Convert the estimate time in seconds to hours, minutes and seconds.
    et_hr = floor(estimate_time_sec / 3600);
    et_min = floor((estimate_time_sec - (et_hr * 3600)) / 60);
    et_sec = round(estimate_time_sec - (et_hr * 3600) - (et_min * 60));

    % Create the string format for displaying the estimated time
    et_str = sprintf('%d:%02d:%02d', et_hr, et_min, et_sec);

    % This is the format of the progress bar
    % MESSAGE: [######             ] - PERCENT% - OP_IDX OP_TYPE TT_STR | ET_STR
    fmt_str = '%s: [%s%s] - %d%% - %d %s %s | %s\n';

    % Determine the number of '#' to add inside the progress bar '[###    ]'
    count = round(op_idx / num_ops * 40);
    left = repmat('#', 1, count);
    right = repmat(' ', 1, 40 - count);

    % Determine the percentage to completion
    percent = round(op_idx / num_ops * 100);

    progress = sprintf(fmt_str, message, left, right, percent, op_idx, ...
        op_type, tt_str, et_str);

    % First print the previous del_progress to erase the prior progress bar.
    fprintf(1, del_progress);

    % Next print the updated progress bar.
    fprintf(1, '%s', progress);

    % Create the new del_progress to later erase this progress bar.
    new_del_progress = repmat('\b', 1, length(progress));

    % Handle the last status message.
    if op_idx == num_ops
        fprintf(1, '\n');
    end
end
