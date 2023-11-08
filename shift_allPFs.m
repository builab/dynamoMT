%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to shift all PF 4 nm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet_pf/';

%% Input
pixelSize = 8.48;
boxSize = 40;
pfDir = sprintf('%spf', prjPath);
mw = 12; % Number of parallel workers to run
shiftAngst = 41; % Angstrom
noPF = 4;


%%%%%%%%%%%%%%%%% Not needed
particleDir = sprintf('%sparticles_repick', prjPath);
pf_template_name = {[particleDir '/pf1.em'], [particleDir '/pf2.em'], [particleDir '/pf3.em'], [particleDir '/pf4.em']};
tableFilePF = {'pf/merged_particles_pf1.tbl', 'pf/merged_particles_pf2.tbl', 'pf/merged_particles_pf3.tbl', 'pf/merged_particles_pf4.tbl'}; % merged particles table all
tableOutFilePF = {'pf/merged_particles_pf1_aln.tbl', 'pf/merged_particles_pf2_aln.tbl', 'pf/merged_particles_pf3_aln.tbl', 'pf/merged_particles_pf4_aln.tbl'}; % merged particles table all
starFilePF = {'pf/merged_particles_pf1.star', 'pf/merged_particles_pf2.star', 'pf/merged_particles_pf3.star', 'pf/merged_particles_pf4.star'}; % star file name for merged particles
pAlnPF = {'pPf1', 'pPf2', 'pPf3', 'pPf4'};
%%%%%%%%%%%%%%%%%


Tp.type = 'shiftrot';
Tp.shifts = [0 0 shiftAngst/pixelSize];
Tp.eulers = [0 0 0];
    

for pf = 1:noPF
	tPF = dread([pfDir '/merged_particles_pf' num2str(pf) '.tbl']);
	tPF_shift = dynamo_table_rigid(tPF, Tp);
	dwrite(tPF_shift, [pfDir '/merged_particles_pfb' num2str(pf) '.tbl']);
	copyfile([pfDir '/merged_particles_pf' num2str(pf) '.star'], [pfDir '/merged_particles_pfb' num2str(pf) '.star']);
	oa_all = daverage([pfDir '/merged_particles_pf' num2str(pf) '.star'], 't', tPF_shift, 'fc', 0, 'mw', mw);
    dwrite(oa_all.average, [pfDir '/pfb' num2str(pf) '.em']);
    %dynamo_table2chimeramarker([targetFolder '/crop.cmm'], [targetFolder '/crop.tbl'], 2);
end
