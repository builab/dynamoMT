%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate different MT assembly
% Need to have an option to align or not
% Now option for alignment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet_pf/';

%% Input
pixelSize = 8.48;
boxSize = 40;
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu
pfaAvgFile = {'pfa1_avg.em', 'pfa2_avg.em', 'pfa3_avg.em', 'pfa4_avg.em'};
pfbAvgFile = {'pfb1_avg.em', 'pfb2_avg.em', 'pfb3_avg.em', 'pfb4_avg.em'};
pfAvgFile = {'pfa1_avg.em', 'pfa2_avg.em', 'pfa3_avg.em', 'pfa4_avg.em', 'pfb1_avg.em', 'pfb2_avg.em', 'pfb3_avg.em', 'pfb4_avg.em'};
refMask = 'masks/mask_pf.em';
finalLowpass = 30; % Now implemented using in Angstrom
alnLowpass1 = 30; % Now implemented using Angstrom
alnLowpass2 = 20; % Now implemented using Angstrom
zshift_limit = 3; % 8nm shift limit
noPF = 4;
mw = 12; % Number of parallel workers to run
gpu = [0:5]; % Alignment using gpu

% For a (1 = yes, 0 = no)
assembleMTa = [1 1 1 1; 1 0 0 0; 1 1 0 0; 1 1 1 0];

% Now do the same for b
assembleMTb = 1 - assembleMTa;

% Assemble the weight
assembleMT = [assembleMTa assembleMTb];
assembleMT_rev = 1 - assembleMT;

assembleMT = [assembleMT; assembleMT_rev] 

for i = 1:length(pfAvgFile)
	pfavg{i} = dread(pfAvgFile{i});
end

%%
for i = 1:size(assembleMT, 1)
	disp(['Generate average for assemble ' num2str(i)])
	avg = zeros(boxSize, boxSize, boxSize);
	% Combine all the average into one table
	for j = 1 : size(assembleMT, 2)
		disp(['Adding the pfAvg ' num2str(j) ' using weight ' num2str(assembleMT(i, j))])
		avg = avg + pfavg{j}*assembleMT(i, j);
	end
	disp(['Writing the MT assemble ' num2str(i)])
	dwrite(avg, ['MTassemble_' num2str(i) '.em']);
end
