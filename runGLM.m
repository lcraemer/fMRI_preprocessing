% fMRI GLM
%
% This script runs the GLM for the preprocessed fMRI data obtained by
% running runPreprocessing.m

% Initialization
% --------------

clc
close all
clear all
dbstop if error
metadata_remove

% Directories
% -----------

% SPM12
spm_path = fullfile(userpath, 'spm12');
addpath(spm_path)
spm('defaults','fmri')
spm_jobman('initcfg')

% Data source root directory
% E.g., ds_root = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
if ispc
    ds_root = 'G:\Pilot_P8_MRT\BIDS';  % For Windows
elseif ismac
    ds_root = '/Volumes/WORK/Pilot_P8_MRT/BIDS';  % For macOS
else
    error('Unsupported operating system');
end
src_dir = 'func';  % functional data sub-directory

% Subject directories
% E.g., sub_dir = {'sub-01', 'sub-02', 'sub-03'};
sub_dir = dir(fullfile(ds_root,'sub*'));
sub_dir = {sub_dir.name}';

% Data target directory
if ispc
    tgt_dir = 'G:\Pilot_P8_MRT\derived';  % For Windows
elseif ismac
    tgt_dir = '/Volumes/WORK/Pilot_P8_MRT/derived';  % For macOS
else
    error('Unsupported operating system');
end

% BIDS format file name part labels
BIDS_fn_label{1} = '_Predator'; % BIDS file name task label
BIDS_fn_label{2} = ''; % BIDS file name acquisition label
BIDS_fn_label{3} = '_run-0'; % BIDS file name run index
BIDS_fn_label{4} = '_bold'; % BIDS file name modality suffix

% Preprocessing object
% --------------------

% Select run numbers
% E.g., run_sel = {[1 2 3 4 5 6], [1 2 3 4 5 6]};
% first vector in the first cell is for subject 1 and for the first task, second vector is for the second task
%%% split between {[T1/localizer],[task]}
for i = 1:length(sub_dir)
    run_sel{i} = {[19],[10 12 14 16]};
end

% Preprocessing variables
prep_vars = struct();
prep_vars.spm_path = spm_path;
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.prep_steps = [];
prep_vars.nslices = 72;
prep_vars.TR = 1;
prep_vars.slicetiming = [0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
                         0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
                         0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
                         0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
                         0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
                         0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57];

% Cycle over participants
% -----------------------
%%% why 23?
% for i = 23:numel(sub_dir)
for i = 1:numel(sub_dir)

    prep_vars.run_sel = run_sel{i};
    
    % Preprocessing object instance
    prep = prepobj(prep_vars);
    
    % generate onsets files from '*_events' files in the 'func' directory
    create_onset_files(prep,sub_dir{i});

    %%% what if I don't have s5nar because I did not do smoothing?
    % set parameters for GLM
    prefix = 's5nar';
    fir = 0; % no finite impulse response model
    is_loc = 0; % if GLM for localizer should be computed or not
    mparams = 1 ; % do / do not include movement parameters
    tapas_denoise = 0; % do/ do not include tapas noise regressors
    physio = 0 ; % do / do not include physiological variables
    glmdenoise =  0; % do / do not include GLM denoise regressors
    results_dir = fullfile(tgt_dir,sub_dir{i}, 'GLM');
    if ~isdir(results_dir), mkdir(results_dir); end
    
    % Run GLM for current subject
    matlabbatch = firstlevel(prep,prefix,results_dir,sub_dir{i},mparams,physio,tapas_denoise,glmdenoise,is_loc);
    spm_jobman('run',matlabbatch)
    
    % run contrasts
    if is_loc
        
        % Set contrasts
        clear matlabbatch
        matlabbatch{1}.spm.stats.con.spmmat = {fullfile(results_dir,'SPM.mat')};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'objects > scrambled';
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 1 -1];
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'scrambled > objects';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 -1 1];
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'all > baseline';
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 1 1];
        matlabbatch{1}.spm.stats.con.delete = 1 ;
        spm_jobman('run',matlabbatch)
    else
        % Set contrasts
        clear matlabbatch
        contrast_names = {'Photo';'Drawing';'Sketch'};%
        for con = 1:length(contrast_names)
            % first get condition order
            cond_order = get_cond_order(prep,sub_dir{i});
            cond_order(cond_order ~=con) =0;
            cond_order(cond_order==con)=1;
            
            weights = [];
            
            for run = 1:length(cond_order)
                weights = [weights,[ones(1,48),zeros(1,36)]*cond_order(run)];
            end
            matlabbatch{1}.spm.stats.con.spmmat = {fullfile(results_dir,'SPM.mat')};
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = contrast_names{con};
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = weights;
        end
        matlabbatch{1}.spm.stats.con.delete = 1 ;
        spm_jobman('run',matlabbatch)
    end
end 
    fprintf('GLM finished\n');