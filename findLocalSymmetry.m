%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to find local symmetry
% Work quite well
% Open the ref file, determine roughly coordinate of the subunit in Imod and put in subbox_orig
% Pick one as ref_subbox (preferrable without rotation)
% Figure out rotation angle for all subunits (particle rotation) to match with the ref_unit, update subbox_p_rots
% Run and then use the final subbox_orig_update or subbox_p_rots_update for the filamentRepickMT 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet_pf/';

%% Input
referenceFile = 'ref_doublet_16nm.em';
pixelSize = 8.48; % Angstrom per pixel
pf_shift = 9.26/pixelSize; % Angstrom
subbox_dir = sprintf('%ssubparticles', prjPath);
alnLowpass = 30; % Angstrom
shift_limit = 5; % You can tune this after seeing the result
prj_subbox = 'alnSubbox';
ref_subbox_orig = [73 51 48];
ref_subbox_file = 'ref_crop.em'
ref_unit_rot = [0 0 0];
subbox_size = 40
subbox_mask = 'mask_crop.em'; % Might be better using mask
alnLowpassPix = round(pixelSize/alnLowpass*subbox_size);

% In this case, in corporarte pf_shift, perhaps no need
subbox_orig = [67 61 48-2*pf_shift; 71 57 48-1*pf_shift; 73 51 48; 71 43 48+pf_shift];
subbox_orig_update = subbox_orig;

% Particle rot
subbox_p_rots = [0 0 47; 0 0 23; 0 0 0; 0 0 -19]

% table for subbox
t_subbox = zeros(size(subbox_orig, 1), 42);

mkdir(subbox_dir)

% Crop the ref & local unit
template = dread(referenceFile);
template_subbox = dcrop(template, subbox_size, ref_subbox_orig, 0);
dwrite(template_subbox, ref_subbox_file)
% Local unit & construct table
for subid = 1:size(subbox_orig)
	t_subbox(subid, 1) = subid;
	t_subbox(subid, 24:26) = round(subbox_orig(subid, :));
	t_subbox(subid, 4:6) = -round(subbox_orig(subid, :)) + subbox_orig(subid, :);
	t_subbox(subid, 7:9) = -subbox_p_rots(subid, :);
end

t_subbox(:, 2) = 1;
t_subbox(:, 3) = 1;
t_subbox(:, 14) = -90;
t_subbox(:, 15) = 90;
t_subbox(:, 20) = 1;
dwrite(t_subbox, [subbox_dir '/subbox.tbl']);
dtcrop(referenceFile, t_subbox, subbox_dir, subbox_size, 'allow_padding', true);


% Alignment
dcp.new(prj_subbox,'d', subbox_dir,'t', [subbox_dir '/crop.tbl'], 'template', ref_subbox_file, 'masks','default','show',0);

% set alignment parameters for 2 rounds
dvput(prj_subbox,'ite', [1]); % no iterations 3 is reasonable
dvput(prj_subbox,'dim', [subbox_size]); 
dvput(prj_subbox,'low', [round(pixelSize/alnLowpass*boxSize)]); % lowpass filter
dvput(prj_subbox,'cr', [0]); % cone range, don't search cone
dvput(prj_subbox,'cs', [5]); % cone search step
dvput(prj_subbox,'ir', [10]); % inplane rotation
dvput(prj_subbox,'is', [1]); % inplane search step
dvput(prj_subbox,'rf', [5]); % refinement
dvput(prj_subbox,'rff', [2]); % refinement factor
dvput(prj_subbox,'lim', [shift_limit]); % shift limit
dvput(prj_subbox,'limm',[1]); % limit mode
dvput(prj_subbox,'sym', 'c1'); % symmetry
% For masking
%dvput(prj_subbox,'file_mask',subbox_mask)

% set computational parameters
%dvput(prj_subbox,'dst','matlab_gpu','cores',1,'mwa',mw);
%dvput(prj_subbox,'gpus',gpu);
%dvput(prj_subbox,'dst','matlab_gpu','cores',1);
    
%CPU
dvput(prj_subbox,'dst', 'matlab','cores',1);

% check/unfold/run
dvrun(prj_subbox,'check',true,'unfold',true);
   
    
% Write out
tPath = ddb([prj_subbox ':t:ite=last']); % Read the path of the table
t_ali = dread(tPath)
dwrite(t_ali, [subbox_dir '/align.tbl']);

subbox_orig_update = t_ali(:, 24:26) + t_ali(:, 4:6)
subbox_p_rots_update = -t_ali(:, 7:9) 




