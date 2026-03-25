function results = computeMRIStd(S, opts)
% COMPUTEMRISTD Build MRI tensor and compute pixel-wise standard deviation
% across frames to visualize articulatorily active regions of the vocal tract.
%
% This function serves as the entry point for the results struct, initializing
% two core fields:
%   - results.MRI    : the full concatenated MRI tensor across all trials
%   - results.MRIStd : pixel-wise std map, used to draw masks and identify
%                      high-variance (articulatorily active) regions
%
% High-variance pixels trace air-tissue boundaries and outline the vocal
% tract — tongue, lips, velum, larynx — making the std map a natural
% basis for mask generation (see drawMRIMask).
%
% Syntax:
%   results = computeMRIStd(S)
%   results = computeMRIStd(S, flipud=true, fName="output.png")
%
% Inputs:
%   S           - struct array of trials, each with field .mri (H x W x nFrames)
%
% Optional name-value inputs:
%   colorMap    - colormap for std map display (default: "bone")
%   flipud      - flip frames vertically before building tensor (default: false)
%   fName       - if provided, save figure to this filename and close (default: "")
%   dims        - figure size as fraction of screen, used when saving (default: 0.75)
%
% Output:
%   results     - struct with fields:
%                   .MRI    : H x W x nTotalFrames uint16 tensor
%                   .MRIStd : H x W double std map
%
% See also: buildMRITensor, drawMRIMask, extractROIProperties
%
% Author: Francesco Burroni
% Last edited: Mar 25 2026

%% Input/Output argument validation
arguments (Input)
    S struct
    opts.colorMap {mustBeMember(opts.colorMap, ["parula","turbo", ...
        "spring","summer","autumn","winter", ...
        "hsv","hot","cool", ...
        "gray","bone","copper","pink","sky", ...
        "abyss","nebula","jet","lines"])} = "bone";
    opts.fName  string  = ""     % output filename for saving figure; "" = interactive mode
    opts.dims   double  = 0.75;  % figure size as fraction of screen (used when saving)
    opts.flipud logical = false  % flip MRI frames vertically before processing
end
arguments (Output)
    results  % struct with fields MRI and MRIStd
end

%% Build MRI tensor and compute std map
% Concatenate all trial frames into a single 3D tensor (H x W x nTotalFrames)
results.MRI = buildMRITensor(S, flipud=opts.flipud);

% Compute pixel-wise standard deviation across the frame dimension.
% High values indicate pixels that move a lot — i.e. air-tissue boundaries
% at articulatorily active regions (tongue, lips, velum, larynx).
results.MRIStd = std(double(results.MRI), 1, 3);

%% Display std map
% Note: colormap applied to current axes — will be scoped properly once
% this is integrated into uifigure-based visualizer
colormap(opts.colorMap)
imagesc(results.MRIStd)
colorbar()
set(gca, "LineWidth", 2)

%% Save or pause
if ~strcmpi(opts.fName, "")
    % Save mode: open dark-themed figure, export to file, close
    fig = figure(Theme="dark", Units="normalized", Position=[0 0 opts.dims opts.dims]);
    pause(1)  % allow figure to render before export
    exportgraphics(fig, opts.fName)
    close(fig)
else
    % Interactive mode: wait for user to inspect std map before continuing
    fprintf("Press space bar to continue \n")
    pause()
end

end