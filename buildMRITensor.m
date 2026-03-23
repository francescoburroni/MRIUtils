function MRI = buildMRITensor(S, opts)
% BUILDMRITENSOR Concatenate MRI frames from struct array into a single tensor
%
%   MRI = buildMRITensor(S) takes a struct array S where each element
%   contains a field .mri (height x width x frames) and returns a single
%   tensor MRI (height x width x totalFrames).
%
%   MRI = buildMRITensor(S, flipud=true) additionally flips each frame
%   vertically, useful for standard anatomical orientation in sagittal MRI.
%
%   Input:
%       S          - struct array with field .mri [H x W x frames]
%   Optional:
%       flipud     - logical, flip frames vertically (default: false)
%   Output:
%       MRI        - [H x W x totalFrames] tensor

arguments
    S
    opts.flipud (1,1) logical = false
end

dim1  = size(S(1).mri,1);
dim2 = size(S(1).mri,2);
mriC = {S.mri};
dim3 = sum(cellfun(@(x) size(x,3), mriC));

MRI = zeros(dim1,dim2,dim3,"like",S(1).mri);
idxFrameStart = 1;
idxFrameEnd = size(mriC{1},3);

for k = 1:numel(S)
    if opts.flipud
        mri = flipud(S(k).mri);
    else
        mri = S(k).mri;
    end
    MRI(:,:,idxFrameStart:idxFrameEnd) = mri;
    
    if k~=numel(S)
    idxFrameStart = idxFrameEnd+1;
    idxFrameEnd = idxFrameStart+size(mriC{k+1},3)-1;
    end

end
end