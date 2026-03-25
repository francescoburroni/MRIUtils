function results = extractROIProperties(results, opts)
% EXTRACTROIPROPERTIES Extract mean intensity and weighted centroid in a
% mask ROI from rtMRI speech data, storing results in the results struct.
%
% For each trial in results.MRIC, loops over MRI frames and computes:
%   - Mean pixel intensity within the mask region (constriction degree proxy)
%   - Weighted centroid of the mask region, using pixel intensities as weights
%
% Results are stored under results.masks.(maskName) alongside the mask array,
% keeping all mask-related data together in one place.
%
% If the mask contains multiple connected components (e.g. upper/lower lip),
% the function selects the most anatomically appropriate component based on
% mask name (rightmost for larynx/velum, largest for lips) and issues a warning.
%
% Syntax:
%   results = extractROIProperties(results)
%   results = extractROIProperties(results, maskName="larynx", doPlot=true)
%
% Inputs:
%   results - struct with fields:
%               .MRIC  : {1 x nTrials} cell array of MRI tensors (H x W x nFrames)
%               .masks : struct with mask fields e.g. .masks.larynx
%
% Optional name-value inputs:
%   maskName      - name of mask to use, must exist in results.masks (default: "noName")
%   rescaleFactor - spatial rescaling factor passed to imresize (default: 1)
%   doPlot        - display frames with centroid overlay during processing (default: false)
%
% Output:
%   results - input struct with added fields:
%               .masks.(maskName).meanInt  : {1 x nTrials} mean intensity vectors
%               .masks.(maskName).centroid : {1 x nTrials} centroid position matrices [x, y]
%
% Notes:
%   - Mean intensity is a proxy for constriction degree: lower intensity
%     (more air/darkness in ROI) typically indicates greater constriction.
%   - Weighted centroid tracks the center of mass of the articulator within
%     the ROI, useful for tracking articulator position over time.
%
% See also: regionprops, drawMRIMask, computeMRIStd
%
% Author: Francesco Burroni
% Last edited: Mar 25 2026

%% Input/Output argument validation
arguments (Input)
    results
    opts.maskName      string  = "noName"  % must match a field in results.masks
    opts.rescaleFactor double  = 1;        % spatial rescaling factor (1 = no rescaling)
    opts.doPlot        logical = false;    % toggle frame-by-frame visualization
end
arguments (Output)
    results
end

%% Retrieve mask from results
mask = results.masks.(opts.maskName);

%% Main loop over trials
for k = 1:numel(results.MRIC)

    %% Preprocessing: rescale MRI frames if needed
    mri = imresize(results.MRIC{k}, opts.rescaleFactor);

    % Preallocate outputs for this trial
    nFrames     = size(mri, 3);
    meanInt     = nan(nFrames, 1);
    centroidInt = nan(nFrames, 2);

    %% Frame loop: compute intensity and centroid per frame
    for l = 1:nFrames
        frame = mri(:,:,l);

        %% Mean intensity within ROI
        % Extract pixels within mask and compute mean.
        % Lower values indicate more air (constriction) in the ROI.
        frameROI      = frame(mask.array);
        meanInt(l, 1) = mean(frameROI(:));

        %% Weighted centroid within ROI
        % Weight pixel positions by intensity to track articulator center of mass.
        maskedFrame = double(frame) .* double(mask.array);
        props = regionprops(mask.array, maskedFrame, "WeightedCentroid", "Area");

        if numel(props) == 1
            % Single connected component — use directly
            centroidInt(l, 1:2) = props.WeightedCentroid;
        else
            % Multiple components — select most anatomically appropriate one
            % Warning fires once per mask name per session
            centroidInt(l, 1:2) = selectCentroid(props, mask.name);
            warning('extractROIProperties:multipleRegions', ...
                ['Mask "%s" has %d connected components at frame %d. ' ...
                'Selecting %s component. Check mask or use imfill/imdilate to merge regions.'], ...
                mask.name, numel(props), l, selectionRule(mask.name));
        end

        %% Optional visualization
        if opts.doPlot
            imagesc(frame); hold on;
            colormap("bone");
            plot(centroidInt(l,1), centroidInt(l,2), "w.", MarkerSize=25);
            hold off;
            pause(0.1);
        end

    end % end frame loop

    %% Store trajectories under results.masks.(maskName)
    % Access pattern: results.masks.larynx.meanInt{k}, results.masks.velum.centroid{k}
    results.masks.(opts.maskName).meanInt{k}  = meanInt;
    results.masks.(opts.maskName).centroid{k} = centroidInt;

end % end trial loop

end % end main function


%% Local helper functions

function rule = selectionRule(maskName)
% SELECTIONRULE Return string describing centroid selection strategy for
% a given mask name. Used for informative warning messages.
switch lower(maskName)
    case {'larynx', 'velum'}
        rule = 'rightmost';   % larynx and velum are rightmost/posterior in sagittal view
    case 'lips'
        rule = 'largest';     % lips may have upper/lower components; keep largest
    otherwise
        rule = 'largest';     % default fallback
end
end


function centroid = selectCentroid(props, maskName)
% SELECTCENTROID Select the most anatomically appropriate centroid when
% a mask contains multiple connected components.
%
% Strategy:
%   larynx, velum : rightmost component (largest x coordinate)
%   lips, other   : largest component by area
%
% Inputs:
%   props    - struct array from regionprops with WeightedCentroid and Area fields
%   maskName - string name of the mask
%
% Output:
%   centroid - [1 x 2] selected centroid [x, y]

centroids = vertcat(props.WeightedCentroid);  % [nComponents x 2] array of [x, y]
areas     = vertcat(props.Area);              % [nComponents x 1] pixel counts per component

switch lower(maskName)
    case {'larynx', 'velum'}
        % Select rightmost component — larynx and velum are posterior
        % in sagittal midline images (largest x coordinate)
        [~, idx] = max(centroids(:, 1));
        centroid  = centroids(idx, :);
    case 'lips'
        % Select largest component by area — more robust than position
        % when upper/lower lip components are both present
        [~, idx] = max(areas);
        centroid  = centroids(idx, :);
    otherwise
        % Default: largest component by area
        [~, idx] = max(areas);
        centroid  = centroids(idx, :);
end
end