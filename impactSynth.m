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
        readIndex = [1; 1; 1; 1]; % reading position in buffers
        soundOut = [0; 0; 0; 0]; % state variable decides whether to output the signal from the buffer or not

        frameBuff; % buffer for output frame
        maxFrameSize; % maximum frame size in samples

        noteState = 'noteOff'; % trig

        %=================================== synth parameters
        modes = [180, 400, 600, 1250];
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
            obj.fs = getSampleRate(obj);
            obj.maxFrameSize = 16384; % 2^14
            obj.N = (0:1/obj.fs:obj.t); % number of samples length in seconds
            obj.buff = [zeros(1,length(obj.N));
                        zeros(1,length(obj.N));
                        zeros(1,length(obj.N));
                        zeros(1,length(obj.N))];
            obj.frameBuff = zeros(1,obj.maxFrameSize);
        end                                   
        
        function reset(obj)
            obj.fs = (getSampleRate(obj));
            obj.maxFrameSize = 16384;
            obj.readIndex = [1; 1; 1; 1];
            obj.soundOut = [0; 0; 0; 0];
        end 
        
        function set.trig(obj, val)
            if val == 'noteOn_'
                obj.readIndex(obj.instID) = 1; % init readIndex of respective buffer
                obj.soundOut(obj.instID) = 1; % trigger sound according to instrument ID

                %=================================== sound synthesis
                obj.buff(obj.instID,:) = bands(obj.modes(obj.instID), obj.N)'; % synthesis
                %===================================

            end

            obj.noteState = val;
        end 
        
        function val = get.trig(obj)
            val = obj.noteState;
        end 
        
        function out = process(obj, in) 
            %if length(in) ~= obj.frameSize
            %    obj.frameSize = length(in);
            %end
            obj.frameBuff = zeros(1,length(obj.frameBuff));

            for i=1:length(obj.soundOut)    
                if obj.readIndex(i) < length(obj.buff(i,:)) - length(in) % buffer length not exceeded - output sound
                    
                    obj.frameBuff(1:length(in)) = obj.frameBuff(1:length(in)) + obj.buff(i,obj.readIndex(i):obj.readIndex(i)+(length(in)-1))... % read from synth buffer and add it to the frame buffer
                    * obj.soundOut(i); % applying state variable

                    obj.readIndex(i) = obj.readIndex(i) + length(in); % increment readIndex

                else % buffer length exceeded - output zeros

                    obj.readIndex(i) = 1; % init readIndex
                    obj.soundOut(i) = 0;

                    obj.frameBuff(1:length(in)) = obj.frameBuff(1:length(in)) + zeros(1,length(in));
                end
            end    

                out = obj.frameBuff(1:length(in))'; % output

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