function [] = inspectMRIProperties(results,opts)
%Inspect
arguments (Input)
    results
    opts.Colormap = "bone"
    opts.col (1, 3)= [0.8667    0.3294         0];
    opts.alpha (1, 1) = 0.5; 

end

arguments (Output)

end



% Set up image
colormap(opts.Colormap)
I = results.MRIC{1}(:,:,1);
allMaskImg = zeros(size(I,1), size(I,2));
maskNames = fieldnames(results.masks);
for k = 1:numel(maskNames)
    allMaskImg = allMaskImg + double(results.masks.(maskNames{k}).array);
end


[I2, I2Alpha] = getRGBfromMask(allMaskImg,opts.col,opts.alpha);

% Plot MRI frame then overlay filled mask with transparency
ISC = imagesc(I); hold on;
ISC2 = imagesc(I2,AlphaData=I2Alpha);
shg;

% Add centroids at time 1
for k = 1:numel(maskNames)
    p(k) = plot(results.masks.(maskNames{k}).centroid{1}(1,1),...
        results.masks.(maskNames{k}).centroid{1}(1,2),LineStyle="none",...
        Marker="o",MarkerFaceColor=opts.col,MarkerEdgeColor="w",MarkerSize=5);
end

for k = 1 : numel(results.MRIC)
    for l = 1 : size(results.MRIC{k},3)
        set(ISC,"CData",results.MRIC{k}(:,:,l))

        for m = 1:numel(maskNames)
            p(m).XData = results.masks.(maskNames{m}).centroid{k}(l,1);
            p(m).YData =  results.masks.(maskNames{m}).centroid{k}(l,2);
        end
        pause(.1)
    end

end





end

function [I, IAlpha] = getRGBfromMask(mask,color,alpha);

M = repmat(mask,[1 1 3]);
colorM = repmat(reshape(color,[1 1 3]),size(M,1),size(M,2));
I = M.*colorM;
IAlpha = mask.*alpha;


end