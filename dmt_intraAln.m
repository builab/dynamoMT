% Script for alignment within the same doublet
% Translation only?

% Input
docFilePath = 'catalogs/tomograms.doc';
filamentListFile = 'filamentList.csv';
modelDir = 'models';
alnDir = 'intraAlign';
particleDir = 'particles';
boxSize = 96; % Extracted subvolume size
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu


% Generate an initial reference average for each filament
filamentList = readcell(filamentListFile);
for idx = 1:length(filamentList)
    tableName = [particleDir '/' filamentList{idx} '/crop.tbl'];
    tOri = dread(tableName);
    template = [particleDir '/' filamentList{idx} '/template.me'];
    prjDir = [alnDir '/' filamentList{idx} '_intra'];
    

    % create alignment project
    dcp.new(prjDir,'d',prjDir,'t',tableName, 'template', template, 'masks','default','show',0);

    % set alignment parameters for 2 rounds
    dvput(pr_0,'ite', [2]); % n iterations
    dvput(pr_0,'dim', [96]); % subvolume sidelength (binning)
    dvput(pr_0,'low', [23]); % lowpass filtere
    dvput(pr_0,'cr', [15]); % cone range
    dvput(pr_0,'cs', [5]); % cone search step
    dvput(pr_0,'ir', [15]); % inplane rotation
    dvput(pr_0,'is', [5]); % inplane search step
    dvput(pr_0,'rf', [5]); % refinement
    dvput(pr_0,'rff', [2]); % refinement factor
    dvput(pr_0,'lim', [10]); % shift limit
    dvput(pr_0,'limm',[1]); % limit mode
    dvput(pr_0,'sym', 'c1'); % symmetry

    % set computational parameters
    dvput(pr_0,'dst','matlab_gpu','cores',1,'mwa',mw);
    dvput(pr_0,'gpus',gpu);

    % check/unfold/run
    dvrun(pr_0,'check',true,'unfold',true);

end
