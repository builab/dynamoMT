%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align intra average of each doublet with a reference
% and transform all the alignment to an updated table.
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage2/Thibault/20240905_SPEF1MTs/MTavg/';

%%%%%%% Variables subject to change %%%%%%%%%%%
pixelSize = 8.48;
boxSize = 80;
filamentListFile = 'filamentPFList14PF.csv';
alnDir = sprintf('%sintraAln', prjPath);
particleDir = sprintf('%sparticles_twist', prjPath);
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
template_name = 'ref_MT14PF_SPEF1_new.em'; % If you have a better reference, use it instead
tableFileName = 'merged_particles_twist_14PF.tbl'; % merged particles table all
tableOutFileName = 'merged_particles_twist_14PF_align.tbl'; % merged particles table all
starFileName = 'merged_particles_twist_14PF.star'; % star file name for merged particles
pAlnAll = 'pAlnAllParticlesTwist14PF';
refMask = 'mask_MT14PF.em';
finalLowpass = 25; % Now implemented using in Angstrom
alnLowpass = 30; % Now implemented using Angstrom
zshift_limit = 6; % 8nm shift limit
outputFile = 'average_twist_14PF.em';


%%%%%%% Do not change anything under here %%%%%
filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);


template = dread(template_name);
 
% Combine all the particles into one table
% create table array
targetFolder = {};
tableName ={};

for idx = 1:noFilament
	targetFolder{idx} = [particleDir '/' filamentList{idx}];
	tableName{idx} = [particleDir '/' filamentList{idx} '/aligned.tbl'];
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
dvput(pAlnAll,'ite', [1 1]);
dvput(pAlnAll,'dim', [boxSize boxSize]); % Integer division of box size
dvput(pAlnAll,'low', [round(boxSize*pixelSize/alnLowpass) round(boxSize*pixelSize/alnLowpass)]); % Low pass filter
dvput(pAlnAll,'cr', [15 6]);
dvput(pAlnAll,'cs', [5 2]);
dvput(pAlnAll,'ir', [15 6]);
dvput(pAlnAll,'is', [5 2]);
dvput(pAlnAll,'rf', [5 5]);
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
tPath = ddb([pAlnAll ':t:ite=last']); % This is correct but might not be prone to more error!!!
dwrite(dread(tPath), tableOutFileName);
dwrite(dynamo_bandpass(a,[1 round(boxSize*pixelSize/finalLowpass)]), outputFile);
