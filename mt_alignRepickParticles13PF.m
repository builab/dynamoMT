%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align repick particles
% and transform all the alignment to an updated table.
% Same for 14 and 13 PF, just different list and ref
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';

%% Input
boxSize = 80;
pixelSize = 8.48;
filamentRepickListFile = 'filamentRepickList13PF.csv';
particleDir = sprintf('%sparticles_repick', prjPath);
mw = 6; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu
template_name = 'templates/hSPEF1_13PFMT_25A.em';
tableFileName = 'merged_particles_repick_13PF.tbl'; % merged particles table all
starFileName = 'merged_particles_repick_13PF.star'; % star file name for merged particles
tableOutFileName = 'merged_particles_repick_13PF_align.tbl'; % merged particles table all
pAlnAll = 'pAlnRepickParticles13PF';
refMask = 'mask_MT13PF.em';
finalLowpass = 25; % Now implemented using in Angstrom
alnLowpass = 25; % Now implemented using Angstrom
zshift_limit = 5; % Should be half the periodicity, 4-nm for tip CP, 8-nm for doublet
newRefFile = 'average_allRepickParticles_13PF.em';

%%
filamentList = readcell(filamentRepickListFile, 'Delimiter', ',');
noFilament = length(filamentList);


template = dread(template_name);
 
% Combine all the particles into one table
% create table array
targetFolder = {};
tableName ={};

for idx = 1:noFilament
	targetFolder{idx} = [particleDir '/' filamentList{idx}];
	tableName{idx} = [particleDir '/' filamentList{idx} '/aligned_manual.tbl'];
end


% create ParticleListFile object (this object only exists temporarily in matlab)
plfClean = dpkdata.containers.ParticleListFile.mergeDataFolders(targetFolder,'tables',tableName);

% create and write the .star file
plfClean.writeFile(starFileName)

% create merged table
tMergedClean = plfClean.metadata.table.getClassicalTable();
dwrite(tMergedClean,tableFileName)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform alignment of all particles with the ref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


dcp.new(pAlnAll,'t', tableFileName, 'd', targetFolder{1}, 'template', template_name, 'masks','default','show',0, 'forceOverwrite',1);
dvput(pAlnAll,'data',starFileName)
dvput(pAlnAll,'file_mask',refMask)

% set alignment parameters
dvput(pAlnAll,'ite', [2 1]);
dvput(pAlnAll,'dim', [boxSize boxSize]);
dvput(pAlnAll,'low', [round(pixelSize/alnLowpass*boxSize) round(pixelSize/alnLowpass*boxSize)]);
dvput(pAlnAll,'cr', [15 6]);
dvput(pAlnAll,'cs', [5 2]);
dvput(pAlnAll,'ir', [15 6]);
dvput(pAlnAll,'is', [5 2]);
dvput(pAlnAll,'rf', [2 2]);
dvput(pAlnAll,'rff', [2 2]);
dvput(pAlnAll,'lim', [zshift_limit zshift_limit]);
dvput(pAlnAll,'limm',[1 2]);
dvput(pAlnAll,'sym', 'c1'); % 
    
% set computational parameters
dvput(pAlnAll,'dst','matlab_gpu','cores',1,'mwa',mw);
dvput(pAlnAll,'gpus',gpu);

% check/unfold/run
dvrun(pAlnAll,'check',true,'unfold',true);

aPath = ddb([pAlnAll ':a']);
a = dread(aPath);
tPath = ddb([pAlnAll ':t:ite=last']); % This makes convertion to Relion better
dwrite(dread(tPath), tableOutFileName);
dwrite(dynamo_bandpass(a,[1 round(pixelSize/finalLowpass*boxSize)]),newRefFile);
