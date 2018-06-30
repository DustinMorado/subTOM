function scale_motl(input_motl_fn, output_motl_fn, scale_factor)
% SCALE_MOTL scales a given motive list by a given factor and writes it out.
%     SCALE_MOTL(
%         INPUT_MOTL_FN,
%         OUTPUT_MOTL_FN,
%         SCALE_FACTOR)
%
%     Takes the motive list given by INPUT_MOTL_FN, and scales it by
%     SCALE_FACTOR, and then writes the transformed motive list out as
%     OUTPUT_MOTL_FN.
%
% Example:
%     SCALE_MOTL('../bin8/combinedmotl/allmotl_2.em', ...
%         'combinedmotl/allmotl_1.em', 2);

% DRM 03-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% input_motl_fn = 'input_motl.em';
% output_motl_fn = 'output_motl.em';
% scale_factor = 2;
%##############################################################################%
    if ischar(scale_factor)
        scale_factor = str2double(scale_factor);
    end

    input_motl = getfield(tom_emread(input_motl_fn), 'Value');
    output_motl = input_motl;
    output_motl(11:13, :) = (input_motl(8:10, :) + input_motl(11:13, :)) ...
        .* scale_factor;

    output_motl(8:10, :) = floor(output_motl(11:13, :));
    output_motl(11:13, :) = output_motl(11:13, :) - output_motl(8:10, :);

    tom_emwrite(output_motl_fn, output_motl);
    check_em_file(output_motl_fn, output_motl);
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
