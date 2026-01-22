function ops = set_glm_ops()


ops.rmvStart         = 1;            % remove first n trials from each session
ops.performanceBin   = 30;           % calculate running hit/miss/fa etc rates from this many trials
ops.missThresh       = .6;            % remove periods where miss rate higher than this
ops.falseAlarmThresh = .9;            % remove periods where false alarm rate higher than this
ops.abortThresh      = 1;            % remove periods where abort rate higher than this
ops.combinedAbortFA  = 1;            % remove periods where combined false alarm/abort rate higher than this

ops.minFR     = .25; % Hz; minimum average firing rate
ops.minFRDrop = 0; % minimum that firing rate can drop to, as proportion of overall mean
ops.suOnly    = 1;  % logical; whether to use only neurons identified as single units (1) or include MUA (0)

ops.minTrialDur  = 2;
ops.tBin         = .01; % seconds; time to discretize GLM
ops.longBLStart  = 2;     % time to start long baseline regressor
ops.includeTrialOutcome = 1;
ops.includeDirection    = 0;
ops.includePhase        = 0;
ops.phaseSplit          = 30; % size of each phase bin 
ops.splitELtf           = 0;
ops.splitELlick         = 0;
ops.splitFStf           = 1;
ops.includeMotionEnergy = 1;
ops.includeRunSpeed     = 0;
ops.kFold               = 10;
ops.nLambdas            = 100;
ops.lambdas             = 0;%[0, logspace(-10, 0, 11)];
ops.maxTrials           = 1500;
ops.alpha               = 1e-6; % 0 is ridge; 1 is lasso
ops.tol                 = .05;
ops.maxFR               = 250; % max firing rate, in hz
ops.maxIter             = 1000;

ops.rndSeed = 10;

end
