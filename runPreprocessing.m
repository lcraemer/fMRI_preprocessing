% fMRI Preprocessing pipeline
%
% This script preprocesses the BIDS formatted fMRI data
%
%   Preprocessing steps include
%       1. Segmentation/Normalization of T1 images
%       2. Realignement
%       3. Slice-timing correction
%       4. Coregistration of mean EPI to T1       
%       5. Application of normalization parameters to EPI data
%       6. Estimation of noise regressors using the aCompCor method
%       (Behzadi,2018) 
%       7. Smoothing (optional) 

% Initialization
% --------------

clc
close all

% Directories 
% -----------

% SPM12
spm_path = '/Users/johannessinger/Documents/cloud_Berlin/Projekte/dfg/WP1/analysis_tools/spm/spm12/';
addpath(spm_path)
spm('defaults','fmri')
spm_jobman('initcfg')

% Subject directories
% E.g., sub_dir = {'sub-01', 'sub-02', 'sub-03'};
sub_dir = {'sub-01'};

% Data source root directory
% E.g., ds_root = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
ds_root = '/Users/johannessinger/Documents/cloud_Berlin/Projekte/fmri_pipeline/data';
src_dir = 'func';  % functional data sub-directory

% Data target directory 
tgt_dir = '/Users/johannessinger/Documents/cloud_Berlin/Projekte/fmri_pipeline/derived'; 

% BIDS format file name part labels
BIDS_fn_label{1} = '_task-main'; % BIDS file name task label
BIDS_fn_label{2} = ''; % BIDS file name acquisition label
BIDS_fn_label{3} = '_run-00'; % BIDS file name run index
BIDS_fn_label{4} = '_bold'; % BIDS file name modality suffix

% Preprocessing object
% --------------------

% Select run numbers 
% E.g., run_sel = {[1 2 3 4 5 6], [1 2 3 4 5 6]};
run_sel = {[1]};

% Select preprocessing steps 
%       1. Segmentation/Normalization of T1 images
%       2. Realignement
%       3. Slice-timing correction
%       4. Coregistration of mean EPI to T1       
%       5. Application of normalization parameters to EPI data
%       6. Estimation of noise regressors using the aCompCor method
%       (Behzadi,2018) 
%       7. Smoothing (optional) 
prep_steps = [7];

% Preprocessing variables
prep_vars = struct();
prep_vars.spm_path = spm_path;
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.prep_steps = prep_steps;
prep_vars.nslices = 57;
prep_vars.TR = 1.5;
prep_vars.slicetiming = [0, 0.78, 0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125,...
                        0.3125, 1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325,...
                        0.625, 1.4025, 0.7025, 0, 0.78, 0.0775, 0.8575, 0.1575,...
                        0.935, 0.235, 1.0125, 0.3125, 1.09, 0.39, 1.17, 0.4675,...
                        1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025, 0, 0.78,...
                        0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125, 0.3125,...
                        1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025];

% Cycle over participants
% -----------------------
for i = 1:numel(sub_dir)
    
    prep_vars.run_sel = run_sel{i};

    % Preprocessing object instance
    prep = prepobj(prep_vars);
    
    % Run preprocessing for current subject
    prep.spm_fmri_preprocess(sub_dir{i});
    
    % Delete intermediate files created by SPM12 during fMRI data preprocessing
    %prep.spm_delete_preprocess_files(sub_dir{i});
    
end

fprintf('Preprocessing finished\n');