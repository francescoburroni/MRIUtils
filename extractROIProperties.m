function [frameROIMeanInt,CentroidROIPosition] = extractROIProperties(S, mask, opts)
% extract mean intensity and centroid(s) in ROI of MRI speech data
arguments (Input)
    S
    mask
    opts.flipud logical = false;
    opts.rescaleFactor double = 1;
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
        centroidInt(l,1:2) = props.WeightedCentroid; % [x, y]

        nexttile(1)
        imagesc(frame); hold on;
        plot(centroidInt(l,1),centroidInt(l,2),"wo"); hold on;
        xlim([40 120])
        ylim([40 120])
        pause(.25)
        shg

    end
    frameROIMeanInt{k} =    meanInt;
    CentroidROIPosition{k} = centroidInt;

  end

end