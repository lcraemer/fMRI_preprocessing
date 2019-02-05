classdef gb_prepobj
    %GB_PREPOBJ Gabor-bandit preprocessing class definition file
    %   This class contains properties and methods to preprocess
    %   Gabor-Bandit fMRI data. 
    
    properties
        
        ds_root; % Data source root directory
        src_dir; % Source directory
        tgt_dir; % Data target directory
        BIDS_fn_label; % BIDS format file name part labels
        run_sel % fMRI lowest and highest run number
    end
    
    methods
        
        function prepobj = gb_prepobj(prep_vars)
            % GB_PREPOBJ Gabor-bandit preprocessing object
            %   This function creates a task object of class gb_prepobj based
            %   on the prep_vars initialization input structure.
            
            % Set variable task properties based on input structure
            prepobj.ds_root = prep_vars.ds_root;
            prepobj.src_dir = prep_vars.src_dir;
            prepobj.tgt_dir = prep_vars.tgt_dir;
            prepobj.BIDS_fn_label = prep_vars.BIDS_fn_label;
            prepobj.run_sel = prep_vars.run_sel;
            
        end
        
        function prepobj = spm_fmri_preprocess(prepobj, sub_dir) 
            % SPM_FMRI_PREPROCESS fMRI Preprocessing
            %   This function implements the preprocessing the fMRI data 
            %   
            %   Preprocessing steps include
            %       1. Realignement
            %       2. Normalization
            %       3. Smoothing
            %
            %   Input
            %       sub_dir: Subject-specific .nii.gz directory
            %
            %   Output
            %       none


            % Create preprocessing file directory
            % -----------------------------------
            
            % aAbsolute subject root directory
            sub_src_dir = fullfile(prepobj.ds_root, sub_dir, prepobj.src_dir);
            sub_pre_dir = fullfile(prepobj.tgt_dir, sub_dir, 'PRE');
            
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
            for r = prepobj.run_sel(1):prepobj.run_sel(2) %length(run_dir) % achung, momentan ab run 2!!!
                
                % run directory
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
                job = [];
                job{1}.spm.util.split.vol = {tfn(1:end-3)}; % single .nii to partition
                job{1}.spm.util.split.outdir = {''}; % output directory is source file directory
                spm_jobman('run', job);
                
                % Event data
                % ---------------------------------------------------------------------
                % source and target file copying
                %sfn = fullfile(sub_src_dir, 'func', [sub_dir BIDS_fn_label{1} BIDS_fn_label{3} num2str(r) '_events.tsv']);
                %sfn = fullfile(sub_src_dir, [sub_dir BIDS_fn_label{1} BIDS_fn_label{3} num2str(r) '_events.tsv']);
                %tfn = fullfile(sub_pre_run_dir, [sub_dir BIDS_fn_label{1} BIDS_fn_label{3} num2str(r) '_events.tsv']);
                %copyfile(sfn,tfn)
            end
            
            % Realignment
            % -----------
            job = [];                                                               % initialize job structure
            
            % Cycle over EPI volumes for realignment
            for r = prepobj.run_sel(1):prepobj.run_sel(2) %:2%1:length(run_dir)
                
                % Specify data
                filt = ['^' sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) '_00.*\.nii$'];         % filename filter
                run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]);              % run directory
                f = spm_select('List',run_dir , filt);                        % file selection
                fs = cellstr([repmat([run_dir filesep], size(f,1), 1) f, repmat(',1', size(f,1), 1)]); % create SPM style file list for model specification
                
                % Assign to job structure = realignment to the first volume of the first run
                job{1}.spm.spatial.realign.estwrite.data{r-prepobj.run_sel(1)+1} = fs;
                
            end
            
            % Job structure specification
            job{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9; % transformation parameter estimation ("est") options - SPM12 default values quality parameter
            job{1}.spm.spatial.realign.estwrite.eoptions.sep = 4; % separation
            job{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5; % smoothing (FWHM)
            job{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0; % register to first: images are registered to the first image in the series
            job{1}.spm.spatial.realign.estwrite.eoptions.interp = 2; % interpolation polynomial order
            job{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0]; % no wrapping
            job{1}.spm.spatial.realign.estwrite.eoptions.weight = ''; % no weighting
            job{1}.spm.spatial.realign.estwrite.roptions.which = [2 1]; % resampling ("write") options - SPM12 default values
            job{1}.spm.spatial.realign.estwrite.roptions.interp = 4; % 4th degree B-Spline interpolation
            job{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0]; % no wrapping
            job{1}.spm.spatial.realign.estwrite.roptions.mask = 1; % Masking
            job{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r'; % create new images with prefix 'r' (realignment)
            
            % Save the job variable to disc
            save([sub_pre_dir, '/job_realignment.mat'], 'job');
            fprintf(['Realignment ',sub_dir, '\n']);
            
            % Run job
            spm_jobman('run', job);
            
            % Normalization
            % -------------
            
            % Location of the tissue probability/MNI template image
            tpm_ima = '/Users/rasmus/Dropbox/gabor_bandit/code/spm12/tpm/TPM.nii';
            
            % Initialize filename array
            fs      = [];
            
            % Cycle over EPI volumes for normalization - all
            for r = prepobj.run_sel(1):prepobj.run_sel(2)%:length(run_dir)
                filt = ['^r' sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) '_00.*\.nii$'];        % filename filter
                run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % run directory
                f = spm_select('List', run_dir, filt); % file selection
                fs = [fs; cellstr([repmat([run_dir filesep], size(f,1), 1) f repmat(',1', size(f,1), 1)])]; % SPM style filename list
            end
            
            % Specify normalization job
            job = []; % initialize job structure
            job{1}.spm.spatial.normalise.estwrite.subj.vol = fs(1); % first realigned image of the first run
            job{1}.spm.spatial.normalise.estwrite.subj.resample = fs; % all realigned images
            job{1}.spm.spatial.normalise.estwrite.eoptions.biasreg = 0.0001; % regularization parameter
            job{1}.spm.spatial.normalise.estwrite.eoptions.biasfwhm = 60; % smoothed image for parameter estimation
            job{1}.spm.spatial.normalise.estwrite.eoptions.tpm = {tpm_ima}; % tissue probability map = MNI space template
            job{1}.spm.spatial.normalise.estwrite.eoptions.affreg  = 'mni'; % normalization to MNI space
            job{1}.spm.spatial.normalise.estwrite.eoptions.reg= [0 0.001 0.5 0.05 0.2];
            job{1}.spm.spatial.normalise.estwrite.eoptions.fwhm = 0; % smoothing kernel
            job{1}.spm.spatial.normalise.estwrite.eoptions.samp = 3; % resampling
            job{1}.spm.spatial.normalise.estwrite.woptions.bb = [-78 -112 -70
                78 76 85];     % MNI space bounding box
            job{1}.spm.spatial.normalise.estwrite.woptions.vox = [2 2 2]; % re-interpolated voxel size
            job{1}.spm.spatial.normalise.estwrite.woptions.interp = 4; % interpolation constant
            job{1}.spm.spatial.normalise.estwrite.woptions.prefix = 'n'; % output file prefix
            
            % Save the job variable to disc
            save([sub_pre_dir, '/job_normalization.mat'], 'job');
            fprintf(['Normalization ',sub_dir, '\n']);
            
            % Run job
            spm_jobman('run', job);
            
            % Smoothing
            % ---------
            
            % Initialize filename array
            fs      = [];
            
            % Cycle over EPI volumes for smoothing
            for r = prepobj.run_sel(1):prepobj.run_sel(2) %1:length(run_dir)
                filt = ['^nr' sub_dir prepobj.BIDS_fn_label{1} prepobj.BIDS_fn_label{3} num2str(r) '_00.*\.nii$']; % filename filter
                run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % run directory
                f = spm_select('List', run_dir, filt); % file selection
                fs = [fs; cellstr([repmat([run_dir filesep], size(f,1), 1) f repmat(',1', size(f,1), 1)])]; % SPM style filename list
            end
            
            % Job structure specification
            job = []; % job structure initialization
            job{1}.spm.spatial.smooth.data = fs; % filenames
            job{1}.spm.spatial.smooth.fwhm = [8 8 8]; % Gaussian smoothing kernel FWHM
            job{1}.spm.spatial.smooth.dtype = 0; % file type
            job{1}.spm.spatial.smooth.im = 0; % no implicit masking
            job{1}.spm.spatial.smooth.prefix= 's'; % create new images with prefix 's' (smoothing)
            
            % Save the job variable to disc
            save([sub_pre_dir, '/job_smoothing.mat'], 'job');
            fprintf(['Smoothing ',sub_dir, '\n']);
            
            % Run job
            spm_jobman('run', job);
        end
        
        function prepobj = spm_delete_preprocess_files(prepobj, sub_dir)
            % SPM_DELTETE_PREPROCESS_FILES Delepte preprocessed files
            %   This function deletes intermediate files created by SPM12 during EPI data
            %   preprocessing for the sake of saving disk space
            %
            %   Inputs
            %       sub_dir: Subject-specific .nii.gz directory
            %
            %   Outputs
            %       none
            
            % Absolute subject root directory
            sub_pre_dir = fullfile(prepobj.tgt_dir, sub_dir, 'PRE');
            
            % Inform user
            fprintf('Deleting r* and nr* files ... \n');
            
            % Delete r* and nr* files
            for r = prepobj.run_sel(1):prepobj.run_sel(2) %length(run_dir)
                sub_pre_run_dir = fullfile(sub_pre_dir, ['RUN_0' num2str(r)]); % subject run directory
                delete(fullfile(sub_pre_run_dir, 'r*.nii')); % delete r* files
                delete(fullfile(sub_pre_run_dir, 'nr*.nii')); % delete nr* files
            end
        end
    end
end

