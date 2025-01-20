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
clear all

% Directories 
% -----------

% SPM12
spm_path = addpath(fullfile(userpath, 'spm12'));
addpath(spm_path)
spm('defaults','fmri')
spm_jobman('initcfg')

% TAPAS toolbox 
tapas_path = addpath(fullfile(userpath, 'tapas'));
addpath(tapas_path)

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
BIDS_fn_label{1} = '_task-gb'; % BIDS file name task label
BIDS_fn_label{2} = ''; % BIDS file name acquisition label
BIDS_fn_label{3} = '_run-0'; % BIDS file name run index
BIDS_fn_label{4} = '_bold'; % BIDS file name modality suffix

% Preprocessing object
% --------------------

% Select run numbers 
% E.g., run_sel = {[1 2 3 4 5 6], [1 2 3 4 5 6]};
% first vector in the first cell is for subject 1 and for the first task, second vector is for the second task
for i = 1:length(sub_dir)
    run_sel{i} = {[10 12 14 16]};
end 

% Select preprocessing steps 
%       0. Create folder and import func and anat files --> if this is
%       selected the current folder is deleted and recreated 
%       1. Segmentation/Normalization of T1 images
%       2. Realignement
%       3. Slice-timing correction
%       4. Coregistration of mean EPI to T1       
%       5. Application of normalization parameters to EPI data
%       6. Estimation of noise regressors using the aCompCor method
%       (Behzadi,2018) 
%       7. Smoothing (optional) 
prep_steps = [0:7];

% Preprocessing variables
prep_vars = struct();
prep_vars.spm_path = spm_path;
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.prep_steps = prep_steps;
prep_vars.nslices = 72;
prep_vars.TR = 1;
prep_vars.slicetiming = [0.5,0.09000000000003183,-0.32000000000005,0.25,-0.1499999999999773,0.4199999999999591,0.009999999999990905,-0.3999999999999773,0.1699999999999591,-0.2400000000000091,0.3400000000000318,-0.07000000000005002,0.5,0.09000000000003183,-0.32000000000005,0.25,-0.1499999999999773,0.4199999999999591,0.009999999999990905,-0.3999999999999773,0.1699999999999591,-0.2400000000000091,0.3400000000000318,-0.07000000000005002,0.5,0.09000000000003183,-0.32000000000005,0.25,-0.1499999999999773,0.4199999999999591,0.009999999999990905,-0.3999999999999773,0.1699999999999591,-0.2400000000000091,0.3400000000000318,-0.07000000000005002,0.5,0.09000000000003183,-0.32000000000005,0.25,-0.1499999999999773,0.4199999999999591,0.009999999999990905,-0.3999999999999773,0.1699999999999591,-0.2400000000000091,0.3400000000000318,-0.07000000000005002,0.5,0.09000000000003183,-0.32000000000005,0.25,-0.1499999999999773,0.4199999999999591,0.009999999999990905,-0.3999999999999773,0.1699999999999591,-0.2400000000000091,0.3400000000000318,-0.07000000000005002,0.5,0.09000000000003183,-0.32000000000005,0.25,-0.1499999999999773,0.4199999999999591,0.009999999999990905,-0.3999999999999773,0.1699999999999591,-0.2400000000000091,0.3400000000000318,-0.07000000000005002];                     

% Cycle over participants
% -----------------------
for i = 1:numel(sub_dir)
    
    prep_vars.run_sel = run_sel{i};

    % Preprocessing object instance
    prep = prepobj(prep_vars);
    
    % Run preprocessing for current subject
    prep.spm_fmri_preprocess(sub_dir{i});
    
    % Delete intermediate files created by SPM12 during fMRI data preprocessing
    prep.spm_delete_preprocess_files(sub_dir{i});
    
end

fprintf('Preprocessing finished\n');