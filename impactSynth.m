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
        t = 4; % buffer length in seconds
        N; % buffer in samples
        readIndex = [1; 1; 1; 1]; % reading position in buffers
        soundOut = [0; 0; 0; 0]; % state variable decides whether to output the signal from the buffer or not

        frameBuff; % buffer for output frame
        maxFrameSize; % maximum frame size in samples

        noteState = 'noteOff'; % trig

        %=================================== synth parameters
        modes = [112, 203, 259, 279, 300, 332, 345, 375, 398, 407, 450, 473, 488, 488, 547, 596,...
                 625, 653, 679, 692, 705, 760, 773, 806, 852, 899, 924, 975, 998, 1019, 1046, 1109,...
                 1134, 1164, 1192, 1226, 1309, 1358, 1379, 1411, 1461, 1532, 1610, 1683, 1758, 1880,...
                 2027, 2131, 2271, 2515, 2731, 2809, 2922, 3224, 4694, 5563, 6655, 7072];

        pitchRange = 100; % pitch range mapped to dimension 
        lpfPole = 0.5; % lowpass filter pole radius - loss filter damping
        excGain = 0.5; % gain coefficient for the excitation
        strikeGain; % gain coefficient for each mode
        m = 0; % slope of transfer fuction
        %===================================
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(...
           audioPluginParameter('strikePos','DisplayName','StrikePosition','Mapping',{'lin',0,1}),...
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
            obj.strikeGain = ones(1,length(obj.modes(1,:)));
        end                                   
        
        function reset(obj)
            obj.readIndex = [1; 1; 1; 1];
            obj.soundOut = [0; 0; 0; 0];
        end 
        
        function set.trig(obj, val)
            if val == 'noteOn_'
                obj.readIndex(obj.instID) = 1; % init readIndex of respective buffer
                obj.soundOut(obj.instID) = 1; % trigger sound according to instrument ID

                %=================================== sound synthesis
                
                obj.modes = obj.modes + (obj.dimension-0.5) * obj.pitchRange; % dimension
                obj.lpfPole = abs(obj.material-0.001); % material
                obj.excGain = obj.strikeVig; % strike vigor
                obj.m = (obj.strikeGain(length(obj.strikeGain))-obj.strikePos) / (length(obj.strikeGain)-1);
                obj.strikeGain = obj.m * [1:length(obj.strikeGain)] + obj.strikePos - obj.m; % (y=mx+b) strike postion
                disp(obj.strikeGain);
                obj.buff(obj.instID,:) = bands(obj.modes(1,obj.instID), obj.N)'; % synthesis
                %===================================

            end

            obj.noteState = val;
        end 
        
        function val = get.trig(obj)
            val = obj.noteState;
        end 
        
        function out = process(obj, in) 

            obj.frameBuff = zeros(1,length(obj.frameBuff)); % init frame buffer

            for i=1:length(obj.buff(:,1)) % iteration through instruments
                if obj.readIndex(i) < length(obj.buff(i,:)) - length(in) % buffer length not exceeded(&& soundOut == 1) - add signal
                    
                    obj.frameBuff(1:length(in)) = obj.frameBuff(1:length(in))...
                    + obj.buff(i,obj.readIndex(i):obj.readIndex(i)+(length(in)-1))... % read from synth buffer, write to frame buffer
                    * obj.soundOut(i); % applying state variable

                    obj.readIndex(i) = obj.readIndex(i) + length(in); % increment readIndex

                else % buffer length exceeded - add zeros

                    obj.readIndex(i) = 1; % init readIndex
                    obj.soundOut(i) = 0;

                    obj.frameBuff(1:length(in)) = obj.frameBuff(1:length(in)) + zeros(1,length(in));
                end
            end    

                out = (obj.frameBuff(1:length(in)) / max(obj.frameBuff(1:length(in))))'; % normalized output

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