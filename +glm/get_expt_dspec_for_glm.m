function [expt, dspec] = get_expt_dspec_for_glm(features, params, ops)

binSize  = ops.tBin*1000;

expt = buildGLM.initExperiment('frame', 1, [], params);

%% Populate expt

regressors = fields(features);

for r = 1:length(regressors)
    if strcmp(regressors{r}, 'duration')
        continue
    else
        reg = regressors{r};
    end
   
    switch reg
        case {'baselineOnset', 'baseline', 'Lick', 'PreLick', 'Lick_e', 'PreLick_e', 'Lick_l', 'PreLick_l'}
            expt = buildGLM.registerTiming(expt, reg, reg);
        case {'trialLicked', 'trialFinished', 'Direction'}
            expt = buildGLM.registerValue(expt, reg, reg);
        case {'TFbl', 'TFch', 'TFch_f', 'TFch_s', 'TFblXDir', 'TFbl_abs', 'time', 'TFblXtime', ...
              'TFbl_e', 'TFbl_l', 'TFbl_f', 'TFbl_s', 'TFbl_fe', 'TFbl_fl', 'TFbl_se', 'TFbl_sl', ...
              'motionEnergy', 'runSpeed'}
            expt = buildGLM.registerContinuous(expt, reg, reg);
        case 'SpTrain'
            expt = buildGLM.registerSpikeTrain(expt, reg, reg);
        otherwise
            if strcmp(reg(1:5), 'Phase')
                expt = buildGLM.registerContinuous(expt, reg, reg);
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

% % baseline long
% bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(14000/binSize), round(1000/binSize), binfun);
bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(14000/binSize), 14, binfun);

dspec = buildGLM.addCovariateTiming(dspec, 'baseline', [], [], bs);

% Pre-lick and lick
if ~ops.splitELlick
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(500/binSize), round(500/binSize), binfun);
    offset = round(-500 / binSize);
    dspec = buildGLM.addCovariateTiming(dspec, 'PreLick', [], [], bs, offset);
    
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(500/binSize), round(500/binSize), binfun);
    offset = 1;
    dspec = buildGLM.addCovariateTiming(dspec, 'Lick', [], [], bs, offset);
else
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(1000/binSize), binfun);
    offset = round(-1000 / binSize);
    dspec = buildGLM.addCovariateTiming(dspec, 'PreLick_e', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'PreLick_l', [], [], bs, offset);
    
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(500/binSize), round(500/binSize), binfun);
    offset = 1;
    dspec = buildGLM.addCovariateTiming(dspec, 'Lick_e', [], [], bs, offset);
    dspec = buildGLM.addCovariateTiming(dspec, 'Lick_l', [], [], bs, offset);
end

if ops.includeTrialOutcome
% licked in trial
    stimHandle = @(features, expt) ...
                   features.trialLicked * ...
                   basisFactory.boxcarStim(...
                   binfun(features.baselineOnset), ...
                   binfun(features.duration), ...
                   binfun(features.duration));
    dspec = buildGLM.addCovariate(dspec, 'trialLicked', 'Licked in trial', stimHandle, [] );

    % Finished trial
    stimHandle = @(features, expt) ...
                   features.trialFinished * ...
                   basisFactory.boxcarStim(...
                   binfun(features.baselineOnset), ...
                   binfun(features.duration), ...
                   binfun(features.duration));
    dspec = buildGLM.addCovariate(dspec, 'trialFinished', 'Finished trial', stimHandle, [] );
end

% direction
% if ops.includeDirection
%     stimHandle = @(features, expt) ...
%                    features.Direction * ...
%                    basisFactory.boxcarStim(...
%                    binfun(features.baselineOnset), ...
%                    binfun(features.duration), ...
%                    binfun(features.duration));
%     dspec = buildGLM.addCovariate(dspec, 'Direction', 'Gratings direction', stimHandle, [] );
% end

% phase
if ops.includePhase
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(250/binSize), round(250/binSize), binfun);
    for ph_bin = 1:360/ops.phaseSplit
        dspec = buildGLM.addCovariateRaw(dspec, sprintf('Phase%d', ph_bin), sprintf('Phase%d', ph_bin), bs);
    end
end

% TFbl, ch
bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(1000/binSize), round(1000/binSize), binfun);
offset = round(-250 / binSize);
if ops.splitELtf & ~ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_e', 'Baseline TFs early',  bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_l', 'Baseline TFs late',  bs, offset);
elseif ~ops.splitELtf & ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_f', 'Baseline TFs fast',  bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_s', 'Baseline TFs slow',  bs, offset);
elseif ops.splitELtf & ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_fe', 'Baseline TFs fast',  bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_se', 'Baseline TFs slow',  bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_fl', 'Baseline TFs fast',  bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_sl', 'Baseline TFs slow',  bs, offset);
elseif ~ops.splitELtf && ~ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFbl', 'Baseline TFs',  bs, offset);
end

if ops.splitFStf
    dspec = buildGLM.addCovariateRaw(dspec, 'TFch_f', 'Change TFs fast',  bs, offset);
    dspec = buildGLM.addCovariateRaw(dspec, 'TFch_s', 'Change TFs slow',  bs, offset);
else
    dspec = buildGLM.addCovariateRaw(dspec, 'TFch', 'Change TFs',  bs, offset);
end

% TF abs
% if ops.includeAbsoluteTF
%     dspec = buildGLM.addCovariateRaw(dspec, 'TFbl_abs', 'Absolute baseline TFs',  bs, offset);
% end

% TF x time interation
% if ops.includeTimeTFInteration
% %     dspec = buildGLM.addCovariateRaw(dspec, 'TFblxDir', 'TF x Dir',  bs);
%     dspec = buildGLM.addCovariateRaw(dspec, 'TFblXtime', 'TFxtime',  bs, offset);
% end
% 
% if ops.includeDirection
%     dspec = buildGLM.addCovariateRaw(dspec, 'TFblXDir', 'TFxDir',  bs, offset);
% end

if ops.includeMotionEnergy
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(500/binSize), round(500/binSize), binfun);
    offset = round(-100 / binSize);
%     bs = basisFactory.makeSmoothTemporalBasis('boxcar', 1, 1, binfun);
    offset = 0;
    dspec = buildGLM.addCovariateRaw(dspec, 'motionEnergy', 'Motion energy',  bs, offset);
end

if ops.includeRunSpeed
    bs = basisFactory.makeSmoothTemporalBasis('boxcar', round(50/binSize), round(50/binSize), binfun);
    offset = round(0 / binSize);
    dspec = buildGLM.addCovariateRaw(dspec, 'runSpeed', 'Running',  bs, offset);
end

    
% time
% dspec = buildGLM.addCovariateRaw(dspec, 'time', 'Time in trial');

% dm = buildGLM.compileSparseDesignMatrix(dspec, 1:length(features));


end