%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filamentListFile = 'filamentList.csv';
alnDir = 'intraAln';
particleDir = 'particles';
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
folderAllaverages = 'avg_aln'; % Output alignment folder
pr_a = folderAllaverages; % Project name
boxSize = 96;
template = 'dmt_init_avg_b96.em';


filamentList = readcell(filamentListFile);

cd(alnDir)
mkdir(folderAllaverages)

noFilament = length(filamentList)
% Copy intra average into particles number
for idx = 1:noFilament
  aPath = ddb([filamentList{idx} ':a']);
  copyfile(aPath{1}, [folderAllaverages '/particle_' num2str(tomoID(idx),'%06.f') '.em';])
end

% Copy template to alignment folder
copyfile(['../' template], [folderAllaverages '/template.em'])


% create corresponding table and save it in new particle folder
ta = dynamo_table_blank(noFilament);
ta(:,13) = 0; % no missing wedge compensation needed for now
% To customize missing wedge, bettter specified a custom wedge, using this guideline
% https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Indicating_the_missing_wedge

ta(:,20) = ta(:,1); % set particle tag number = filament number
ta(:,24:26) = (ceiling(boxSize/2) + 1)*ones(nFilament,3); % set centers, depending on box size
dwrite(ta,[folderAllaverages '/crop.tbl'])


% create the alignment project of averages to align all intra dmt particles (averages)
dcp.new(pr_a,'d',folderAllaverages,'t',[folderAllaverages '/crop.tbl'], ...
'template',[folderAllaverages '/template.em'],'masks','default','show',0);

% set alignment parameters for 2 rounds
dvput(pr_a,'ite', [3 3]);
dvput(pr_a,'dim', [48 96]); % Half & then full size
dvput(pr_a,'low', [23 23]);
dvput(pr_a,'cr', [15 6]); % If no polarity [180 30], with polarity defined [15 6]
dvput(pr_a,'cs', [5 2]);
dvput(pr_a,'ir', [360 30]);
dvput(pr_a,'is', [10 5]);
dvput(pr_a,'rf', [5 5]);
dvput(pr_a,'rff', [2 2]);
dvput(pr_a,'lim', [80 20]); % Angstrom or pixel? Probably Angstrom
dvput(pr_a,'limm',[1 2]);
dvput(pr_a,'sym', 'c1');

% set computational parameters
dvput(pr_a,'dst','matlab_gpu','cores',2,'mwa',mw);
dvput(pr_a,'gpus',gpu);

% check/unfold/run
dvrun(pr_a,'check',true,'unfold',true);

% prepare resulting average for chimera
aPath = ddb([pr_a ':a']);
a = dread(aPath);
dwrite(dynamo_bandpass(a,[1 23])*(-1),['result_' pr_a '_INVERTED.em']);
