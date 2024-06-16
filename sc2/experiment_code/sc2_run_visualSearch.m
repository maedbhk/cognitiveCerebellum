function [T, score] = sc2_run_visualSearch(screen,keyNames,T)

global TRreal timeOfTR;

%% super_cerebellum project 
% Maedbh King, Rich Ivry & Joern Diedrichsen (2017)

% Visual Search Task

% Input variables:
% screen - output arg from 'sc2_psychtoolbox_config'
% keyNames - output arg from 'sc2_psychtoolbox_config'
% T - target file containing task-relevant information

% Output variables: 
% T - task information to be saved (added to input structure, T)
% score - feedback (numerical or qualitative - depending on the task)

%% Display Instructions

if  (nargin < 3 || isempty(T)) && isempty(keyNames{5}),
    DrawFormattedText(screen.window, sprintf('Visual Search Task! \n\n Use your LEFT hand \n\n Press "%s" when you see L \n\n Otherwise press "%s"',keyNames{2},keyNames{1}), ...
        'center', 'center', screen.black);
    Screen('Flip', screen.window);
    return;
elseif (nargin<3 || isempty(T)) && ~isempty(keyNames{5}),
    DrawFormattedText(screen.window, sprintf('Visual Search Task! \n\n Use your LEFT hand \n\n Press "%s" when you see L \n\n Otherwise press "%s" \n\n %s',keyNames{2},keyNames{1},keyNames{5}), ...
        'center', 'center', screen.black);
    Screen('Flip', screen.window);
    return;
end;

% Read in stimuli
imTarg = imread(char(T.letter(1)));
imDist = imread(char(T.letter(end)));

% Number of trials
numTrials = length(T.startTime);

% Start the trial
t0 = GetSecs;

%% Begin Experimental Loop

for trial = 1:numTrials,
    
    targetPresent = T.trialType(trial);
    
    % Make search display
    img = makeSearchDisplay(imTarg,imDist,T.setSize(trial),targetPresent,T.rotateDistractor(trial),screen.grey,screen.height-50,screen.width-100); % rotateDistractor can also be included here
    imageDisplay = Screen('MakeTexture', screen.window, img);
    
    % Calculate image position (center of the screen)
    imageSize = size(img);
    pos = [(screen.width-imageSize(2))/2 (screen.height-imageSize(1))/2 (screen.width+imageSize(2))/2 (screen.height+imageSize(1))/2];
    
    % Before trial starts
    while GetSecs-t0 <= T.startTime(trial);
        checkTR(screen);
    end;
    
    % Start the trial
    T.startTimeReal(trial,1) = GetSecs-t0;
    T.startTRreal(trial,1) = TRreal;
    T.timeOfTR(trial,1) = timeOfTR-t0;
    
    % Set up counter
    respMade = false;
    rt = 0;
    numCorr = 0;
    numErr = 0;
    response = 0;
    
    % Set up variables
    T.rt(trial,1) = 0;
    T.numCorr(trial,1) = 0;
    T.numErr(trial,1) = 0;
    T.respMade(trial,1) = 0;
    T.numTrial(trial,1) = trial;
    
    % Start timer
    t2 = GetSecs;
    
    % Show the search display
    Screen('DrawTexture',screen.window, imageDisplay, [], pos);
    Screen('Flip', screen.window);
    
    while GetSecs-t0 <= T.startTime(trial)+T.trialDur(trial);
        checkTR(screen);
        % Check the keyboard.
        [isPressed, ~, keyCode] = KbCheck(screen.keyBoard); % query specific keyboards
        if keyCode(screen.escapeKey)
            ShowCursor;
            sca;
            return
        end;
        
        if (~respMade && isPressed && (keyCode(screen.one) || keyCode(screen.two)))
            if keyCode(screen.two)
                t1 = GetSecs;
                rt = t1 - t2;
                respMade=true;
                response = 1;
            elseif keyCode(screen.one)
                t1 = GetSecs;
                rt = t1 - t2;
                respMade=true;
                response = 2;
            end
            
            %% Record the data
            % Record rt
            T.rt(trial,1) = rt;
            if (targetPresent==1),
                if (response==1)
                    numCorr = numCorr+1;
                    T.numCorr(trial,1) = numCorr;
                    Screen('DrawTexture',screen.window, imageDisplay, [], pos);
                    Screen('Flip', screen.window)
                    % Give feedback
                    % Display correct
                    Screen('DrawTexture',screen.window, imageDisplay, [], pos);
                    makeSquare(screen, numCorr)
                elseif (response == 2),
                    % Display incorrect
                    T.numErr(trial,1) = numErr+1;
                    Screen('DrawTexture',screen.window, imageDisplay, [], pos);
                    makeSquare(screen, numCorr)
                end;
            end;
            if (targetPresent==2),
                if (response==1)
                    % Display incorrect
                    T.numErr(trial,1) = numErr+1;
                    Screen('DrawTexture',screen.window, imageDisplay, [], pos);
                    makeSquare(screen, numCorr)
                elseif (response==2),
                    numCorr = numCorr+1;
                    T.numCorr(trial,1) = numCorr;
                    % Display correct
                    Screen('DrawTexture',screen.window, imageDisplay, [], pos);
                    makeSquare(screen, numCorr)
                end;
            end
        end
    end
    
    % Draw fixation cross
    DrawFormattedText(screen.window, '+','center', 'center', screen.black); %fixation cross in center
    Screen('Flip', screen.window);
    
    T.respMade(trial,1) = respMade;
end

score = round(sum((T.numCorr))*100/length(T.numCorr));