%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align repick particles
% and transform all the alignment to an updated table.
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /STORAGE/kabui/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/STORAGE/kabui/human/mt/';

%% Input
boxSize = 64;
pixelSize = 4.892;
filamentRepickListFile = 'filamentRepickList.csv';
particleDir = sprintf('%sparticles_repick', prjPath);
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
template_name = 'pf.em';
tableFileName = 'merged_particles_repick.tbl'; % merged particles table all
starFileName = 'merged_particles_repick.star'; % star file name for merged particles
tableOutFileName = 'merged_particles_repick_align.tbl'; % merged particles table all
pAlnAll = 'pAlnRepickParticles';
refMask = 'pf_mask.em';
finalLowpass = 10; % Now implemented using in Angstrom
alnLowpassR1 = 35; % Now implemented using Angstrom
alnLowpassR2 = 25; % Now implemented using Angstrom
alnLowpassR3 = 20;
zshift_limit = 10; % Should be half the periodicity, 4-nm for tip CP, 8-nm for doublet

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
	tableName{idx} = [particleDir '/' filamentList{idx} '/crop.tbl'];
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
dvput(pAlnAll,'ite', [2 2 2]);
dvput(pAlnAll,'dim', [boxSize boxSize boxSize]);
dvput(pAlnAll,'low', [round(pixelSize/alnLowpassR1*boxSize) round(pixelSize/alnLowpassR2*boxSize) round(pixelSize/alnLowpassR3*boxSize)]);
dvput(pAlnAll,'cr', [9 3 3]);
dvput(pAlnAll,'cs', [3 1 1]);
dvput(pAlnAll,'ir', [9 3 3]);
dvput(pAlnAll,'is', [3 1 1]);
dvput(pAlnAll,'rf', [5 2 2]);
dvput(pAlnAll,'rff', [2 2 2]);
dvput(pAlnAll,'lim', [zshift_limit zshift_limit/2 zshift_limit/2]);
dvput(pAlnAll,'limm',[1 2 2]);
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
dwrite(dynamo_bandpass(a,[1 round(pixelSize/finalLowpass*boxSize)])*(-1),['result_alnRepickParticles_filt' num2str(finalLowpass) '_INVERTED_all.em']);

