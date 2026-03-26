function results = drawMRIMask(results, opts)
% DRAWMRIMAGE Interactively draw a mask on an MRI image and store it in results.
%
% Displays the first MRI frame fused with the standard deviation image as a
% falsecolor overlay, prompts the user to draw an ROI, and stores the resulting
% mask in results.masks.(maskName) for downstream use in trajectory extraction
% and visualization.
%
% The user is shown the resulting mask overlaid on the first frame and asked
% to confirm. If unsatisfied, they can redraw until happy.
%
% Syntax:
%   results = drawMRIMask(results)
%   results = drawMRIMask(results, maskName="velum", maskType="polygon")
%
% Inputs:
%   results       - struct with fields:
%                     .MRI    : H x W x nFrames MRI tensor
%                     .MRIStd : H x W standard deviation map
%
% Optional name-value inputs:
%   maskType  - ROI shape: "rectangle" (default), "polygon", "ellipse", "circle"
%   maskName  - string label for this mask (default: "No Name Mask")
%               used as field name in results.masks.(maskName)
%
% Output:
%   results   - input struct with added field:
%                 .masks.(maskName) : struct with fields
%                     .name  : string label
%                     .array : H x W logical mask array
%                     .type  : string ROI type used
%
% See also: computeMRIStd, extractROIProperties
%
% Author: Francesco Burroni
% Last edited: 2026

%% Input/Output argument validation
arguments (Input)
    results
    opts.maskType (1,1) string {mustBeMember(opts.maskType, ...
        ["rectangle","polygon","ellipse","circle"])} = "rectangle"
    opts.maskName (1,1) string = "noName"
end
arguments (Output)
    results
end

%% Interactive ROI drawing loop
answer = "";
while ~strcmpi(answer, "Yes")

    %% Display drawing canvas — first frame fused with std map
    % Falsecolor overlay highlights high-variance regions to guide mask placement
    imshowpair(results.MRI(:,:,1), results.MRIStd, "falsecolor")
    shg

    %% Draw ROI of requested type
    switch opts.maskType
        case "rectangle"
            roi = drawrectangle();
        case "polygon"
            roi = drawpolygon();
        case "ellipse"
            roi = drawellipse();
        case "circle"
            roi = drawcircle();
    end

    %% Preview mask overlaid on first frame for user confirmation
    mask.array = roi.createMask();
    mask.roi = roi();
    imshowpair(results.MRI(:,:,1), mask.array, "falsecolor")
    shg
    answer = questdlg("Is the ROI okay?", "ROI Confirmation");

end

%% Compute pharyngeal reference point for velum mask
% The top-right corner of the velum ROI approximates the velopharyngeal
% port — the point the velum moves toward/away from during opening/closing.
% Only meaningful for the velum mask.
if strcmpi(opts.maskName, "velum")
    [rows, cols] = find(mask.array);
    mask.pharyngealRef = [max(cols), min(rows)];
end

%% Store mask in results struct under its name
mask.name = opts.maskName;
mask.type = opts.maskType;
results.masks.(opts.maskName) = mask;

end