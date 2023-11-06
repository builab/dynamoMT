%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to combine PF table
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% TODO Perhaps using dynamo_subboxing_table is a bit more elegant, then incorporate the rotation
% TODO Use filamentList instead of tomo

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet_pf/';

%% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
noPF = 4; % Number of PF
filamentRepickListFile = sprintf('%sfilamentRepickList.csv', prjPath);



filamentList = readcell(filamentRepickListFile, 'Delimiter', ',');
noFilament = length(filamentList);

for pf = 1:noPF
	% Combine all the particles in one pf  into one table
	starFileName = ['merged_particles_pf' num2str(pf) '.star'];
	tableFileName = ['merged_particles_pf' num2str(pf) '.tbl'];
	targetFolder = {};
	tableName ={};

	for idx = 1:noFilament
		targetFolder{idx} = [particleDir '/' filamentList{idx} '_pf' num2str(pf)];
		tableName{idx} = [particleDir '/' filamentList{idx} '_pf' num2str(pf) '/crop.tbl'];
	end


	% create ParticleListFile object (this object only exists temporarily in matlab)
	plfClean = dpkdata.containers.ParticleListFile.mergeDataFolders(targetFolder,'tables',tableName);

	% create and write the .star file
	plfClean.writeFile(starFileName);

	% create merged table
	tMergedClean = plfClean.metadata.table.getClassicalTable();
	dwrite(tMergedClean,tableFileName)
	disp(['Writing ' tableFileName])
end

