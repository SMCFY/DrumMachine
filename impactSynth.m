classdef impactSynth < audioPlugin
    % audio plugin for producing bubble sounds

    properties
        %=================================== interfaced parameters
        strikePos = 1;
        strikeVig = 1;
        dimension = 1;
        material = 1;

        instID = 1; % instrument ID

        %===================================
    end
    
    properties (Dependent)
        trig = 'noteOff'; % noteState
    end
    
    properties (Access = private)
        % vst parameters
        fs; % sampling rate
        buff; % buffer for generated waveform
        N; % buffer length
        readIndex = [1, 1, 1, 1]; % reading position in buffers
        noteState = 'noteOff'; % note state
        soundOut = 'false'; % state variable decides whether to output the signal or not

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
           audioPluginParameter('instID','DisplayName','ID','Mapping',{'lin',0,3}),...
           audioPluginParameter('trig','DisplayName','Trigger','Mapping',{'enum','noteOff','noteOn_'}),...
           'InputChannels',1,'OutputChannels',1);      
    end
%--------------------------------------------------------------------------
    methods
        function obj = impactSynth() % constructor
            obj.fs = (getSampleRate(obj));
            obj.N =(0:1/obj.fs:0.5);
            obj.buff = [zeros(length(obj.N),1);
                        zeros(length(obj.N),1);
                        zeros(length(obj.N),1);
                        zeros(length(obj.N),1)];
        end                                   
        
        function reset(obj)
            obj.fs = (getSampleRate(obj));
            obj.readIndex = [1, 1, 1, 1];
            obj.soundOut = 'false';
        end 
        
        function set.trig(obj, val)
            if val == 'noteOn_' && obj.instID == 0
                obj.readIndex(1,1) = 1; % init readIndex 
                obj.soundOut = 'true_';
print('tom')
                %=================================== sound synthesis
                %obj.buff(1,:) = bands(inp)+mesh(inp)'; % synthesis
                %===================================
            end
            obj.noteState = val;
        end 
        
        function val = get.trig(obj)
            val = obj.noteState;
        end 
        
        function out = process(obj, in) 

             if obj.soundOut == 'true_' 
                 if obj.readIndex < length(obj.buff)-length(in) % buffer length not exceeded - output sound
                     out = obj.buff(obj.readIndex:length(in)+obj.readIndex-1); % read from buffer      
                     obj.readIndex = obj.readIndex + length(in); % increment readIndex
                 else % buffer length exceeded - output zeros
                     obj.readIndex = 1; % init readIndex
                     obj.soundOut = 'false';
                     out = zeros(length(in),1);
                 end
             else
                 out = zeros(length(in),1);
                
             end
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
function out = bands(inp)
    out = inp; 
end
function out = mesh(inp)
    out = inp; 
end
%===================================