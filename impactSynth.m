classdef impactSynth < audioPlugin
    % audio plugin for producing bubble sounds

    properties
        % interfaced parameters
        strikePos = 1;
        strikeVig = 1;
        dimension = 1;
        material = 1;

        instID = 1; % instrument ID
    end
    
    properties (Dependent)
        trig = 'noteOff'; % noteState
    end
    
    properties (Access = private)
        % vst parameters
        fs; % sampling rate
        buff; % buffer for generated waveform
        t = 0.5; % buffer length in seconds
        N; % buffer in samples
        buffSum; % sum of all buffers (output frame)
        readIndex = [1, 1, 1, 1]; % reading position in buffers
        noteState = 'noteOff'; % note state
        soundOut = [0, 0, 0, 0]; % state variable decides whether to output the signal from the buffer or not

        %=================================== synth parameters
        modes = [];
        %===================================
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(...
           audioPluginParameter('strikePos','DisplayName','StrikingPosition','Mapping',{'lin',0,1}),...
           audioPluginParameter('strikeVig','DisplayName','StrikeVigor','Mapping',{'lin',0,1}),...
           audioPluginParameter('dimension','DisplayName','Dimension','Mapping',{'lin',0,1}),...
           audioPluginParameter('material','DisplayName','Material','Mapping',{'lin',0,1}),...
           audioPluginParameter('instID','DisplayName','ID','Mapping',{'int',1,4}),...
           audioPluginParameter('trig','DisplayName','Trigger','Mapping',{'enum','noteOff','noteOn_'}),...
           'InputChannels',1,'OutputChannels',1);      
    end
%--------------------------------------------------------------------------
    methods
        function obj = impactSynth() % constructor
            obj.fs = (getSampleRate(obj));
            obj.N = (0:1/obj.fs:obj.t); % number of samples length in seconds
            obj.buff = [zeros(1,length(obj.N));
                        zeros(1,length(obj.N));
                        zeros(1,length(obj.N));
                        zeros(1,length(obj.N))];
            obj.bufSum = zeros(1,length(obj.N));
        end                                   
        
        function reset(obj)
            obj.fs = (getSampleRate(obj));
            obj.readIndex = [1, 1, 1, 1];
            obj.soundOut = [0, 0, 0, 0];
        end 
        
        function set.trig(obj, val)
            if val == 'noteOn_'
                obj.readIndex(1,obj.instID) = 1; % init readIndex of respective buffer
                obj.soundOut(1,obj.instID) = 1; % trigger sound according to instrument ID

                if obj.instID == 1
                    fprintf('tom')
                    %=================================== sound synthesis
                    obj.buff(1,:) = bands(220, obj.N) + mesh(330, obj.N); % synthesis
                    %===================================
                elseif obj.instID == 2
                    fprintf('snare')
                    %=================================== sound synthesis
                    obj.buff(1,:) = bands(440, obj.N) + mesh(442, obj.N)'; % synthesis
                    %===================================
                elseif obj.instID == 3
                    fprintf('cymbal')
                    %=================================== sound synthesis
                    obj.buff(1,:) = bands(350, obj.N) + mesh(700, obj.N)'; % synthesis
                    %=================================== 
                else
                    fprintf('kick')
                    %=================================== sound synthesis
                    obj.buff(1,:) = bands(120, obj.N) + mesh(180, obj.N)'; % synthesis
                    %===================================
                end
            end
            buffSum = obj.buff(1,:) * obj.soundOut(1,1)...
                    + obj.buff(2,:) * obj.soundOut(1,2)...
                    + obj.buff(3,:) * obj.soundOut(1,2)...
                    + obj.buff(4,:); % sum of all buffers
            obj.noteState = val;
        end 
        
        function val = get.trig(obj)
            val = obj.noteState;
        end 
        
        function out = process(obj, in) 

            %if obj.soundOut == 'true_' 
            for i=1:length(obj.soundOut)    
                if obj.readIndex(1,i) < length(obj.buff(i,:)) - length(in) % buffer length not exceeded - output sound
                    out = obj.buff(i,obj.readIndex(1,i):length(in)+obj.readIndex(1,i)-1)... % read from buffer
                    * obj.soundOut(1,i); % applying state variable
                    obj.readIndex(1,i) = obj.readIndex(1,i) + length(in); % increment readIndex
                else % buffer length exceeded - output zeros
                    obj.readIndex(1,i) = 1; % init readIndex
                    obj.soundOut(1,i) = 0;
                    out = zeros(length(in),1);
                end
            end    
            %else

                %out = zeros(length(in),1);
                
            %end
            
        end  
    end
%--------------------------------------------------------------------------
    methods (Static)        
        function configureMIDI(obj,varargin)
            % Configure MIDI connections.
            
            privConfigureMIDI(obj,varargin{:});
        end
        
        function C = getMIDIConnections(obj)
            % Get MIDI connections. 
        
            C = privConfigureMIDI('getConnections',obj);
        end
        
        function disconnectMIDI(obj)
            % Disconnect MIDI controls.
         
            privConfigureMIDI('disconnect',obj);       
        end
    end
end
%--------------------------------------------------------------------------
%=================================== synth functions
function out = bands(freq, time)
    out = sin(2*pi*freq*time); 
end
function out = mesh(freq, time)
    out = sin(2*pi*freq*time); 
end
%===================================