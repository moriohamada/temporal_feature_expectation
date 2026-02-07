function [expt, dspec] = get_expt_dspec_for_glm(features, params, ops)

binSize  = ops.tBin*1000;

expt = buildGLM.initExperiment('10ms', 1, [], params);
 
%% Populate expt

regressors = fields(features);

for r = 1:length(regressors)
    if strcmp(regressors{r}, 'duration')
        continue
    else
        reg = regressors{r};
    end
   
    switch reg
        case {'baselineOnset', 'baseline', 'Lick', 'PreLick', 'Lick_e', 'PreLick_e', 'Lick_l', 'PreLick_l', ...
              'TFch_25', 'TFch_100', 'TFch_150', 'TFch_200', 'TFch_250', 'TFch_300', 'TFch_375'}
            expt = buildGLM.registerTiming(expt, reg, reg);
        case {'trialLicked', 'trialFinished', 'Direction', ...
              'outcome_Miss', 'outcome_Hit', 'outcome_FA', 'outcome_abort'}
            expt = buildGLM.registerValue(expt, reg, reg);
        case {'TFbl', 'TFblXDir', 'TFbl_abs', 'time', 'TFblXtime', ...
              'TFbl_e', 'TFbl_l', 'TFbl_f', 'TFbl_s', 'TFbl_fe', 'TFbl_fl', 'TFbl_se', 'TFbl_sl', ...
              'motionEnergy', 'speed', 'BaselineStimOn', 'ChangeStimOn'}
            expt = buildGLM.registerContinuous(expt, reg, reg);
        case 'SpTrain'
            expt = buildGLM.registerSpikeTrain(expt, reg, reg);
        otherwise
            if length(reg) >= 5 && strcmp(reg(1:5), 'Phase')
                expt = buildGLM.registerContinuous(expt, reg, reg);
            elseif strcmp(reg, 'trialOutcome')
                % skip the original string field, we use one-hot versions
                continue
            else
                keyboard
            end
            
    end
end

expt.trial = features;


%% dspec

dspec = buildGLM.initDesignSpec(expt);
binfun = expt.binfun;

% baseline onset
bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(2000/binSize), round(400/binSize), binfun);
dspec = buildGLM.addCovariateTiming(dspec, 'baselineOnset', [], [], bs);

% baseline long
bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(14000/binSize), 14, binfun);
dspec = buildGLM.addCovariateTiming(dspec, 'baseline', [], [], bs);

% Pre-lick and lick
if ~ops.splitELlick
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(200/binSize), binfun);
    offset = round(-1000 / binSize);
    dspec = buildGLM.addCovariateTiming(dspec, 'PreLick', [], [], bs, offset);
    
    offset = 0;
    dspec = buildGLM.addCovariateTiming(dspec, 'Lick', [], [], bs, offset);
else
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(200/binSize), binfun);
    offset = round(-1000 / binSize);
    dspec = buildGLM.addCovariateTiming(dspec, 'PreLick_e', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'PreLick_l', [], [], bs, offset);
    
    offset = 0;
    dspec = buildGLM.addCovariateTiming(dspec, 'Lick_e', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'Lick_l', [], [], bs, offset);
end

% Trial outcome one-hot encoded
if ops.includeTrialOutcome
    outcome_types = {'outcome_Miss', 'outcome_Hit', 'outcome_FA', 'outcome_abort'};
    for i = 1:length(outcome_types)
        outcome_name = outcome_types{i};
        stimHandle = @(features, expt) ...
                       features.(outcome_name) * ...
                       basisFactory.boxcarStim(...
                       binfun(features.baselineOnset), ...
                       binfun(features.duration), ...
                       binfun(features.duration));
        dspec = buildGLM.addCovariate(dspec, outcome_name, outcome_name, stimHandle, []);
    end
end


% TFbl
bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(200/binSize), binfun);
offset = round(0 / binSize);

if ops.splitELtf && ~ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_e', 'Baseline TFs early', bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_l', 'Baseline TFs late', bs, offset);
elseif ~ops.splitELtf && ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_f', 'Baseline TFs fast', bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_s', 'Baseline TFs slow', bs, offset);
elseif ops.splitELtf && ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_fe', 'Baseline TFs fast early', bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_se', 'Baseline TFs slow early', bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_fl', 'Baseline TFs fast late', bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_sl', 'Baseline TFs slow late', bs, offset);
else
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl', 'Baseline TFs', bs, offset);
end

% TFch one-hot encoded
tfch_onehot = {'TFch_25', 'TFch_100', 'TFch_150', 'TFch_200', 'TFch_250', 'TFch_300', 'TFch_375'};
bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1500/binSize), round(300/binSize), binfun);
for i = 1:length(tfch_onehot)
    dspec = buildGLM.addCovariateTiming(dspec, tfch_onehot{i}, [], [], bs, offset);
end

if ops.includeMotionEnergy
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(200/binSize), binfun);
    offset =round(-500 / binSize);
    dspec = buildGLM.addCovariateRaw(dspec, 'motionEnergy', 'Motion energy', bs, offset);
end

if ops.includeRunSpeed
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(200/binSize), binfun);
    offset = round(-500 / binSize);
    dspec = buildGLM.addCovariateRaw(dspec, 'speed', 'Running', bs, offset);
end

% BL and change stimulus on indicator
bs = basisFactory.makeSmoothTemporalBasis('boxcar', 1, 1, binfun);
offset = 0;
dspec = buildGLM.addCovariateRaw(dspec, 'BaselineStimOn', 'baseline on', bs, offset);
dspec = buildGLM.addCovariateRaw(dspec, 'ChangeStimOn', 'change on', bs, offset);



end