function cat_motls(write_output, output_motl_fn, sort_row, varargin)
% CAT_MOTLS concatenate motive lists and print on the standard ouput.
%     CAT_MOTLS(
%         WRITE_OUTPUT,
%         OUTPUT_MOTL_FN,
%         SORT_ROW,
%         INPUT_MOTL_FNS)
%
%     Takes the motive lists INPUT_MOTL_FNS, and concatenates them all together.
%     If WRITE_OUTPUT evaluates to True as a boolean then the joined motive
%     lists are written out as OUPUT_MOTL_FN. Since the 
%     used to find the files, and this does not guarantee that the output motive
%     list will have any form of sorting, if SORT_ROW is a valid field number
%     the output motive list will be sorted by SORT_ROW.
%
%     The motive list is also printed to standard ouput. An arbitrary choice has
%     been made to ouput the motive list in STAR format, since it is used in
%     other more well-known EM software packages. 
%
% Example:
%     CAT_MOTLS(1, 'combinedmotl/allmotl_4_joined.em', 4, ...
%         'combinedmotl/allmotl_1_tomo_1.em', ...
%         'combinedmotl/allmotl_1_tomo_3.em');

% DRM 07-2018
%##############################################################################%
%                                    DEBUG                                     %
%##############################################################################%
% write_output = 1;
% output_motl_fn = 'output_motl.em';
% sort_row = 7;
% varargin = {'combinedmotl/allmotl_1_tomo_1.em'};
%##############################################################################%
    % Evaluate numeric input
    if ischar(write_output)
        write_output = str2double(write_output);
    end
    write_output = logical(write_output);

    if ischar(sort_row)
        sort_row = str2double(sort_row);
    end

    allmotl = [];
    if sort_row >= 1 && sort_row <= 20
        do_sort = 1;
    else
        do_sort = 0;
    end

    for motl_fn = varargin
        motl = getfield(tom_emread(motl_fn{1}), 'Value');
        allmotl = [allmotl motl];
    end

    if do_sort
        allmotl_sorted = transpose(sortrows(allmotl', sort_row));
        allmotl = allmotl_sorted;
    end

    if write_output
        tom_emwrite(output_motl_fn, allmotl);
        check_em_file(output_motl_fn, allmotl);
    end

    fprintf('\ndata_MOTL\n\nloop_\n');
    fprintf('_motlCCC #1\n')
    fprintf('_motlMarkerSet #2\n')
    fprintf('_motlPickParticleRadius #3\n')
    fprintf('_motlParticleNumber #4\n')
    fprintf('_motlTomogramNumber #5\n')
    fprintf('_motlPickParticleObject #6\n')
    fprintf('_motlTomogramID #7\n')
    fprintf('_motlCoordinateX #8\n')
    fprintf('_motlCoordinateY #9\n')
    fprintf('_motlCoordinateZ #10\n')
    fprintf('_motlPostShiftX #11\n')
    fprintf('_motlPostShiftY #12\n')
    fprintf('_motlPostShiftZ #13\n')
    fprintf('_motlPreShiftX #14\n')
    fprintf('_motlPreShiftY #15\n')
    fprintf('_motlPreShiftZ #16\n')
    fprintf('_motlPhiSpin #17\n')
    fprintf('_motlPsiRot #18\n')
    fprintf('_motlThetaTilt #19\n')
    fprintf('_motlClassNumber #20\n')
    for motl_idx = 1:size(allmotl, 2)
        fprintf('%-12.6f ', allmotl(1, motl_idx));
        fprintf('%-8d ', allmotl(2, motl_idx));
        fprintf('%-8d ', allmotl(3, motl_idx));
        fprintf('%-8d ', allmotl(4, motl_idx));
        fprintf('%-8d ', allmotl(5, motl_idx));
        fprintf('%-8d ', allmotl(6, motl_idx));
        fprintf('%-8d ', allmotl(7, motl_idx));
        fprintf('%-12.6f ', allmotl(8, motl_idx));
        fprintf('%-12.6f ', allmotl(9, motl_idx));
        fprintf('%-12.6f ', allmotl(10, motl_idx));
        fprintf('%-12.6f ', allmotl(11, motl_idx));
        fprintf('%-12.6f ', allmotl(12, motl_idx));
        fprintf('%-12.6f ', allmotl(13, motl_idx));
        fprintf('%-12.6f ', allmotl(14, motl_idx));
        fprintf('%-12.6f ', allmotl(15, motl_idx));
        fprintf('%-12.6f ', allmotl(16, motl_idx));
        fprintf('%-12.6f ', allmotl(17, motl_idx));
        fprintf('%-12.6f ', allmotl(18, motl_idx));
        fprintf('%-12.6f ', allmotl(19, motl_idx));
        fprintf('%-8d\n', allmotl(20, motl_idx));
    end
    fprintf('\n');
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
