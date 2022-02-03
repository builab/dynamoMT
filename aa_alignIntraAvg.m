%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
% and transfer all the alignment to a new table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filamentListFile = 'filamentList.csv';
alnDir = 'intraAln';
particleDir = 'particles';
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
folderAllaverages = 'avg_aln'; % Output alignment folder
pr_a = 'pr_avg_aln'; % Project name
boxSize = 96;
templateFile = 'dmt_init_avg_b96.em';


filamentList = readcell(filamentListFile);
noFilament = length(filamentList);


template = dread(templateFile);

% Need to apply transformation into original table
for idx = 1:noFilament
  aPath = ddb([filamentList{idx} ':a']);
  filamentAvg = dread(aPath);
  sal = dalign(dynamo_bandpass(template,[1 23]), ...
  dynamo_bandpass(filamentAvg,[1 23]),'cr',1,'cs',1,'ir',1,'is',1,'dim',96, 'limm',1,'lim',[1,1,20],'rf',5,'rff',2); % cone_flip
  dview(sal.aligned_particle);
  % Read last table from alignment
  t_ccFilt_Ex = dread(['t_ccFilt_Ex_' stackName{idx} '.tbl']);
  % Read last transformation & applied to table
  t_ccFilt_Ex_Ali = dynamo_table_rigid(t_ccFilt_Ex,sal.Tp);
  % Write table
 end
