function lmb_split_motl(input_motl_fn, even_motl_fn, odd_motl_fn)
    input_motl = getfield(tom_emread(input_motl_fn), 'Value');
    even_motl = input_motl(:, 2:2:end);
    odd_motl = input_motl(:, 1:2:end);

    tom_emwrite(even_motl_fn, even_motl);
    check_em_file(even_motl_fn, even_motl);
    tom_emwrite(odd_motl_fn, odd_motl);
    check_em_file(odd_motl_fn, odd_motl);
end

%% check_em_file
% A function to check that an EM file was correctly written.
function check_em_file(em_fn, em_data)
    while true
        try
            % If this fails, catch command is run
            tom_emread(em_fn);
            break;
        catch
            tom_emwrite(em_fn, em_data)
        end
    end
end
