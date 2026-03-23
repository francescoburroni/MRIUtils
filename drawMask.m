function mask = drawMask(S,results,maskType,maskName)
% Draw a mask on MRI image using maximum standard deviation as a
% guide
arguments (Input)
    S
    results
    maskType (1,1) string {mustBeMember(maskType,["rectangle","polygon"])} = "rectangle"
end

arguments (Output)
    mask 
end

mask.name
imshowpair(results.MRI(:,:,1),results.mriStd,"falsecolor")
shg

switch maskType
    case "rectangle"
        roi = drawrectangle();
    case "polygon"
        roi = drawpolygon();
end

mask.array = roi.createMask;
imshowpair(results.MRI(:,:,1),mask.array ,"falsecolor")
shg 

end