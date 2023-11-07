%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to align all PF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet_pf/';

%% Input
pixelSize = 8.48;
boxSize = 40;
particleDir = sprintf('%sparticles_repick', prjPath);
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu
pf_template_name = {[particleDir '/pf1.em'], [particleDir '/pf2.em'], [particleDir '/pf3.em'], [particleDir '/pf4.em']};
tableFilePF = {'pf/merged_particles_pf1.tbl', 'pf/merged_particles_pf2.tbl', 'pf/merged_particles_pf3.tbl', 'pf/merged_particles_pf4.tbl'}; % merged particles table all
tableOutFilePF = {'pf/merged_particles_pf1_aln.tbl', 'pf/merged_particles_pf2_aln.tbl', 'pf/merged_particles_pf3_aln.tbl', 'pf/merged_particles_pf4_aln.tbl'}; % merged particles table all
starFilePF = {'pf/merged_particles_pf1.star', 'pf/merged_particles_pf2.star', 'pf/merged_particles_pf3.star', 'pf/merged_particles_pf4.star'}; % star file name for merged particles
pAlnPF = {'pPf1', 'pPf2', 'pPf3', 'pPf4'};
refMask = 'masks/mask_pf.em';
finalLowpass = 30; % Now implemented using in Angstrom
alnLowpass1 = 30; % Now implemented using Angstrom
alnLowpass2 = 20; % Now implemented using Angstrom
zshift_limit = 3; % 8nm shift limit
filamentListFile = 'filamentRepickList.csv';
noPF = 4;
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu

%%
filamentList = readcell(filamentListFile, 'Delimiter', ',');
noFilament = length(filamentList);

for pf = 1:noPF
	% Combine all the particles into one table
	% create table array
	targetFolder = {};

	for idx = 1:noFilament
		targetFolder{idx} = [particleDir '/' filamentList{idx} '_pf' num2str(pf)];
	end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform alignment of all particles with the ref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Weird setup but necessary to have 'd', targetFolder{1}
	dcp.new(pAlnPF{pf},'t', tableFilePF{pf}, 'd', targetFolder{1}, 'template', pf_template_name{pf}, 'masks','default','show',0, 'forceOverwrite',1);
	dvput(pAlnPF{pf},'data',starFilePF{pf})
	dvput(pAlnPF{pf},'file_mask',refMask)

	% set alignment parameters
	dvput(pAlnPF{pf},'ite', [2 2]);
	dvput(pAlnPF{pf},'dim', [boxSize boxSize]); % Integer division of box size
	dvput(pAlnPF{pf},'low', [round(boxSize*pixelSize/alnLowpass1) round(boxSize*pixelSize/alnLowpass2)]); % Low pass filter
	dvput(pAlnPF{pf},'cr', [6 3]);
	dvput(pAlnPF{pf},'cs', [2 1]);
	dvput(pAlnPF{pf},'ir', [6 3]);
	dvput(pAlnPF{pf},'is', [2 1]);
	dvput(pAlnPF{pf},'rf', [5 5]);
	dvput(pAlnPF{pf},'rff', [2 2]);
	dvput(pAlnPF{pf},'lim', [zshift_limit zshift_limit]);
	dvput(pAlnPF{pf},'limm',[1 2]);
	dvput(pAlnPF{pf},'sym', 'c1'); % 
	
	% set computational parameters
	dvput(pAlnPF{pf},'dst','matlab_gpu','cores',1,'mwa',mw);
	dvput(pAlnPF{pf},'gpus',gpu);
	%dvput(pAlnPF{pf},'dst', 'matlab','cores',1);

	% check/unfold/run
	dvrun(pAlnPF{pf},'check',true,'unfold',true);

	aPath = ddb([pAlnPF{pf} ':a']);
	a = dread(aPath);
	tPath = ddb([pAlnPF{pf} ':t:ite=last']); % This is correct but might not be prone to more error!!!
	dwrite(dread(tPath), tableOutFilePF{pf});
	dwrite(a*(-1),['result_PF' num2str(pf) '_INVERTED_all.em']);
end
