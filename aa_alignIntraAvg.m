%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
% and transfer all the alignment to a new table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filamentListFile = 'filamentList.csv';
alnDir = 'intraAln';
outputDir = 'alnTable';
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
boxSize = 96;
initRefFile = 'dmt_init_avg_b96.em';


filamentList = readcell(filamentListFile);
noFilament = length(filamentList);
template = dread(initRefFile);

cd(alnDir)
mkdir(outputDir)

% Need to apply transformation into original table
for idx = 1:noFilament
  aPath = ddb([filamentList{idx} ':a']); % Read the path of the alignment project average
  tPath = ddb([filamentList{idx} ':rt']);
  filamentAvg = dread(aPath);
  sal = dalign(dynamo_bandpass(template,[1 23]), dynamo_bandpass(filamentAvg,[1 23]),'cr',14,'cs',2,'ir',360,'is',2,'dim',96, 'limm',1,'lim',[20,20,20],'rf',5,'rff',2); % cone_flip
  %sal = dalign(dynamo_bandpass(template,[1 23]), dynamo_bandpass(filamentAvg,[1 23]),'cr',14,'cs',2,'ir',360,'is',2,'dim',96, 'limm',1,'lim',[20,20,20],'rf',5,'rff',2, 'cone_flip', 1); % cone_flip
  dview(sal.aligned_particle);
  % Read last table from alignment
  tFilament = dread(tPath);
  % Read last transformation & applied to table
  tFilament_ali = dynamo_table_rigid(tFilament, sal.Tp);
  % Write table
  dwrite(tFilament_ali, [outputDir '/' filamentList{idx} '.tbl'])
 end
 
 cd ..
