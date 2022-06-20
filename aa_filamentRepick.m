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
% Seems to work better running on merged_particles.tbl instead of merged_particles_aln.tbl
% Implement a nearest neighbour for angle assignnment, still doesn't work yet due to Dynamo careless angle interpolation.

%%%%%%%% Before Running Script %%%%%%%%%%
%%% Activate Dynamo
run /london/data0/software/dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/london/data0/20220404_TetraCU428_Tip_TS/ts/tip_CP_dPhi/';

%%%%%%%%

% Input
docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
modelDir = sprintf('%smodels_repick', prjPath);
origParticleDir = sprintf('%sparticles', prjPath);
particleDir = sprintf('%sparticles_repick', prjPath);
c001Dir = sprintf('%scatalogs/c001', prjPath);
pixelSize = 8.48; % Angstrom per pixel
periodicity = 82.8; % 82.8 for tipCP, xx for baseCP, 169 doublet
boxSize = 96;
mw = 12;
subunits_dphi = 0.72;  % For the tip CP 0.72, baseCP 0.5, doublet 0
subunits_dz = periodicity/pixelSize; % in pixel repeating unit dz = 8.4 nm = 168 Angstrom/pixelSize
filamentListFile = sprintf('%sfilamentList.csv', prjPath);
tableAlnFileName = 'merged_particles.tbl'; % merge particles before particle alignment for robust
avgLowpass = 40; % Angstrom
dTh = 40; % Distance Threshold in Angstrom
doExclude = 1; % Exclude particles too close
doOutlier = 0; % Exclude outlier using CC using MAD
doInitialAngle = 0; % Only turn on for axoneme case now


% loop through all tomograms
fileID = fopen(docFilePath); D = textscan(fileID,'%d %s'); fclose(fileID);
tomoID = D{1,1}'; % get tomogram ID
nTomo = length(D{1,2}); % get total number of tomograms

tAll = dread(tableAlnFileName);

% Loop through tomograms
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
    if doExclude > 0
        tTomoEx = dpktbl.exclusionPerVolume(tTomo, dTh/pixelSize);
        tTomo = tTomoEx;
        display(['Exclude ' num2str(length(tTomo) - length(tTomoEx)) ' particles due to proximity']);

    end
    modelout =   [modelDir '/' tomoName '.omd'];
    contour = unique(tTomo(:, 23));
    
    % 0.2b Now use col 23 as filament number
    m = {}; % Cell array contains all filament
    
    for i = 1:length(contour)        
        tContour = tTomo(tTomo(:, 23) == contour(i), :);
       
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
       
        m{i} = dmodels.filamentWithTorsion();
        m{i}.subunits_dphi = subunits_dphi;
        m{i}.subunits_dz = subunits_dz;
        
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
        t(:,23) = contour(i); % Additing contour number (filament)
        
        if doInitialAngle > 0
            phi = median(tContour(:, 9)); % Same as AA         
            %midIndex = floor(size(t, 1)/2);
            %t(:, 9 = t(:, 9) - t(midIndex, 9) + phi; 
            t(:, 9) = phi; % This works will in case of doublet, in case of tip/base cp, make the middle value to this and then same shift
        end
        
        dwrite(t, [modelDir '/' tomoName '_' num2str(contour(i)) '.tbl']);
        targetFolder = [particleDir '/'  tomoName '_' num2str(contour(i))];
        
        % Cropping subtomogram out
        dtcrop(docFilePath, t, targetFolder, boxSize, 'mw', mw);
        % Average the middle region again
        midIndex = floor(size(t, 1)/2);
        if size(t, 1) > 15
            tMiddle = t(midIndex - 3: midIndex + 4, :);
        else
            tMiddle = t;
        end 
        oa = daverage(targetFolder, 't', tMiddle, 'fc', 1, 'mw', mw);
        dwrite(dynamo_bandpass(oa.average, [1 round(pixelSize/avgLowpass*boxSize)]), [targetFolder '/template.em']);
        
        % Plotting save & close
        dtplot([targetFolder '/crop.tbl'], 'pf', 'oriented_positions');
        view(-230, 30); axis equal;
        print([targetFolder '/repick_' tomoName '_' num2str(contour(i))] , '-dpng');
        close all
        
    end
    % Write the DynamoModel
    dwrite(m, modelout);
end
