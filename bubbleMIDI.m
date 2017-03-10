classdef bubbleMIDI < audioPlugin
    % audio plugin for producing bubble sounds

    properties
        r = 0.01; % radius 
    end
    
    properties (Access = private)
        fs; % sampling rate
        buff; % buffer for generated waveform
        readIndex = 1;

        % bubble parameters
        N; % signal length      
        a = 1; % initial amplitude 
        eps = 0.25; % epsilon
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(audioPluginParameter...
           ('r','DisplayName','Radius','Mapping',{'lin',0.002,0.02}),...
           'InputChannels',1,'OutputChannels',1);      
    end
%--------------------------------------------------------------------------
    methods
        function obj = bubbleMIDI() % constructor
            obj.fs = (getSampleRate(obj));
            obj.N =(0:1/obj.fs:0.5);
            obj.buff = zeros(length(obj.N),1);
            %setupMIDIControls(obj);
        end
         
        function out = process(obj, in) 

            if obj.readIndex > length(obj.buff)-length(in) % init readIndex
                obj.readIndex = 1;
            end
            
            out = obj.buff(obj.readIndex:length(in)+obj.readIndex-1); % read from buffer
            
            obj.readIndex = obj.readIndex + length(in); % increment readIndex
        end                             
        
        function reset(obj)
            obj.fs = (getSampleRate(obj));
            obj.readIndex = 1;
        end
        
        function set.r(obj, val)
            obj.r = val;
            obj.buff = newBubble(val, obj.N, obj.a, obj.eps)';
        end  
        
        function val = get.r(obj)
            val = obj.r;
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
function bub = newBubble(r, N, a, eps)
    f0 = 3/r; % fundamental frequency
    d = 0.043 * f0 + 0.0014* f0^(3/2); % decay formula
    sigma = eps*d; % sigma
    ft = f0*(1+sigma*N); % rate of change in frequency over time
    bub = a*sin(2*pi*ft.*N).*exp(-d*N); % calculation of the bubble 
end
%--------------------------------------------------------------------------
% function setupMIDIControls(obj)
% configureMIDI(obj,'r',1048,'DeviceName','APC Key 25');
% end