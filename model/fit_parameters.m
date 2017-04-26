function fit_parameters(testmodel,subjnum,nStartVals,truemodel,expnumber)
if nargin < 3; nStartVals = 1; end
if nargin < 4; truemodel = testmodel; end % for model recovery
if nargin < 5; expnumber = 2; end

%
%
% ================= INPUT VARIABLES ==================
% MODEL: 1 (optimal priority placement) or 2 (not optimal)
% SUBJNUM: subject number. 1 - 11
% NSTARTVALS: optimization starting vals
% TESTMODEL: 1 (optimal priority placement) or 2 (not optimal). this is
% used only for model recovery.
% EXPNUMBER: 1 (experiment with just priority manipulation) or 2
% (experiment with disc size response also). 
% 
% -----------------------
%      Aspen H. Yoo
%   aspen.yoo@nyu.edu
%     April 10, 2017

% filepath = ['fits/exp' num2str(expnumber) '/'];
filepath = ['/home/ay963/spatialWM/fits/exp' num2str(expnumber) '/'];
if (expnumber == 1) % if nodiscsize experiment (first experiment)
    suffix = '_nodisc';
else
    suffix = [];
end

if (expnumber == 1)
    nSubj = 14;
else
    nSubj = 11;
end

if (subjnum <= nSubj)
    load(['cleandata' suffix '.mat'])
    subjdata = data{subjnum};
    filename = [filepath 'fits_model' num2str(testmodel) '_subj' num2str(subjnum) '.mat'];
else
    load([filepath 'simdata_model' num2str(truemodel) '.mat'],'simdata')
    subjdata = simdata{subjnum - nSubj};
    if strcmp(truemodel,testmodel); % if same model
    filename = [filepath 'paramrecov_model' num2str(testmodel) '_subj' num2str(subjnum-nSubj) '.mat'];
    else
        filename = [filepath 'modelrecov_truemodel' num2str(truemodel) '_testmodel' num2str(testmodel) '_subj' num2str(subjnum-nSubj) '.mat'];
    end
end


rng(0);
% rng(str2double([num2str(model) num2str(subjnum)]));

lb = [1e-5 1e-3]; % Jbar_total, tau
ub = [50 10];
plb = [0.5 0.01];
pub = [20 5];
logflag = [1 1];
if expnumber == 2 % alpha beta
    lb = [lb 1e-5 1e-5];
    ub = [ub 10 5];
    plb = [plb 0.5 0.5];
    pub = [pub 2 1.5];
    logflag = [logflag 0 0];
end
if testmodel == 2 % p_high p_med
    lb = [lb 0 0];
    ub = [ub 1 1];
    plb = [plb 0.3 0];
    pub = [pub 0.7 0.3];
    logflag = [logflag 0 0];
end
logflag = logical(logflag);
nParams = length(logflag);
lb(logflag) = log(lb(logflag));
ub(logflag) = log(ub(logflag));
plb(logflag) = log(plb(logflag));
pub(logflag) = log(pub(logflag));

for istartvals = 1:nStartVals
    try load(filename); catch; ML_parameters = []; nLLVec = []; end
%     load(['simdata_model' num2str(model) '.mat'],'simtheta')
%     x0 = simtheta(subjnum-11,:);
%     x0(1:2) = log(x0(1:2));
    x0 = plb + rand(1,nParams).*(pub - plb);
    fun = @(x) calc_nLL(testmodel,x,subjdata);
    [x,fval] = bps(fun,x0,lb,ub,plb,pub);

    x(logflag) = exp(x(logflag));
    ML_parameters = [ML_parameters; x];
    nLLVec = [nLLVec fval];
    save(filename,'ML_parameters','nLLVec')
end

