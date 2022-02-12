%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to combine all the filament tables together and align with a common ref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filamentListFile = 'filamentList.csv';
alnDir = 'intraAln';
particleDir = 'particles';
mw = 12; % Number of parallel workers to run
gpu = [0:1]; % Alignment using gpu
boxSize = 96;
template_name = 'updated_avg_b96.em';
tableFileName = 'merged_particles.tbl'; % merged particles table all
starFileName = 'merged_particles.star'; % star file name for merged particles
pAlnAll = 'pAlnAllParticles'



filamentList = readcell(filamentListFile);
noFilament = length(filamentList);


template = dread(refFile);
 
% Combine all the particles into one table
% create table array

for idx = 1:noFilament
	targetFolder = [particleDir '/' filamentList{idx}];
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

cd(alnDir)

% Might use mask later
dcp.new(pAlnAll,'t', tableFileName, 'd', targetFolder{1}, 'template', template_name, 'masks','default','show',0, 'forceOverwrite',1);
dvput(pAlnAll,'data',starFileName)

% set alignment parameters
dvput(pAlnAll,'ite', [1 1]);
dvput(pAlnAll,'dim', [96 96]);
dvput(pAlnAll,'low', [23 23]);
dvput(pAlnAll,'cr', [15 6]);
dvput(pAlnAll,'cs', [5 2]);
dvput(pAlnAll,'ir', [15 6]);
dvput(pAlnAll,'is', [5 2]);
dvput(pAlnAll,'rf', [5 5]);
dvput(pAlnAll,'rff', [2 2]);
dvput(pAlnAll,'lim', [10 10]);
dvput(pAlnAll,'limm',[1 2]);
dvput(pAlnAll,'sym', 'c1'); % 
    
% set computational parameters
dvput(pAlnAll,'dst','matlab_gpu','cores',1,'mwa',mw);
dvput(pAlnAll,'gpus',gpu);

% check/unfold/run
dvrun(pAlnAll,'check',true,'unfold',true);

aPath = ddb([pAlnAll ':a']);
a = dread(aPath);
dwrite(dynamo_bandpass(a,[1 23])*(-1),['result_' pr_0 '_INVERTED.em']);

cd ..