function subtom_check_em_file(em_fn, em_data)
% SUBTOM_CHECK_EM_FILE check that an EM file was correctly written.
%     SUBTOM_CHECK_EM_FILE(...
%         EM_FN, ...
%         EM_DATA)
%
%     Tries to verify that the EM-file was correctly written before proceeding,
%     it should always be run following a call to TOM_EMWRITE to make sure that
%     that function call succeeded. If an error is caught here while trying to
%     read the file that was just written, it just tries to write it again.
%
% Example:
%   SUBTOM_CHECK_EM_FILE('my_EM_filename.em', my_EM_data);
%
% See also TOM_EMWRITE

% DRM 11-2017
    % Calculate the size of the EM-file, 32-bit float data with a 512B header.
    size_check = numel(em_data) * 4 + 512;

    % Create an infinite loop until we correctly write the file.
    while true
        % Get file stats given the file name.
        listing = dir(em_fn);

        % Check if the file exists.
        if isempty(listing)
            warning('subTOM:NonExistWarning', ...
                'check_em_file: File %s does not exist.', em_fn);

            % Get the information from the warning we just raised.
            [msg, msg_id] = lastwarn;

            % Print out the warning info to stderr, the warning will print twice
            % once with just the message and later with both the type and
            % message.
            fprintf(2, '%s - %s\n', msg_id, msg);

            % Just try and write the file again.
            tom_emwrite(em_fn, em_data);

        % Check if the file is the correct size.
        elseif listing.bytes ~= size_check
            warning('subTOM:WrongSizeWarning', ...
                'check_em_file: File %s is not the correct size.', em_fn);

            % Get the information from the warning we just raised.
            [msg, msg_id] = lastwarn;

            % Print out the warning info to stderr, the warning will print twice
            % once with just the message and later with both the type and
            % message.
            fprintf(2, '%s - %s\n', msg_id, msg);

            % Just try and write the file again.
            tom_emwrite(em_fn, em_data);

        % If both the file exists and is correctly-sized, exit the loop.
        else
            break;
        end
    end
end
