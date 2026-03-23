function displayMRI(S, opts)
% DISPLAYMRI Display synchronized MRI, spectrogram and waveform, and write video
%
%   displayMRI(S) displays an animated figure showing MRI frames alongside
%   a spectrogram and waveform, synchronized in time, and writes the result
%   to a video file.
%
%   displayMRI(S, resizeFactor=5) rescales MRI frames by the given factor.
%
%   displayMRI(S, outputFile="myVideo.avi") writes to a custom filename.
%
%   Note: output is uncompressed AVI and can be large.
%   TODO: convert to mp4 after release using FFmpeg:
%         system(sprintf("ffmpeg -i %s -vcodec libx264 %s", opts.outputFile, strrep(opts.outputFile, ".avi", ".mp4")))
%
%   Input:
%       S            - struct with fields:
%                        .mri     [H x W x nFrames] MRI tensor
%                        .audio   [nSamples x 1] audio signal
%                        .audioFs sampling rate of audio (Hz)
%                        .mriFs   frame rate of MRI (Hz)
%   Optional:
%       resizeFactor - positive scalar, MRI frame upscaling (default: 10)
%       outputFile   - string, output video filename (default: "output.avi")

arguments
    S
    opts.resizeFactor (1,1) double {mustBePositive} = 1
    opts.outputFile   (1,1) string                  = "output.avi"
end

resizeFactor = opts.resizeFactor;
pauseDur = 1/S.mriFs;
tAudio = getTimeVector(S.audio,S.audioFs);
tMRI = linspace(tAudio(1),tAudio(end),size(S.mri,3));
audioSamplePerFrame = round(size(S.audio,1)/size(S.mri,3));
audioBuffer = buffer(S.audio,audioSamplePerFrame,1);
cMap = bone;

% Compute spectrogram
x = S.audio;
for k = 2 : size(x,1)
    xPreEmph1(k) = x(k) - .95 .* x(k-1);
end
winLen = round(.004.* S.audioFs);
overLapLen = winLen - round(.001.* S.audioFs);
nPoints = 1024;

% Prepare figure
fig = figure(Theme="dark",Units="normalized",Position=[0 0 0.25 1]);
colormap(cMap)
tl = tiledlayout(3,1,TileSpacing="none");
shg
pause(1)
nexttile(1)
k = 1;
frame = imresize(flipud(S.mri(:,:,k)),resizeFactor);
imagesc(frame);
text(1,1,sprintf("%03d",k),FontSize=25,Color=cMap(end,:),VerticalAlignment="top")
xticks([])
yticks([])
nexttile(3)
plot(tAudio,S.audio,Color=cMap(175,:));
l3 = xline(tAudio(k),LineWidth=2);
ax3=gca;
nexttile(2)
colormap(flip(cMap))
spectrogram(xPreEmph1,gausswin(winLen),overLapLen,nPoints,S.audioFs,"yaxis","MinThreshold",-100);
l2 = xline(tAudio(k),LineWidth=2);
hold on;
colorbar("off")
xlabel("")
xticklabels([])
grid on
box on
title("")
ax2=gca;
colormap(cMap)
linkaxes([ax2 ax3],"x")

% Prepare video
vidWrite = vision.VideoFileWriter(opts.outputFile);
vidWrite.FrameRate = S.mriFs;
vidWrite.AudioInputPort = true;
vidFrame = getframe(fig);
img = vidFrame.cdata;
vidWrite(img,audioBuffer(:,k))
pause(pauseDur)

for k = 2 : size(S.mri,3)
    nexttile(1)
    pauseDur = 1/S.mriFs;
    frame = imresize(flipud(S.mri(:,:,k)),resizeFactor);
    imagesc(frame);
    text(1,1,sprintf("%03d",k),VerticalAlignment="top")
    xticks([])
    yticks([])
    nexttile(3)
    l2.Value=tMRI(k);
    nexttile(3)
    l3.Value=tMRI(k);
    pause(pauseDur)
    vidFrame = getframe(fig);
    img = vidFrame.cdata;
    vidWrite(img,audioBuffer(:,k))
end

vidWrite.release
close(fig)
end