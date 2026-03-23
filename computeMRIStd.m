function sigmaM = computeMRIStd(S, opts)
% Compute an std Matrix from MRI tensor to initialize centroid
% tracking

arguments (Input)
   S struct
   opts.colorMap {mustBeMember(opts.colorMap,["parula","turbo"...
       "spring","summer","autumn","winter" ...
       "hsv","hot","cool"...
       "gray","bone","copper","pink","sky"...
       "abyss","nebula","jet","lines"])} = "bone";
end

arguments (Output)
   sigmaM (:,:)
end

colormap(opts.colorMap)
MRI = double(buildMRITensor(S,flipud=true));
I = std(double(MRI),1,3);
imagesc(I)
end