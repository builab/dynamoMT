% Script for alignment within the same doublet
% Translation only?

% Input
docFilePath = 'catalogs/tomograms.doc';
filamentListFile = 'filamentList.csv';
modelDir = 'models';
alnDir = 'intraAln';
particleDir = 'particles';
boxSize = 96; % Extracted subvolume size
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu


% Generate an initial reference average for each filament
filamentList = readcell(filamentListFile);
for idx = 1:length(filamentList)
    tableName = [particleDir '/' filamentList{idx} '/crop.tbl'];
    tOri = dread(tableName);
    template = [particleDir '/' filamentList{idx} '/template.em'];
    prjDir = [particlesDir '/' filamentList{idx} '_intra'];
    prj_intra = [alnDir '/' filamentList{idx} '_intra'];    

    % create alignment project
    dcp.new(prj_intra,'d',prjDir,'t',tableName, 'template', template, 'masks','default','show',0);

    % set alignment parameters for 2 rounds
    dvput(prj_intra,'ite', [2]); % n iterations
    dvput(prj_intra,'dim', [96]); % subvolume sidelength (binning)
    dvput(prj_intra,'low', [23]); % lowpass filtere
    dvput(prj_intra,'cr', [15]); % cone range
    dvput(prj_intra,'cs', [5]); % cone search step
    dvput(prj_intra,'ir', [15]); % inplane rotation
    dvput(prj_intra,'is', [5]); % inplane search step
    dvput(prj_intra,'rf', [5]); % refinement
    dvput(prj_intra,'rff', [2]); % refinement factor
    dvput(prj_intra,'lim', [10]); % shift limit
    dvput(prj_intra,'limm',[1]); % limit mode
    dvput(prj_intra,'sym', 'c1'); % symmetry

    % set computational parameters
    dvput(pr_intra,'dst','matlab_gpu','cores',1,'mwa',mw);
    dvput(pr_intra,'gpus',gpu);

    % check/unfold/run
    dvrun(pr_intra,'check',true,'unfold',true);

end
