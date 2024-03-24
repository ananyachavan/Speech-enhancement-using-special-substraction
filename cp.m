classdef cp < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = private)
        % Store variables here
    end

    % App components
    properties (Access = public)
        UIFigure               matlab.ui.Figure
        LoadAudioButton        matlab.ui.control.Button
        ThresholdSlider        matlab.ui.control.Slider
        EnhanceButton          matlab.ui.control.Button
        OriginalSpectrogramAxes matlab.ui.control.UIAxes
        EnhancedSpectrogramAxes matlab.ui.control.UIAxes
        ThresholdLabel         matlab.ui.control.Label
        OriginalAudioPlotAxes  matlab.ui.control.UIAxes % New UIAxes for original speech plot
        EnhancedAudioPlotAxes  matlab.ui.control.UIAxes % New UIAxes for enhanced speech plot
    end

    % Add a property to store the loaded audio data
    properties (Access = public)
        originalAudio double % This property will store the loaded audio data
        audioSampleRate double % Store the sample rate of the loaded audio
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, audioFilePath)
            % Default audio file path (change this as needed)
            if nargin < 2
                audioFilePath = 'input_audio.wav';
            end
            app.loadAndPlotAudio(audioFilePath);
        end

        % Load audio and plot the original spectrogram
        function loadAndPlotAudio(app, audioFilePath)
            [audio, sampleRate] = audioread(audioFilePath);
            % Store the audio data for later use
            app.originalAudio = audio;
            app.audioSampleRate = sampleRate;

            % Create the Hamming window with the desired length
            windowLength = 1024;  % Change this to your desired window length
            hammingWindow = hann(windowLength);

            % Create the spectrogram and display it in OriginalSpectrogramAxes
            [~, ~, ~, P] = spectrogram(app.originalAudio, hammingWindow, [], [], sampleRate, 'yaxis');
            imagesc(app.OriginalSpectrogramAxes, 10*log10(P));
            colormap(app.OriginalSpectrogramAxes, 'jet');
            axis(app.OriginalSpectrogramAxes, 'xy');
            xlabel(app.OriginalSpectrogramAxes, 'Time (s)')
            ylabel(app.OriginalSpectrogramAxes, 'Frequency (Hz)')
            title(app.OriginalSpectrogramAxes, 'Original Spectrogram');
        end

        % Button pushed function: LoadAudioButton
        function LoadAudioButtonPushed(app, ~)
            [fileName, filePath] = uigetfile({'*.wav', 'Wave Files (*.wav)'}, 'Select an audio file');
            if fileName
                audioFilePath = fullfile(filePath, fileName);
                app.loadAndPlotAudio(audioFilePath);
            end
        end

        % Value changed function: ThresholdSlider
        function ThresholdSliderValueChanged(app, ~)
            % Implement this function to update the threshold value
            % and possibly update the display accordingly.
        end

        % Button pushed function: EnhanceButton
        function EnhanceButtonPushed(app, ~)
            % Implement this function to apply spectral subtraction
            % and display the enhanced spectrogram.

            % Plot original speech in OriginalAudioPlotAxes
            t_original = (0:(length(app.originalAudio) - 1)) / app.audioSampleRate;
            plot(app.OriginalAudioPlotAxes, t_original, app.originalAudio);
            axis(app.OriginalAudioPlotAxes, 'tight');

            % Perform spectral subtraction and get enhanced audio
            if ~isempty(app.originalAudio)
                enhancedAudio = enhanceAudio(app.originalAudio, app.audioSampleRate);  

                % Plot enhanced speech in EnhancedAudioPlotAxes
                t_enhanced = (0:(length(enhancedAudio) - 1)) / app.audioSampleRate;
                plot(app.EnhancedAudioPlotAxes, t_enhanced, enhancedAudio);
                axis(app.EnhancedAudioPlotAxes, 'tight');

                % Save the enhanced audio to a file
                outputFileName = 'D:/dsp/speech enhancement/output_audiocheck.net_pinknoise.wav';  % Change the filename as needed
                audiowrite(outputFileName, enhancedAudio, app.audioSampleRate);

                
                % Create the spectrogram for the enhanced audio and display it
                windowLength = 1024;  % Change this to your desired window length
                hammingWindow = hamming(windowLength);
                [~, ~, ~, P] = spectrogram(enhancedAudio, hammingWindow, [], [], app.audioSampleRate, 'yaxis');
                imagesc(app.EnhancedSpectrogramAxes, 10*log10(P));
                colormap(app.EnhancedSpectrogramAxes, 'jet');
                axis(app.EnhancedSpectrogramAxes, 'xy');
                xlabel(app.EnhancedSpectrogramAxes, 'Time (s)')
                ylabel(app.EnhancedSpectrogramAxes, 'Frequency (Hz)')
                title(app.EnhancedSpectrogramAxes, 'Enhanced Spectrogram');
            end
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct the app
        function app = cp
            % Create and configure components
            app.createComponents();

            % Properties setup
            app.originalAudio = [];
            app.audioSampleRate = 0;
        end

        % Create UIFigure and components
        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure('Name', 'Speech Enhancement');
            app.UIFigure.Position = [100, 100, 800, 600];
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @appCloseRequest, true);
            
            % Add a title at the top
            app.UIFigure.Name = 'Speech Enhancement using Spectral Subtraction Method';
            
            % Create LoadAudioButton
            app.LoadAudioButton = uibutton(app.UIFigure, 'push');
            app.LoadAudioButton.Position = [50, 500, 100, 30];
            app.LoadAudioButton.Text = 'Load Audio';
            app.LoadAudioButton.ButtonPushedFcn = createCallbackFcn(app, @LoadAudioButtonPushed, true);

            % Create ThresholdSlider
            app.ThresholdSlider = uislider(app.UIFigure);
            app.ThresholdSlider.Position = [200, 550, 200, 3];
            app.ThresholdSlider.Limits = [0, 1];
            app.ThresholdSlider.Value = 0.1;
            app.ThresholdSlider.MajorTicks = [0, 0.25, 0.5, 0.75, 1];
            app.ThresholdSlider.MajorTickLabels = {'0', '0.25', '0.5', '0.75', '1'};
            app.ThresholdSlider.ValueChangedFcn = createCallbackFcn(app, @ThresholdSliderValueChanged, true);

            % Create EnhanceButton
            app.EnhanceButton = uibutton(app.UIFigure, 'push');
            app.EnhanceButton.Position = [450, 500, 100, 30];
            app.EnhanceButton.Text = 'Enhance';
            app.EnhanceButton.ButtonPushedFcn = createCallbackFcn(app, @EnhanceButtonPushed, true);

            % Create OriginalSpectrogramAxes
            app.OriginalSpectrogramAxes = uiaxes(app.UIFigure);
            app.OriginalSpectrogramAxes.Position = [50, 300, 400, 180];
            xlabel(app.OriginalSpectrogramAxes, 'Time (s)')
            ylabel(app.OriginalSpectrogramAxes, 'Frequency (Hz)')
            title(app.OriginalSpectrogramAxes, 'Original Spectrogram');
            
            % Create EnhancedSpectrogramAxes
            app.EnhancedSpectrogramAxes = uiaxes(app.UIFigure);
            app.EnhancedSpectrogramAxes.Position = [450, 300, 400, 180];
            xlabel(app.EnhancedSpectrogramAxes, 'Time (s)')
            ylabel(app.EnhancedSpectrogramAxes, 'Frequency (Hz)')
            title(app.EnhancedSpectrogramAxes, 'Enhanced Spectrogram');
            
            % Create OriginalAudioPlotAxes
            app.OriginalAudioPlotAxes = uiaxes(app.UIFigure);
            app.OriginalAudioPlotAxes.Position = [50, 100, 400, 180];
            xlabel(app.OriginalAudioPlotAxes, 'Time (s)')
            ylabel(app.OriginalAudioPlotAxes, 'Amplitude')
            title(app.OriginalAudioPlotAxes, 'Original Speech');

            % Create EnhancedAudioPlotAxes
            app.EnhancedAudioPlotAxes = uiaxes(app.UIFigure);
            app.EnhancedAudioPlotAxes.Position = [450, 100, 400, 180];
            xlabel(app.EnhancedAudioPlotAxes, 'Time (s)')
            ylabel(app.EnhancedAudioPlotAxes, 'Amplitude')
            title(app.EnhancedAudioPlotAxes, 'Enhanced Speech');

            % Create ThresholdLabel
            app.ThresholdLabel = uilabel(app.UIFigure);
            app.ThresholdLabel.Position = [200, 500, 200, 30];
            app.ThresholdLabel.Text = ['Threshold: ', num2str(app.ThresholdSlider.Value)];
        end

        % Code that executes before app deletion
        function appCloseRequest(app, ~)
            delete(app.UIFigure);
        end
    end
end