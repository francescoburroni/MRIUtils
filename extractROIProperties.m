function [frameROIMeanInt,CentroidROIPosition] = extractROIProperties(S, mask, opts)
% extract mean intensity and centroid(s) in ROI of MRI speech data
arguments (Input)
    S
    mask
    opts.flipud logical = false;
    opts.rescaleFactor double = 1;
    opts.doPlot logical = false
end

arguments (Output)
    frameROIMeanInt
    CentroidROIPosition
end

for k = 1 : numel(S)
    if opts.flipud
        mri = imresize(flipud(S(k).mri),opts.rescaleFactor);
    else
        mri = imresize(S(k).mri,opts.rescaleFactor);
    end

    meanInt = nan(size(mri,3),1);
    centroidInt = nan(size(mri,3),2);

    shg
    for l = 1 : size(mri,3)
        frame = mri(:,:,l);
        frameROI = frame(mask.array);
        meanInt(l,1) = mean(frameROI(:));

        % get centroid
        maskedFrame = double(frame) .* (mask.array);
        props = regionprops(mask.array, maskedFrame, "WeightedCentroid");
        if numel(props) == 1
            centroidInt(l,1:2) = props.WeightedCentroid;
        else
            centroidInt(l,1:2) = selectCentroid(props, mask.name);
            warning('extractROIProperties:multipleRegions', ...
                'Mask "%s" has %d connected components at frame %d. Selecting %s component.', ...
                mask.name, numel(props), l, selectionRule(mask.name));
        end
        centroidInt(l,1:2) = props.WeightedCentroid; % [x, y]
        
        if opts.doPlot
        nexttile(1)
        imagesc(frame); hold on;
        colormap("bone")
        plot(centroidInt(l,1),centroidInt(l,2),"w.",MarkerSize=25); hold on;
        pause(.25)
        end

    end
    frameROIMeanInt{k} =    meanInt;
    CentroidROIPosition{k} = centroidInt;

end

end

function rule = selectionRule(maskName)
switch lower(maskName)
    case {'larynx','velum'}
        rule = 'rightmost';
    case 'lips'
        rule = 'largest';
    otherwise
        rule = 'largest';
end
end

function centroid = selectCentroid(props, maskName)
centroids = vertcat(props.WeightedCentroid);  % x, y per component
areas     = vertcat(props.Area);

switch lower(maskName)
    case {'larynx', 'velum'}
        % rightmost centroid (largest x)
        [~, idx] = max(centroids(:,1));
        centroid = centroids(idx,:);
    case 'lips'
        % largest component or return both for aperture computation
        [~, idx] = max(areas);
        centroid = centroids(idx,:);
end
end