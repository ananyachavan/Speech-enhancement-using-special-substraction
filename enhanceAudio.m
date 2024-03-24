function enhancedAudio = enhanceAudio(noisySpeech, sampleRate)
    % Define parameters
    frameSize = 256; % Frame size in samples
    overlap = 128;   % Overlap between frames in samples
    alpha = 5;       % Increased empirical scaling factor (adjust as needed)

    % Initialize variables
    numFrames = floor((length(noisySpeech) - overlap) / (frameSize - overlap));
    enhancedSpeech = zeros(size(noisySpeech));
    
    % Initialize noise spectrum
    noiseSpectrumPrev = zeros(frameSize, 1);

    % Loop through frames
    for i = 1:numFrames
        % Extract current frame
        frameStart = (i - 1) * (frameSize - overlap) + 1;
        frameEnd = frameStart + frameSize - 1;
        frame = noisySpeech(frameStart:frameEnd);

        % Compute the power spectrum of the noisy frame
        noisySpectrum = abs(fft(frame)).^2;

        % Estimate the noise spectrum (assuming the first few frames are noise)
        if i <= 5
            noiseSpectrum = noisySpectrum;
        else
            % Update noise spectrum with a smoothing factor
            noiseSpectrum = alpha * noiseSpectrum + (1 - alpha) * noiseSpectrumPrev;
        end

        % Store the current noise spectrum for the next frame
        noiseSpectrumPrev = noiseSpectrum;

        % Perform spectral subtraction
        enhancedSpectrum = max(noisySpectrum - noiseSpectrum, 0);

        % Reconstruct the enhanced frame
        enhancedFrame = real(ifft(sqrt(enhancedSpectrum) .* exp(1i * angle(fft(frame)))));

        % Overlap and add the enhanced frame to the output signal
        enhancedSpeech(frameStart:frameEnd) = enhancedSpeech(frameStart:frameEnd) + enhancedFrame;
    end

    % Scale the enhanced speech signal to the range [-1, 1]
    enhancedAudio = enhancedSpeech / max(abs(enhancedSpeech));
end