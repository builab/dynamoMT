%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to apply alignment parameters to repick filament with torsion model
% Should have same parameters as imodModel2Filament
% dynamoDMT v0.2b
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Using GUI https://wiki.dynamo.biozentrum.unibas.ch/w/index.php/Filament_model
% Now also printing output
% NOTE: v0.2b add CC filter using median(cc) - 3*mad(cc) 
% NOTE: v0.2b add different contour (Done)
% NOTE: v0.2b eliminate duplicate less than dTh (Done)
% NOTE: v0.2b find nearest neighbour for angle
% 0.2b Now use col 23 as filament number
% merged_particles.tbl intentionally switch the polarity of particles
% Seems to work better running on merged_particles.tbl instead of merged_particles_aln.tbl
% Implement a nearest neighbour for angle assignnment, still doesn't work yet due to Dynamo careless angle interpolation.

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/doublet_pf/';

%% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
modelDir = sprintf('%smodels_repick', prjPath);
origParticleDir = sprintf('%sparticles', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
pixelSize = 8.48; % Angstrom per pixel
subunits_dphi = 0;  %  0
subunits_dz = 168/pixelSize; % in pixel repeating unit dz = 8.4 nm = 168 Angstrom/pixelSize
pf_shift = 9.26/pixelSize; % Angstrom
%pf_rot = 27.69; % Measure with our reference positive end point to lower Z
%radius = 24; % In pixel
boxSize = 128;
mw = 12;
noPF = 1; % Number of PF
filamentRepickListFile = sprintf('%sfilamentRepickList.csv', prjPath);
tableAlnFileName = 'merged_particles_align.tbl'; % merge particles before particle alignment for robust but must be merged_particles_align to use doInitialAngle
avgLowpass = 25; % Angstrom
dTh = 30; % Distance Threshold in Angstrom
doExclude = 1; % Exclude particles too close
doOutlier = 1; % Exclude outlier using CC using MAD
doInitialAngle = 0; % Only turn on for axoneme case now, absolutely not for microtubule
% NOTE: this is misleading. This script read from xform, so it is included

%% loop through all tomograms
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

tAll = dread(tableAlnFileName);

filamentRepickList = {};

% Use this shifts & rots matrix to transform to different PF
shifts = [-18 -12 -2*pf_shift; -22 -8 -1*pf_shift; -23 -2 0; -22 5 pf_shift]
rots = [0 0 47; 0 0 -23; 0 0 0; 0 0 19]

%% Loop through tomograms
for idx = 1:nTomo
    tomo = D{1,2}{idx,1};
    [tomoPath,tomoName,ext] = fileparts(tomo);
    tomono = D{1,1}(idx);
    % Modify specific to name
    tomoName = strrep(tomoName, '_rec', ''); % Remove the rec part of the name
    tTomo = tAll(tAll(:,20) == tomono, :);
    if isempty(tTomo) == 1
        continue;
    end
      
    modelout =   [modelDir '/' tomoName '.omd'];
    contour = unique(tTomo(:, 23));
    
    m = {}; % Cell array contains all filament
    
    for i = 1:length(contour)        
        tContour = tTomo(tTomo(:, 23) == contour(i), :);
        phi = median(tContour(:, 9)); % Same as AA  
    
        % v0.2b Important: this step invert the Y axis, doing for each contour might help to check for polarity
        if doExclude > 0
            tContourEx = dpktbl.exclusionPerVolume(tContour, dTh/pixelSize);
            % Make sure to sort as before by particles number for not inverting angle
            tContour = sortrows(tContourEx, 1);
            display(['Exclude ' num2str(length(tContour) - length(tContourEx)) ' particles due to proximity']);
        end
       
        if doOutlier > 0
            cc = tContour(:, 10);
            x = median(cc);
            y = mad(cc);
            tContour = tContour(cc > x - 3*y, :);
            display(['Contour ' num2str(contour(i)) ': Exclude ' num2str(sum(cc <= x - 3*y)) ' particles']);
        end
        
        if isempty(tContour) == 1
            continue;
        end
        points = tContour(:, 24:26) + tContour(:, 4:6);
        
        % v0.2b Check for polarity in the original crop file
       
        m{i} = dmodels.filamentWithTorsion();
        m{i}.subunits_dphi = subunits_dphi;
        m{i}.subunits_dz = subunits_dz;
        %m{i}.radius = radius;
        
        m{i}.name = [tomoName '_' num2str(contour(i))];
        % Import coordinate
        m{i}.points = points;
        % Create backbone
        m{i}.backboneUpdate();
        % Update crop point (can change dz)
        m{i}.updateCrop();
        % Link to catalog
        m{i}.linkCatalogue(c001Dir, 'i', idx);
        m{i}.saveInCatalogue();
        t = m{i}.grepTable();

        %v0.2b addition
        if isempty(t) == 1
          	warning(['Skip: ' tomoName  '_' num2str(contour(i)) 'does not have any particles!']);
        	continue;
        end

        t(:,23) = contour(i); % Additing contour number (filament)
        
        t_xform = load([origParticleDir '/' tomoName '_' num2str(contour(i)) '/xform.tbl']);
        txform(1, 5) = 0;
        t_ali = dynamo_table_rigid(t, t_xform(1,4:6));
        
        % Construct 13 pf table
        % 23 = filament number
        % 31 = subboxing = PF number        
        for pf = 1:size(shifts, 1)
            Tp{pf}.type = 'shiftrot';
            Tp{pf}.shifts = shifts(pf, :);
            Tp{pf}.eulers = rots(pf, :);
            t_ali_pf{pf} = dynamo_table_rigid(t_ali, Tp{pf});
            t_ali_pf{pf}(:, 31) = pf;
        end
        
       
        % Cropping subtomogram out
        % 0.2b
        try
           for pf = 1:size(shifts, 1)
            dwrite(t, [modelDir '/' tomoName '_' num2str(contour(i)) '_pf' num2str(pf) '.tbl']);
           	targetFolder = [particleDir '/'  tomoName '_' num2str(contour(i)) '_pf' num2str(pf)];
           	dtcrop(docFilePath, t_all_pf{pf}, targetFolder, boxSize/2, 'mw', mw);
           	tCrop = dread([targetFolder '/crop.tbl']);
           	oa_all = daverage(targetFolder, 't', tCrop, 'fc', 1, 'mw', mw);
           	dwrite(dynamo_bandpass(oa_all.average, [1 round(pixelSize/avgLowpass*boxSize)]), [targetFolder '/average.em']);
           	dynamo_table2chimeramarker([targetFolder '/crop.cmm'], [targetFolder '/crop.tbl'], 2);
           end
           
        catch
  			warning(['Skip: ' tomoName  '_' num2str(contour(i)) 'does not have enough particles!'])
  			continue;
  		end	
  		% If it is cropping out
  		filamentRepickList{end + 1, 1} = [tomoName  '_' num2str(contour(i))];   
    end
    % Write the DynamoModel
    dwrite(m, modelout);
end

%% Write filament list out
writecell(filamentRepickList, filamentRepickListFile);


