function even_odd_motl(input_motl_fn, split_row, even_motl_fn, odd_motl_fn)
% EVEN_ODD_MOTL split a MOTL file into even odd halves
%     EVEN_ODD_MOTL(
%         INPUT_MOTL_FN,
%         SPLIT_ROW,
%         EVEN_MOTL_FN,
%         ODD_MOTL_FN)
%
%    Takes the MOTL file specified by INPUT_MOTL_FN and writes out seperate
%    MOTL files with EVEN_MOTL_FN and ODD_MOTL_FN where each output file
%    corresponds to roughly half of INPUT_MOTL_FN. The MOTL is split by the
%    values in SPLIT_ROW, initially just taking even/odd halves of the unique
%    values in that given row, and then this is slightly adjusted by naively
%    adding to the lesser half until closest to half is found.
%
% Example:
%     EVEN_ODD_MOTL('combinedmotl/allmotl_1.em', 4, ...
%         'even/combinedmotl/allmotl_1.em', 'odd/combinedmotl/allmotl_1.em');
%
% See also SPLIT_MOTL_BY_ROW

% DRM 07-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_motl_fn = 'input_motl.em';
% split_row = 4;
% even_motl_fn = 'input_motl_even.em'
% odd_motl_fn = 'input_motl_odd.em'
%##############################################################################%
    % Evaluate numeric input
    if ischar(split_row)
        split_row = str2double(split_row);
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');
    split_vals = unique(input_motl(split_row, :));

    start_odd = 1;
    odd_motl  = input_motl(:, ismember(input_motl(split_row, :), ...
        split_vals(start_odd:2:end)));
    size_odd =  size(odd_motl, 2);

    start_even = 2;
    even_motl = input_motl(:, ismember(input_motl(split_row, :), ...
        split_vals(start_even:2:end)));
    size_even = size(even_motl, 2);

    odd_bigger = size_odd >= size_even;

    while size_odd ~= size_even
        if odd_bigger
            start_odd = start_odd + 2;
            new_odd_motl = input_motl(:, ismember(input_motl(split_row, :), ...
                split_vals(start_odd:2:end)));
            new_size_odd = size(new_odd_motl, 2);

            new_even_motl = input_motl(:, ismember(input_motl(split_row, :), ...
                split_vals([1:2:start_odd - 2, start_even:2:end])));
            new_size_even = size(new_even_motl, 2);

            new_odd_bigger = new_size_odd >= new_size_even;
            if ~(odd_bigger & new_odd_bigger)
                old_ratio = size_odd / size_even - 1;
                new_ratio = new_size_even / new_size_odd - 1;
                if old_ratio < new_ratio
                    break
                else
                    odd_motl  = new_odd_motl;
                    even_motl = new_even_motl;
                    break
                end
            end
        else
            start_even = start_even + 2;
            new_even_motl = input_motl(:, ismember(input_motl(split_row, :), ...
                split_vals(start_even:2:end)));
            new_size_even = size(new_even_motl, 2);

            new_odd_motl = input_motl(:, ismember(input_motl(split_row, :), ...
                split_vals([2:2:start_even - 2, start_odd:2:end])));
            new_size_odd = size(new_odd_motl, 2);

            new_odd_bigger = new_size_odd >= new_size_even;
            if ~(odd_bigger & new_odd_bigger)
                old_ratio = size_even / size_odd - 1;
                new_ratio = new_size_odd / new_size_even - 1;
                if old_ratio < new_ratio
                    break
                else
                    odd_motl  = new_odd_motl;
                    even_motl = new_even_motl;
                    break
                end
            end
        end
    end

    tom_emwrite(even_motl_fn, even_motl);
    check_em_file(even_motl_fn, even_motl);
    tom_emwrite(odd_motl_fn, odd_motl);
    check_em_file(odd_motl_fn, odd_motl);
end

%##############################################################################%
%                                CHECK_EM_FILE                                 %
%##############################################################################%
function check_em_file(em_fn, em_data)
% CHECK_EM_FILE check that an EM file was correctly written.
%     CHECK_EM_FILE(...
%         EM_FN, ...
%         EM_DATA)
%
%     Tries to verify that the EM-file was correctly written before proceeding,
%     it should always be run following a call to TOM_EMWRITE to make sure that
%     that function call succeeded. If an error is caught here while trying to
%     read the file that was just written, it just tries to write it again.
%
% Example:
%   CHECK_EM_FILE('my_EM_filename.em', my_EM_data);
%
% See also TOM_EMWRITE

% DRM 11-2017
    size_check = numel(em_data) * 4 + 512;
    while true
        listing = dir(em_fn);
        if isempty(listing)
            fprintf('******\nWARNING:\n\tFile %s does not exist!', em_fn);
            tom_emwrite(em_fn, em_data);
        else
            if listing.bytes ~= size_check
                fprintf('******\nWARNING:\n');
                fprintf('\tFile %s is not the correct size!', em_fn);
                tom_emwrite(em_fn, em_data);
            else
                break;
            end
        end
    end
end
