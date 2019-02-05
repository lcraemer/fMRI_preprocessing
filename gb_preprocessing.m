% This script preprocesses the Gabor-Bandit fMRI data
%
%   Preprocessing steps include
%       1. Realignement
%       2. Normalization
%       3. Smoothing

% Initialization
% --------------

clc
close all

% Directories 
% -----------

% SPM12
addpath('~/Dropbox/gabor_bandit/code/spm12')
spm('defaults','fmri')
spm_jobman('initcfg')

% subject directories
sub_dir = {'sub-01'};

% Data source root directory
ds_root = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
src_dir = 'func';

% Data target directory
tgt_dir = fullfile('/Users/rasmus/Documents/gb_fmri_data/prepr_data'); 


% BIDS format file name part labels
BIDS_fn_label{1} = '_task-gb'; % BIDS file name task label
BIDS_fn_label{2} = ''; % BIDS file name acquisition label
BIDS_fn_label{3} = '_run-0'; % BIDS file name run index
BIDS_fn_label{4} = '_bold'; % BIDS file name modality suffix

% Preprocessing object
% --------------------

% fMRI lowest and highest run number
run_sel = [2, 7]; 

% Preprocessing variables
prep_vars = struct();
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.run_sel = run_sel;

% Preprocessing object instance
prep = gb_prepobj(prep_vars);

% Cycle over participants
% -----------------------
for i = 1:numel(sub_dir)
    
    % Implement the preprocessing of fMRI data related to the PDM project
    prep.spm_fmri_preprocess(sub_dir{i});
    
    % Delete intermediate files created by SPM12 during fMRI data preprocessing
    prep.spm_delete_preprocess_files(sub_dir{i});
    
end

fprintf('Preprocessing finished\n');
