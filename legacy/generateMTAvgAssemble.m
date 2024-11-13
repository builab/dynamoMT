%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to generate different MT assembly
% Need to have an option to align or not
% Maybe masking?
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
pfAvgFile = {'pfa1_avg.em', 'pfa2_avg.em', 'pfa3_avg.em', 'pfa4_avg.em', 'pfb1_avg.em', 'pfb2_avg.em', 'pfb3_avg.em', 'pfb4_avg.em'};
refMask = 'masks/mask_pf.em';
finalLowpass = 30; % Now implemented using in Angstrom
shiftLimit = 2; % 8nm shift limit

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

template = pfavg{1};
%%
for i = 1:size(assembleMT, 1)
	disp(['Generate average for assemble ' num2str(i)])
	avg = zeros(boxSize, boxSize, boxSize);
	% Combine all the average into one table
	for j = 1 : size(assembleMT, 2)
		if assembleMT(i, j) > 0
			sal = dalign(pfavg{j}, template,'cr',3,'cs',1,'ir',3,'is',1,'dim',boxSize,'limm',1,'lim',shiftLimit,'rf',5,'rff',2); % no cone_flip
			disp(['Adding the pfAvg ' num2str(j)])
			avg = avg + sal.aligned_particle;
		end
	end
	disp(['Writing the MT assemble ' num2str(i)])
	dwrite(avg, ['MTassemble_' num2str(i) '.em']);
end
