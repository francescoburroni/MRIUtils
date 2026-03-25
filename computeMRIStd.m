function [sigmaM, image3DM] = computeMRIStd(S, opts)
% Compute an std Matrix from MRI tensor to initialize centroid
% tracking

arguments (Input)
    S struct
    opts.colorMap {mustBeMember(opts.colorMap,["parula","turbo"...
        "spring","summer","autumn","winter" ...
        "hsv","hot","cool"...
        "gray","bone","copper","pink","sky"...
        "abyss","nebula","jet","lines"])} = "bone";
    opts.fName string = ""
    opts.dims double = 0.75;
    opts.flipud logical = false
end

arguments (Output)
    sigmaM (:,:)
    image3DM(:,:,:)
end

% Prepare figure

colormap(opts.colorMap)
image3DM = (buildMRITensor(S,flipud=opts.flipud));
sigmaM = std(double(image3DM),1,3);
imagesc(sigmaM)
colorbar()
set(gca,"LineWidth",2)

if ~strcmpi(opts.fName,"")
    fig = figure(Theme="dark",Units="normalized",Position=[0 0 opts.dims opts.dims]);
    pause(1)
    exportgraphics(fig,opts.fName)
    close(fig)
else
    fprintf("Press space bar to continue \n")
    pause()
end


end