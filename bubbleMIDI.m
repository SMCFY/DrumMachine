classdef bubbleMIDI < audioPlugin
    % audio plugin for producing bubble sounds

    properties
        r = 0.01; % radius 
        trig = 'noteOff'; % trigger for sound generation
    end
    
    properties (Access = private)
        fs; % sampling rate
        buff; % buffer for generated waveform
        readIndex = 1;
        soundOut = 0;

        % bubble parameters
        N; % signal length      
        a = 1; % initial amplitude 
        eps = 0.25; % epsilon
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(...
           audioPluginParameter('r','DisplayName','Radius','Mapping',{'lin',0.002,0.02}),...
           audioPluginParameter('trig','DisplayName','Trigger','Mapping',{'enum','noteOff','noteOn_'}),...
           'InputChannels',1,'OutputChannels',1);      
    end
%--------------------------------------------------------------------------
    methods
        function obj = bubbleMIDI() % constructor
            obj.fs = (getSampleRate(obj));
            obj.N =(0:1/obj.fs:0.5);
            obj.buff = zeros(length(obj.N),1);
        end                                   
        
        function reset(obj)
            obj.fs = (getSampleRate(obj));
            obj.readIndex = 1;
            obj.soundOut = 0;
        end
        
        function set.r(obj, val) 
            obj.r = val;
        end  
        
        function val = get.r(obj)
            val = obj.r;
        end  
        
        function set.trig(obj, val)
            if val == 'noteOn_'
                obj.readIndex = 1; % init readIndex
                obj.soundOut = 1; % note on
                obj.buff = newBubble(obj.r, obj.N, obj.a, obj.eps)'; % generate waveform
            end
            obj.trig = val;            
        end 
        
        function val = get.trig(obj)
            val = obj.trig;
        end 
        
        function out = process(obj, in) 

             if obj.soundOut == 1
                 if obj.readIndex < length(obj.buff)-length(in) % buffer length not exceeded - output sound
                     out = obj.buff(obj.readIndex:length(in)+obj.readIndex-1); % read from buffer      
                     obj.readIndex = obj.readIndex + length(in); % increment readIndex
                 else % buffer length exceeded - output zeros
                     obj.readIndex = 1; % init readIndex
                     obj.soundOut = 0; % note off
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
function bub = newBubble(r, N, a, eps)
    f0 = 3/r; % fundamental frequency
    d = 0.043 * f0 + 0.0014* f0^(3/2); % decay formula
    sigma = eps*d; % sigma
    ft = f0*(1+sigma*N); % rate of change in frequency over time
    bub = a*sin(2*pi*ft.*N).*exp(-d*N); % calculation of the bubble 
end