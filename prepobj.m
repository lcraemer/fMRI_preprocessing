classdef prepobj
    %GB_PREPOBJ Gabor-bandit preprocessing class definition file
    %
    %   This class contains properties and methods to preprocess fMRI data

    properties

        spm_path % string spacifying spm path
        ds_root % data source root directory
        src_dir % source directory
        tgt_dir % data target directory
        BIDS_fn_label % BIDS format file name part labels
        prep_steps % preprocessing steps
        run_sel % fMRI run numbers

    end

    methods

        function prepobj = prepobj(prep_vars)
            % GB_PREPOBJ Gabor-bandit preprocessing object
            %
            %   This function creates a task object of class gb_prepobj based
            %   on the prep_vars initialization input structure
            %
            %   Input
            %       prep_vars: Preprocessing-variables-object instance
            %
            %   Output
            %       none

            % Set variable task properties based on input structure
            prepobj.spm_path = prep_vars.spm_path;
            prepobj.ds_root = prep_vars.ds_root;
            prepobj.src_dir = prep_vars.src_dir;
            prepobj.tgt_dir = prep_vars.tgt_dir;
            prepobj.BIDS_fn_label = prep_vars.BIDS_fn_label;
            prepobj.prep_steps = prep_vars.prep_steps;
            prepobj.run_sel = prep_vars.run_sel;

        end

        function prepobj = spm_fmri_preprocess(prepobj, sub_dir)
            % SPM_FMRI_PREPROCESS fMRI Preprocessing
            %
            %   This function implements the preprocessing of the fMRI data
            %
            %   Preprocessing steps include
            %       1. Segmentation/Normalization of T1 images
            %       2. Realignement
            %       3. Coregistration of mean EPI to T1
            %       4. Application of normalization parameters to EPI data
            %       5. Smoothing
            %
            %   Input
            %       prepobj: Preprocessing structure
            %       sub_dir: Subject-specific .nii.gz directory
            %
            %   Output
            %       none

            % Create preprocessing file directory
            % -----------------------------------

            % Absolute subject root directory
            sub_src_dir = fullfile(prepobj.ds_root, sub_dir, prepobj.src_dir); % source directory
            sub_pre_dir = fullfile(prepobj.tgt_dir, sub_dir); % preprocessing directory

            % Delete directory and its contents if it is preexisting and create a new one
            if exist(sub_pre_dir, 'dir')
                rmdir(sub_pre_dir,'s')
                mkdir(sub_pre_dir)
            else
                % Create the directory if it is non-existent
                mkdir(sub_pre_dir)
            end

            warning off

            % Copy, unzip and partition raw data single .nii from BIDS standard
            % -----------------------------------------------------------------

            % Cycle over functional runs
            for r = 1:length(prepobj.run_sel)

                % Run directory
                sub_pre_run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]);
                mkdir(sub_pre_run_dir);

                % fMRI data
                % ---------

                % Source and target file copying
                sfn = fullfile(sub_src_dir, [sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) prepobj.BIDS_fn_label{4} '.nii.gz']);
                tfn = fullfile(sub_pre_run_dir, [sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) '.nii.gz']);
                copyfile(sfn,tfn)

                % Unzip files
                gunzip(tfn)

                % Partition single .nii to multiple .nii (volumes)
                % job = [];
                % job{1}.spm.util.split.vol = {tfn(1:end-3)}; % single .nii to partition
                % job{1}.spm.util.split.outdir = {''}; % output directory is source file directory
                % spm_jobman('run', job);


            end

            % Anatomical data
            struct_dir = fullfile(sub_pre_dir, 'T1');
            mkdir(struct_dir);
            tfn = fullfile(struct_dir, [sub_dir '_T1w.nii.gz']);
            copyfile(sfn, tfn)

            % Unzip files
            gunzip(tfn)

            % Run specified preprocessing steps
            % ---------------------------------

            % Initialize prefix indicating preprocessing step
            curr_prefix = '';

            % Go through specified steps
            for p = prepobj.prep_steps

                switch p

                    case 1 % Segmentation/Normalization of T1 images

                        % Inform user
                        disp(['Step ' num2str(p) ' Segmentation: ' sub_dir])

                        % Run segmentation
                        segmentation(struct_dir, prepobj.spm_path)

                    case 2 % Realignement

                        % Use "r" as prefix for realignment
                        realignment_prefix = 'r';

                        % Cycle over runs
                        for r = 1:length(prepobj.run_sel)

                            % Inform user
                            disp(['Step ' num2str(p) ' Realignment: ' sub_dir ', run ' num2str(r)])

                            % Realignment of current run
                            filt = ['^' sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) '.*\.nii$']; % filename filter
                            run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % run directory
                            realignment(filt, run_dir, realignment_prefix)

                        end

                        % Update prefix
                        curr_prefix = strcat(realignment_prefix, curr_prefix);

                    case 3 % Coregistration of mean EPI to T1

                        % Cycle over runs
                        for r = 1:length(prepobj.run_sel)

                            % Inform user
                            disp(['Step ' num2str(p) ' Coregistration: ' sub_dir ', run ' num2str(r)])

                            % Coregistration of current run
                            filt = ['^mean' sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) '.*\.nii$']; % filename filter
                            run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % run directory
                            coregistration(struct_dir, filt, run_dir, curr_prefix)
                        end

                    case 4 % Application of normalization parameters to EPI data

                        % Use "n" as prefix for normalization
                        normalization_prefix = 'n';

                        % Cycle over runs
                        for r = 1:length(prepobj.run_sel)

                            % Inform user
                            disp(['Step ' num2str(p) ' Normalization: ' sub_dir ', run ' num2str(r)])

                            % Normalization of current run
                            filt = ['^' curr_prefix '.*\.nii'];
                            run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]);
                            normalization(struct_dir, filt, run_dir, normalization_prefix)
                        end

                        % Update prefix
                        curr_prefix = strcat(normalization_prefix, curr_prefix);

                    case 5 % Smoothing

                        % Cycle over runs
                        for r = 1:length(prepobj.run_sel)

                            % Inform user
                            disp(['Step ' num2str(p) ' Smoothing: ' sub_dir ', run ' num2str(r)])

                            % Smoothing of current run
                            filter = ['^' curr_prefix '.*\.nii']; % filter name
                            run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % run directory
                            smoothing(filter, run_dir)
                        end
                end
            end
        end

        function prepobj = spm_delete_preprocess_files(prepobj, sub_dir)
            % SPM_DELTETE_PREPROCESS_FILES Delete preprocessed files
            %   This function deletes intermediate files created by SPM12 during EPI data
            %   preprocessing to save disk space
            %
            %   Inputs
            %       sub_dir: Subject-specific .nii.gz directory
            %
            %   Outputs
            %       none

            % Absolute subject root directory
            sub_pre_dir = fullfile(prepobj.tgt_dir, sub_dir);

            % Inform user
            fprintf('Deleting r* and nr* files... \n\n');
   
            % Delete r* and nr* files
            for r = 1:length(prepobj.run_sel)
                sub_pre_run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % subject run directory
                delete(fullfile(sub_pre_run_dir, 'r*.nii'));
                delete(fullfile(sub_pre_run_dir, 'nr*.nii'));
            end
        end
    end
end

