function data = tools_filterDat(data,baseline,fs,lpfilt,winfilt)

% this function filters down the rows - meaning you have to filter the transpose of the matrix
% (row x column in original data is chan x time; transposing means time x chan)
if ~isempty(lpfilt)
    % construction filter for lowpass, butterworth IIR
    d = designfilt('lowpassiir','FilterOrder',2,'HalfPowerFrequency',lpfilt,'DesignMethod','butter','SampleRate',fs);

    % to get half amplitude, do filtfilt (backward spreading) or filter twice (forward spreading)
    data.avg = filtfilt(d,data.avg');
    data.avg = data.avg';
end

% moving window filter - can remove things such as alpha noise
if ~isempty(winfilt)
    fc = winfilt; % cut-off frequency
    winsize = fs/fc;
    for i = 1:size(data.avg,1)
        data.avg(i,:) = conv(data.avg(i,:),ones(1,winsize),'same')./winsize;
    end
end

baseline = mean(data.avg(:,data.time >= baseline(1) & data.time <= baseline(2)),2);
data.avg = data.avg - repmat(baseline,1,size(data.avg,2));


