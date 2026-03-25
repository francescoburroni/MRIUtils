function mask = drawMRIMask(results, opts)
% DRAWMASK Interactively draw a mask on an MRI image
%
%   mask = drawMask(results) displays the first MRI frame fused with the
%   standard deviation image as a falsecolor overlay, prompts the user to
%   draw a rectangular ROI, and returns a logical mask.
%
%   mask = drawMask(results, maskType="polygon") uses a polygon ROI instead,
%   useful for irregular anatomical regions such as the velum.
%
%   mask = drawMask(results, maskName="velum") attaches a name to the mask
%   for later identification and visualization.
%
%   The user is shown the resulting mask overlaid on the first frame and
%   asked to confirm. If unsatisfied, they can redraw until happy.
%
%   Input:
%       results       - struct with fields:
%                         .MRI     [H x W x T] MRI tensor
%                         .mriStd  [H x W] standard deviation image
%   Optional:
%       maskType      - string, ROI shape: "rectangle" (default), "polygon",
%                       "ellipse", or "circle"
%       maskName      - string, label for this mask (default: "")
%   Output:
%       mask          - struct with fields:
%                         .name    string label
%                         .array   [H x W] logical mask array

arguments (Input)
    results
    opts.maskType (1,1) string {mustBeMember(opts.maskType, ["rectangle","polygon","ellipse","circle"])} = "rectangle"
    opts.maskName = "No Name Mask"
end
arguments (Output)
    mask
end

mask.name = opts.maskName;
answer = "";

while ~strcmpi(answer, "Yes")
    % Display first frame fused with std image as drawing canvas
    imshowpair(results.MRI(:,:,1), results.mriStd, "falsecolor")
    shg

    % Draw ROI of requested type
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

    % Show mask overlaid on first frame for confirmation
    mask.array = roi.createMask;
    imshowpair(results.MRI(:,:,1), mask.array, "falsecolor")
    shg

    answer = questdlg("Is the ROI okay?", "ROI Confirmation");
end

end