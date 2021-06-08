classdef getpoints < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        DataAcquisitionFolderPathEditFieldLabel  matlab.ui.control.Label
        PathField                matlab.ui.control.EditField
        BrowseButton             matlab.ui.control.Button
        LoadButton               matlab.ui.control.Button
        WarningLabel             matlab.ui.control.Label
        WarningLabel_2           matlab.ui.control.Label
        CamNumber12SpinnerLabel  matlab.ui.control.Label
        CamField                 matlab.ui.control.Spinner
        ClearButton              matlab.ui.control.Button
        Success                  matlab.ui.control.Label
        SelectPointsButton       matlab.ui.control.Button
        WarningLabel_3           matlab.ui.control.Label
        UIAxes                   matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        cam; % Description
        im; % Description
        pts; % Description
        path; % Description
        isLoaded; % Description
        points; % Description
        arePoints; % Description
    end 
    
    methods (Access = private)
        
        function [xvals, yvals] = select_points(app)
            xvals = nan(1,30);
            yvals = nan(1,30);
            for i=1:30
                point = drawpoint(app.UIAxes);
                xvals(i) = round(point.Position(1));
                yvals(i) = round(point.Position(2));
            end
            
        end
        
        function  r = print2file(app)
            xvals = nan(1,30);
            yvals = nan(1,30);
            for i=1:30
                xvals(i) = round(app.points.(['p', num2str(i)]).Position(1));
                yvals(i) = round(app.points.(['p', num2str(i)]).Position(2));
            end
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.cam = app.CamField.Value-1;
            app.path = nan;
            app.isLoaded = 0;
            app.points = nan;
            app.arePoints = 0;
        end

        % Button pushed function: BrowseButton
        function BrowseButtonPushed(app, event)
            app.PathField.Value = uigetdir;
            app.UIFigure.Visible = 'off';
            app.UIFigure.Visible = 'on';
            app.path = app.PathField.Value;
        end

        % Button pushed function: LoadButton
        function LoadButtonPushed(app, event)
            if isnan(app.path)
                app.WarningLabel_2.Text = 'Error: Specify path';
                pause(3)
                app.WarningLabel_2.Text = '';
            else
                folder_contents = dir(app.path);
                m = {folder_contents.name};
                isValid1 = sum(contains(m, ['cam',num2str(app.cam),'.dovi']));
                isValid2 = sum(contains(m, ['cam',num2str(app.cam),'.raw']));
                if (isValid1 > 0) && (isValid2 > 0)
                    app.LoadButton.Text = 'Loading...';
                    pause(0.5)
                    file = ['meas_s0_cam', num2str(app.cam), '.dovi'];
                    app.im = mean(read_dovi(fullfile(app.PathField.Value, file)), 3);
%                     imagesc(app.UIAxes, app.im, 'XData', [1 app.UIAxes.Position(3)], 'YData', [1 app.UIAxes.Position(4)]); 
                    imagesc(app.UIAxes, app.im); 
                    set(app.UIAxes, 'XLim', [0, size(app.im, 2)])
                    set(app.UIAxes, 'YLim', [0, size(app.im, 1)])
                    colormap(app.UIAxes, gray); 
                    app.LoadButton.Text = 'Load';
                    app.isLoaded = 1;
                else
                    app.WarningLabel_2.Text = 'Error: Data not found';
                    pause(3)
                    app.WarningLabel_2.Text = '';
                end
            end
            
        end

        % Value changed function: CamField
        function CamFieldValueChanged(app, event)
            app.cam = app.CamField.Value-1;
        end

        % Value changed function: PathField
        function PathFieldValueChanged(app, event)
            app.path = app.PathField.Value;            
        end

        % Button pushed function: ClearButton
        function ClearButtonPushed(app, event)
            cla(app.UIAxes)
        end

        % Button pushed function: SelectPointsButton
        function SelectPointsButtonPushed(app, event)
            app.WarningLabel_3.Text = '';
            pause(0.5)
            if app.isLoaded
                [xvals, yvals] = select_points(app);
                a = 0:29;
                A = [a; xvals; a; yvals];
                formatSpec = '\nx%d=%d\ny%d=%d';
                fname = 'patternpoints.ini';
                fid = fopen(fullfile(app.path, fname), 'w');
                fprintf(fid,'[General]');
                fprintf(fid,formatSpec, A);
                app.Success.Text = ['Success! File Saved to: ', fullfile(app.path, fname)];
                pause(5)
                app.Success.Text = '';
            else
                app.WarningLabel_3.Text = 'Error: No image loaded';
                pause(3)
                app.WarningLabel_3.Text = '';
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.149 0.149 0.149];
            app.UIFigure.Position = [100 100 757 678];
            app.UIFigure.Name = 'C-Dose Manual Extrinsic Calibration';
            app.UIFigure.Resize = 'off';

            % Create DataAcquisitionFolderPathEditFieldLabel
            app.DataAcquisitionFolderPathEditFieldLabel = uilabel(app.UIFigure);
            app.DataAcquisitionFolderPathEditFieldLabel.HorizontalAlignment = 'right';
            app.DataAcquisitionFolderPathEditFieldLabel.FontColor = [1 1 1];
            app.DataAcquisitionFolderPathEditFieldLabel.Position = [28 644 159 22];
            app.DataAcquisitionFolderPathEditFieldLabel.Text = 'Data Acquisition Folder Path';

            % Create PathField
            app.PathField = uieditfield(app.UIFigure, 'text');
            app.PathField.ValueChangedFcn = createCallbackFcn(app, @PathFieldValueChanged, true);
            app.PathField.Position = [32 615 409 22];

            % Create BrowseButton
            app.BrowseButton = uibutton(app.UIFigure, 'push');
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);
            app.BrowseButton.Position = [464 615 100 22];
            app.BrowseButton.Text = 'Browse';

            % Create LoadButton
            app.LoadButton = uibutton(app.UIFigure, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Position = [33 544 100 22];
            app.LoadButton.Text = 'Load';

            % Create WarningLabel
            app.WarningLabel = uilabel(app.UIFigure);
            app.WarningLabel.FontColor = [1 0.4118 0.1608];
            app.WarningLabel.Position = [243 583 275 22];
            app.WarningLabel.Text = '';

            % Create WarningLabel_2
            app.WarningLabel_2 = uilabel(app.UIFigure);
            app.WarningLabel_2.FontColor = [1 0.4118 0.1608];
            app.WarningLabel_2.Position = [150 544 275 22];
            app.WarningLabel_2.Text = '';

            % Create CamNumber12SpinnerLabel
            app.CamNumber12SpinnerLabel = uilabel(app.UIFigure);
            app.CamNumber12SpinnerLabel.HorizontalAlignment = 'right';
            app.CamNumber12SpinnerLabel.FontColor = [1 1 1];
            app.CamNumber12SpinnerLabel.Position = [32 583 118 22];
            app.CamNumber12SpinnerLabel.Text = 'Cam Number (1,2,...)';

            % Create CamField
            app.CamField = uispinner(app.UIFigure);
            app.CamField.Limits = [1 5];
            app.CamField.ValueChangedFcn = createCallbackFcn(app, @CamFieldValueChanged, true);
            app.CamField.Position = [171 583 52 22];
            app.CamField.Value = 1;

            % Create ClearButton
            app.ClearButton = uibutton(app.UIFigure, 'push');
            app.ClearButton.ButtonPushedFcn = createCallbackFcn(app, @ClearButtonPushed, true);
            app.ClearButton.Position = [33 472 100 22];
            app.ClearButton.Text = 'Clear';

            % Create Success
            app.Success = uilabel(app.UIFigure);
            app.Success.FontColor = [0 1 0];
            app.Success.Position = [46 15 671 22];
            app.Success.Text = '';

            % Create SelectPointsButton
            app.SelectPointsButton = uibutton(app.UIFigure, 'push');
            app.SelectPointsButton.ButtonPushedFcn = createCallbackFcn(app, @SelectPointsButtonPushed, true);
            app.SelectPointsButton.Position = [32 509 100 22];
            app.SelectPointsButton.Text = 'Select Points';

            % Create WarningLabel_3
            app.WarningLabel_3 = uilabel(app.UIFigure);
            app.WarningLabel_3.FontColor = [1 0.4118 0.1608];
            app.WarningLabel_3.Position = [151 509 275 22];
            app.WarningLabel_3.Text = '';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            app.UIAxes.XTick = [];
            app.UIAxes.XTickLabel = '';
            app.UIAxes.YTick = [];
            app.UIAxes.YTickLabel = '';
            app.UIAxes.Box = 'on';
            app.UIAxes.Position = [34 36 692 437];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = getpoints

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end