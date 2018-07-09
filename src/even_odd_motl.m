function even_odd_motl(input_motl_fn, even_motl_fn, odd_motl_fn)
% EVEN_ODD_MOTL split a MOTL file into even odd halves
%     EVEN_ODD_MOTL(
%         INPUT_MOTL_FN,
%         EVEN_MOTL_FN,
%         ODD_MOTL_FN)
%
%    Takes the MOTL file specified by INPUT_MOTL_FN and writes out seperate
%    MOTL files with EVEN_MOTL_FN and ODD_MOTL_FN where each output file
%    corresponds to a half of INPUT_MOTL_FN.
%
% Example:
%     EVEN_ODD_MOTL('combinedmotl/allmotl_1.em', ...
%         'even/combinedmotl/allmotl_1.em', 'odd/combinedmotl/allmotl_1.em');
%
% See also SPLIT_MOTL_BY_ROW

% DRM 07-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_motl_fn = 'input_motl.em';
% even_motl_fn = 'input_motl_even.em'
% odd_motl_fn = 'input_motl_odd.em'
%##############################################################################%
    input_motl = getfield(tom_emread(input_motl_fn), 'Value');
    even_motl = input_motl(:, 2:2:end);
    odd_motl = input_motl(:, 1:2:end);
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
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch ME
            fprintf('******\nWARNING:\n\t%s\n******', ME.message);
            tom_emwrite(em_fn, em_data)
        end
    end
end
