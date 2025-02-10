%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Script to check for outlier after alignment
% NOT TESTED
% dynamoMT v0.1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%% Before Running Script %%%%%%%%%%%%%%%
%%% Activate Dynamo
run /storage/software/Dynamo/dynamo_activate.m

% Change path to the correct directory
prjPath = '/storage/builab/Thibault/20240905_SPEF1_MT_TS/MTavg/';


%%%%%%% Variables subject to change %%%%%%%%%%%

docFilePath = sprintf('%scatalogs/tomograms.doc', prjPath);
filamentListFile = sprintf('%sfilamentListTwist.csv', prjPath);
alnDir = sprintf('%sintraAln_twist', prjPath);
particleDir = sprintf('%sparticles_twist', prjPath);
boxSize = 80; % Original extracted subvolume size
mw = 12; % Number of parallel workers to run
gpu = [0]; % Alignment using gpu for titann setting
pixelSize = 8.48; % Angstrom per pixel
avgLowpass = 30; % In Angstrom to convert to Fourier Pixel
alnLowpass = 30; % In Angstrom to convert to Fourier Pixel, 50 if you only need to align the filament well, 35-40Angstrom for clear tubulin MT
zshift_limit = 6; % ~4nm 

%%%%%%% Do not change anything under here %%%%%

% Example matrix t
% Example matrix t
t = rand(100, 26); % Replace with your actual data
t(:, 24:26) = t(:, 24:26) * 10; % Example origin points
t(:, 4:6) = t(:, 4:6) * 0.1; % Example translational shifts
t(:, 7:9) = t(:, 7:9) * 180; % Example rotational angles

% Expected Euclidean distance between points
D = 1.0;

% RANSAC parameters
threshold = 0.5; % Distance threshold for inliers
maxIterations = 1000; % Maximum number of RANSAC iterations

% Detect outliers
outliers = detectOutliers(t, D, threshold, maxIterations);
inliers = setdiff(1:size(t, 1), outliers);

% Correct outliers
t = correctOutliers(t, outliers, inliers);

% Display corrected matrix
disp(t);

% function to Detect outlier

function outliers = detectOutliers(t, D, threshold, maxIterations)
    % Inputs:
    % t: Input matrix with columns as described
    % D: Expected Euclidean distance between points
    % threshold: Distance threshold for inliers
    % maxIterations: Maximum number of RANSAC iterations

    % Output:
    % outliers: Indices of rows in t that are outliers

    numPoints = size(t, 1);
    bestInliers = [];
    bestModel = [];

    for iter = 1:maxIterations
        % Randomly select a subset of points to fit the model
        sampleIndices = randperm(numPoints, 2); % Use 2 points to define a linear trend
        samplePoints = t(sampleIndices, :);

        % Fit a linear model for column 9 (rotational angle)
        p = polyfit(samplePoints(:, 9), 1:2, 1); % Fit a line to the sample points
        linearTrend = polyval(p, t(:, 9)); % Evaluate the linear trend for all points

        % Calculate residuals for column 9 (deviation from linear trend)
        residualsCol9 = abs(t(:, 9) - linearTrend);

        % Check similarity of columns 7 and 8 (rotational angles)
        residualsCol7_8 = abs(t(:, 7) - t(:, 8));

        % Check Euclidean distances between points after translational shifts
        shiftedPoints = t(:, 24:26) + t(:, 4:6); % Apply translational shifts
        distances = pdist2(shiftedPoints, shiftedPoints); % Compute pairwise distances
        meanDistances = mean(distances, 2); % Mean distance for each point
        residualsDistances = abs(meanDistances - D); % Deviation from expected distance D

        % Combine residuals to determine inliers
        combinedResiduals = residualsCol9 + residualsCol7_8 + residualsDistances;
        inliers = find(combinedResiduals < threshold);

        % Update best model if this iteration has more inliers
        if length(inliers) > length(bestInliers)
            bestInliers = inliers;
            bestModel = p;
        end
    end

    % Identify outliers as points not in the best inlier set
    outliers = setdiff(1:numPoints, bestInliers);

    % Display results
    fprintf('Number of inliers: %d\n', length(bestInliers));
    fprintf('Number of outliers: %d\n', length(outliers));
    fprintf('Outlier indices: %s\n', mat2str(outliers));
end

function t = correctOutliers(t, outliers, inliers)
    % Inputs:
    % t: Input matrix with columns as described
    % outliers: Indices of rows in t that are outliers
    % inliers: Indices of rows in t that are inliers

    % For each outlier, find the nearest inliers and compute new values
    for i = 1:length(outliers)
        outlierIdx = outliers(i);

        % Extract the original coordinates of the outlier
        outlierCoords = t(outlierIdx, 24:26);

        % Compute distances to all inliers
        inlierCoords = t(inliers, 24:26);
        distances = pdist2(outlierCoords, inlierCoords);

        % Find the nearest inliers (e.g., top 3)
        [~, sortedIndices] = sort(distances, 'ascend');
        nearestInliers = inliers(sortedIndices(1:3)); % Use 3 nearest inliers

        % Interpolate translational shifts (columns 4-6)
        t(outlierIdx, 4:6) = mean(t(nearestInliers, 4:6), 1);

        % Interpolate rotation angles (columns 7-9)
        t(outlierIdx, 7:9) = mean(t(nearestInliers, 7:9), 1);
    end
end