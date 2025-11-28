

function [db, ops] = switch_task_analysis_params()
%%
% Data specification -------------------------------------------------------------------------------
            
% db.animals  = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_007', 'MH_010', 'MH_011', 'MH_014', 'MH_015'};
% db.sessions = {{'h1', 'h2', 'e2', 'e3', 'e4', 'e5', 'e8'}, ...                                      % MH_001
%                {'h1', 'h2', 'h4', 'h5', 'h6', 'e1', 'e2', 'e3'}, ...                                % MH_002 
%                {'e1','e2','e3','e4', 'e6','e7','e8','e9'}, ...                                      % MH_004
%                {'h2', 'h3','e1','e2','e3','e4','e5', 'e6', 'e7', 'e8'}, ...                         % MH_006
%                {'h3', 'h4', 'h5', 'h6', 'e6','e7','e8'}, ...                                        % MH_007
%                {'h2', 'h3', 'h4', 'h5', 'e1','e2','e3', 'e5','e6'}, ...                             % MH_010
%                {'h1', 'h2', 'h3', 'h4', 'h5', 'e1','e2','e3','e4','e5','e6', 'e7'}, ...             % MH_011
%                {'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8'}, ...                                      % MH_014
%                {'h1', 'h2', 'h3', 'h4', 'e1', 'e2', 'e3',  'e5', 'e6'}};                            % MH_015
  
% db.animals  = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_011', 'MH_014', 'MH_015', ...
%                'MH_100', 'MH_103', 'MH_105', 'MH_110', 'MH_111'};
% db.sessions = {{'h1', 'h2', 'e2', 'e3', 'e4', 'e5', 'e8'}, ...                                      % MH_001
%                {'h1', 'h2', 'h4', 'h5', 'h6', 'e1', 'e2', 'e3'}, ...                                % MH_002 
%                {'e1','e2','e3','e4', 'e6','e7','e8','e9'}, ...                                      % MH_004
%                {'h2', 'h3', 'e2','e3','e4','e5','e6', 'e7','e8'}, ...                               % MH_006
%                {'h2', 'h3', 'h4', 'h5', 'e1','e2','e3', 'e5','e6'}, ...                             % MH_010
%                {'h1', 'h2', 'h3', 'h4', 'h5', 'e1','e2','e3','e4' }, ...                            % MH_011
%                {'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8'}, ...                                      % MH_014
%                {'h1', 'h2', 'h3', 'h4', 'e1', 'e2', 'e3',  'e5', 'e6'}, ...                         % MH_015
%                {'h7', 'h10', 'h11', 'h12', 'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'e10'}, ...    % MH_100
%                {'h1', 'e1', 'e2', 'e3', 'e4', 'e5'}, ...                                            % MH_103
%                {'h1', 'h2', 'h4', 'h5', 'h6', 'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9'}, ...        % MH_105
%                {'h6','h7','e1','e2','e3','e4','e5','e6','e7','e8','e9','e10','e11'},...             % MH_110
%                {'h1','h2','h3','h4','h5','h6','e1','e2','e3','e4','e5', 'e7','e8','e9'}};           % MH_111
% 
% db.animals  = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_011', 'MH_014', 'MH_015', ...
%                'MH_100', 'MH_103', 'MH_105', 'MH_110', 'MH_111'};
% db.sessions = {{'h1', 'h2', 'e2', 'e3', 'e4', 'e5', 'e8'}, ...                                      % MH_001
%                {'h1', 'h2', 'h4', 'h5', 'h6', 'e1', 'e2', 'e3'}, ...                                % MH_002 
%                {'e1','e2','e3','e4', 'e6','e7','e8','e9'}, ...                                      % MH_004
%                {'h2', 'h3', 'e2','e3','e4','e5','e6', 'e7','e8'}, ...                               % MH_006
%                {'h2', 'h3', 'h4', 'h5', 'e1','e2','e3', 'e5','e6'}, ...                             % MH_010
%                {'h1', 'h2', 'h3', 'h4', 'h5', 'e1','e2','e3','e4' }, ...                            % MH_011
%                {'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8'}, ...                                      % MH_014
%                {'h1', 'h2', 'h3', 'h4', 'e1', 'e2', 'e3',  'e5', 'e6'}, ...                         % MH_015
%                {'h7', 'h10', 'h11', 'h12', 'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'e10'}, ...    % MH_100
%                {'h1', 'e1', 'e2', 'e3', 'e4', 'e5'}, ...                                            % MH_103
%                {'h1', 'h2', 'h4', 'h5', 'h6', 'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9'}, ...        % MH_105
%                {'h6','h7', 'e1', 'e2', 'e5', 'e6', 'e7','e8', 'e9', 'e10', 'e11'},...               % MH_110
%                {'h1','h2','h3','h4','h5','h6','e1','e2','e3','e4','e5', 'e7','e8','e9'}};           % MH_111

db.animals  = {'MH_001', 'MH_002', 'MH_004', 'MH_006', 'MH_010', 'MH_011', 'MH_014', 'MH_015', ...
               'MH_100', 'MH_103', 'MH_105', 'MH_111'};
db.sessions = {{'h1', 'h2', 'e2', 'e3', 'e4', 'e5', 'e8'}, ...                                      % MH_001
               {'h1', 'h2', 'h4', 'h5', 'h6', 'e1', 'e2', 'e3'}, ...                                % MH_002 
               {'e1','e2','e3','e4', 'e6','e7','e8','e9'}, ...                                      % MH_004
               {'h2', 'h3', 'e2','e3','e4','e5','e6', 'e7','e8'}, ...                               % MH_006
               {'h2', 'h3', 'h4', 'h5', 'e1','e2','e3', 'e5','e6'}, ...                             % MH_010
               {'h1', 'h2', 'h3', 'h4', 'h5', 'e1','e2','e3','e4' }, ...                            % MH_011
               {'h2', 'h3', 'h4', 'h5', 'h6', 'h7', 'h8'}, ...                                      % MH_014
               {'h1', 'h2', 'h3', 'h4', 'e1', 'e2', 'e3',  'e5', 'e6'}, ...                         % MH_015
               {'h7', 'h10', 'h11', 'h12', 'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'e10'}, ...    % MH_100
               {'h1', 'e1', 'e2', 'e3', 'e4', 'e5'}, ...                                            % MH_103
               {'h1', 'h2', 'h4', 'h5', 'h6', 'e2', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9'}, ...        % MH_105
               {'h1','h2','h3','h4','h5','h6','e1','e2','e3','e4','e5', 'e7','e8','e9'}};           % MH_111

% Paths --------------------------------------------------------------------------------------------


ops.dataDir      = '/media/morio/Data_Fast/switch_task_revisions/session_data/';
ops.saveDir      = '/media/morio/Analysis_outputs/switch_task_revisions/manuscript_figures/';

ops.respsIndsDir = '/media/morio/Data_Fast/switch_task_revisions/';
ops.frDir        = '/media/morio/Data_Fast/switch_task_revisions/firing_rates';
ops.eventPSTHdir = '/media/morio/Data_Fast/switch_task_revisions/event_responses/';
ops.avgPSTHdir   = '/media/morio/Data_Fast/switch_task_revisions/avg_responses/';
ops.indexesDir   = '/media/morio/Data_Fast/switch_task_revisions/indexes/';
ops.tuningDir    = '/media/morio/Data_Fast/switch_task_revisions/tuning/';
ops.popDimsDir   = '/media/morio/Data_Fast/switch_task_revisions/session_dims/'; 
ops.tdrGLMDir    = '/media/morio/Data_Fast/switch_task/glm_kernels/glm_mouthO_basicsOnly_230615_25ms/results/';
ops.fullGLMDir   = '/media/morio/Data_Fast/switch_task/glm_kernels/ridge_full50ms';
ops.glmELDir     = '/media/morio/Data_Fast/switch_task/glm_kernels/ridge_splitEL50ms';
ops.npxDir       = '/mnt/ceph/public/projects/MoHa_20201102_SwitchChangeDetection/npx';

% Behaviour options --------------------------------------------------------------------------------
ops.rmvStartTrs      = 10;           % remove first n trials from each session
ops.minNumTrials     = 50;           % minimum number of good trials to keep session
ops.minNumHits       = 30;           % minimum number of hits to include session (of any change magnitude)
ops.performanceBin   = 30;           % calculate running hit/miss/fa etc rates from this many trials
ops.missThresh       = .6;           % remove periods where miss rate higher than this
ops.falseAlarmThresh = .9;           % remove periods where false alarm rate higher than this
ops.abortThresh      = 1;            % remove periods where abort rate higher than this
ops.combinedAbortFA  = 1;            % remove periods where combined false alarm/abort rate higher than this
ops.windows          = [2 7; 8 16];  % early and late windows for analyses
ops.stimWindows      = [4 8; 12 16]; % actual windows used in task
ops.tHistory         = 1.5;          % seconds in past for looking at elta/eltc
ops.ignoreTrStart    = 1.5;            % ignore early licks happening in first n sec
ops.nIter            = 1000;

% For projecting baseline TF onto eigenvectors
ops.nPCs             = 4;            % number of principle components to plot
ops.simMeasure       = 'dot';
ops.lickWindow       = [-.05 .05];
ops.minPulses        = 500;
ops.normLickP        = 1;

% Single pulse behavioural analyses
ops.lickRTWin        = [.25 1];
ops.tfBinStarts      = -1:.05:.99;
ops.tfBinSize        = .1;
ops.delays           = [1:3]; % frames
ops.minSinglePulses  = 500;
ops.minMultiPulses   = 200;
ops.minTrialDur      = 2;
% GLM 

% Ephys analysis options ---------------------------------------------------------------------------
ops.suOnly             = 0;               % logical; whether to use only single units (1) or multiunits as well (0)
ops.minFR              = .1;              % minimum firing rate for neuron to be considered
ops.minFRDrop          = 0;               % minimum firing rate neuron can drop to relative to mean
ops.tfOutlier          = 1.5;             % std dev away from mean to consider outlier
ops.rmvTimeAround      = 1.5;             % remove periods within this time (s) from other salient events
ops.spBinWidth         = 10;              % ms; bin width for counting spikes
ops.spSmoothSize       = 50;              % ms; size of boxcar filter
ops.sigThresh          = .05;
ops.saveFRmatrix       = false;           % also save nN x nT matrix of firing rates while loading
ops.minEventCount      = 5; 
ops.plotMultiUnits     = 0;
ops.nPCdimensions      = 10;

% response windows
ops.respWin.tfShort   = [.05, .35];
ops.respWin.tf        = [.1, .4];
ops.respWin.lick      = [-1, 0];
ops.respWin.preLick   = [-2, -1.4];
ops.respWin.tfContext = [-.5 -.1]; 


% Plot and colour options --------------------------------------------------------------------------
ops.colors.F = [204 37 41]./255;
ops.colors.S = [57 106 177]./255;
ops.colors.F_light= [211 94 96]./255; 
ops.colors.S_light = [114 147 203]./255; 
ops.colors.F_pref = [255 111 97]/255;
ops.colors.S_pref = [112 93 160]/255;
ops.colors.F_pref_light = [255 131 117]/255;
ops.colors.S_pref_light = [112 113 186]/255;
el=cbrewer2('div', 'PuOr', 2);
ops.colors.E = el(1,:);
ops.colors.L = el(2,:);
ops.colors.FA = [197 109 70]/255;
ops.colors.TFresp = [15 76 129]/255;

ops.colors.MOs = [49 150 87]/255;
ops.colors.Vis = [133,193,233]/255;
ops.colors.PPC = [216,185,255]/255;

ops.colors.heatmap = TurqWhiteYellow(256);

ops.colors.spectrum = flipud(sky);

ops.colors.Hit  = [136 175 75]/255; % greenery
ops.colors.Miss = [222 205 190]/255; % samd
end