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
        t = 2; % buffer length in seconds
        readIndex = [1; 1; 1; 1]; % reading position in buffers
        soundOut = [0; 0; 0; 0]; % state variable decides whether to output the signal from the buffer or not

        frameBuff; % buffer for output frame
        maxFrameSize; % maximum frame size in samples

        noteState = 'noteOff'; % trig

        %=================================== synth parameters
        modes = [112, 203, 259, 279, 300, 332, 345, 375, 398, 407, 450, 473, 488, 488, 547, 596,...
                 625, 653, 679, 692, 705, 760, 773, 806, 852, 899, 924, 975, 998, 1019, 1046, 1109,...
                 1134, 1164, 1192, 1226, 1309, 1358, 1379, 1411, 1461, 1532, 1610, 1683, 1758, 1880,...
                 2027, 2131, 2271, 2515, 2731, 2809, 2922, 3224, 4694];
        decay = [0.9999 0.9999 0.9998 0.9998 0.9998 0.9997 0.9997 0.9996 0.9996 0.9995...
                 0.9995 0.9994 0.9994 0.9993 0.9993 0.9992 0.9992 0.9991 0.9991 0.999 0.999...
                 0.998 0.998 0.997 0.997 0.996 0.996 0.995 0.995 0.994 0.994 0.993...
                 0.993 0.992 0.992 0.991 0.991 0.991 0.991 0.991 0.991 0.991 0.991 0.991 0.99...
                 0.993 0.992 0.991 0.99 0.98 0.98 0.98 0.97 0.97 0.97];
        
        lpfPole = 0.5; % lowpass filter pole radius - loss filter damping
        excGain = 0.5; % gain coefficient for the excitation
        strikeGain; % gain coefficient for each mode
        m = 0; % slope of transfer fuction
        
        resBank = [audioread('Analyses/tom_res.wav')'; % extracted residuals
                   audioread('Analyses/snare_res.wav')';
                   audioread('Analyses/cymbal_res.wav')';
                   audioread('Analyses/kick_res.wav')'];
        resPadded; % zero padded residuals
        %===================================
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(...
           audioPluginParameter('strikePos','DisplayName','StrikePosition','Mapping',{'lin',0,1}),...
           audioPluginParameter('strikeVig','DisplayName','StrikeVigor','Mapping',{'lin',0,1}),...
           audioPluginParameter('dimension','DisplayName','Dimension','Mapping',{'lin',0.5,1.5}),...
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
            obj.buff = [zeros(1,obj.fs*obj.t);
                        zeros(1,obj.fs*obj.t);
                        zeros(1,obj.fs*obj.t);
                        zeros(1,obj.fs*obj.t)];
            obj.frameBuff = zeros(1,obj.maxFrameSize);
            obj.strikeGain = ones(1,length(obj.modes(1,:)));
            obj.resPadded = [obj.resBank(1,:), zeros(1, obj.fs*obj.t-length(obj.resBank(1,:)));
                             obj.resBank(2,:), zeros(1, obj.fs*obj.t-length(obj.resBank(2,:)));
                             obj.resBank(3,:), zeros(1, obj.fs*obj.t-length(obj.resBank(3,:)));
                             obj.resBank(4,:), zeros(1, obj.fs*obj.t-length(obj.resBank(4,:)));];
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
                
                obj.lpfPole = abs(obj.material-0.001); % material
                obj.excGain = obj.strikeVig; % strike vigor
                obj.m = (obj.strikeGain(length(obj.strikeGain))-obj.strikePos) / (length(obj.strikeGain)-1);
                obj.strikeGain = obj.m * [1:length(obj.strikeGain)] + obj.strikePos - obj.m; % (y=mx+b) strike postion
                
                obj.buff(obj.instID,:) = f_bdwg(obj.modes(1:24)*obj.dimension, obj.decay(1:24), length(obj.buff(1,:)), obj.fs, [0.999; 1.001], 0.9, obj.strikeGain)'; % banded waveguide
                % waveguide mesh
                obj.buff(obj.instID,:) = real(ifft(fft(obj.buff(obj.instID,:)) .* fft(obj.resPadded(obj.instID,:)))); % convolution with residual (multiplication of spectrums)
                obj.buff(obj.instID,:) = obj.buff(obj.instID,:) / max(obj.buff(obj.instID,:)); % normalisation
                %===================================

            end

            obj.noteState = val;
        end 
        
        function val = get.trig(obj)
            val = obj.noteState;
        end 
        
        function out = process(obj, in) 
            
            if sum(obj.soundOut)>0 % do not process if all state variables are false
                for i=1:length(obj.soundOut) % iteration through synth buffers
                    if obj.readIndex(i) < length(obj.buff(i,:)) - length(in) % buffer length not exceeded - add wavefrom
                        
                        obj.frameBuff(1:length(in)) = obj.frameBuff(1:length(in))...
                        + obj.buff(i,obj.readIndex(i):obj.readIndex(i)+(length(in)-1))... % read from synth buffer, write to frame buffer
                        * obj.soundOut(i); % applying state variable (only adding active instruments)
    
                        obj.readIndex(i) = obj.readIndex(i) + length(in); % increment readIndex by frame size
    
                    else % buffer length exceeded - add zeros  
                        obj.readIndex(i) = 1; % init readIndex
                        obj.soundOut(i) = 0;
                    end
                end    
            end
            
            out = (obj.frameBuff(1:length(in))*obj.excGain)'; % output
            obj.frameBuff = zeros(1,length(obj.frameBuff)); % clear frame buffer

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

function out = f_bdwg( freqs, decay, Tsamp, fs, low_high, damp, bandCoeff)
    % Banded digital waveguide function
    
    %% variables
    n_modes = length(freqs); % number of modes
    d = zeros(1, n_modes); % length of delay lines (Samples)
    for i = 1:n_modes
        d(i) = floor(fs/freqs(i));
    end
    
    %% initialization
    
    L = rand(1, max(d)); % initialize delay lines with white noise
    L = L - mean(L);
    L = L/max(L);
    L = repmat(L,n_modes,1);

    out = zeros(1, Tsamp); % output
    
    p_out = 3*ones(1,n_modes); % pointers out      (see shift register)
    p_out1 = 2*ones(1,n_modes);
    p_out2 = 1*ones(1,n_modes);
    %p_out3 = 1*ones(1,n_modes);
    p_in = 6*ones(1,n_modes); % pointers in
    p_in1 = 5*ones(1,n_modes);
    p_in2 = 4*ones(1,n_modes);
    
    %% bandpass according to paper (following Steiglitz's DSP book, 1996)
    
    f_low_high = low_high*freqs;
    B = f_low_high(2,:) - f_low_high(1,:); % bandwidth
    % B = B';
    B_rad = 2*pi/fs*B; % bandwidth in radians/samp
    psi = 2*pi/fs*freqs; % center frequencies in radians/samp
    R = 1 - B_rad/2;
    cosT = 2*R/(1+R.^2) * cos(psi);
    A0 = (1-R.^2)/2; % normalization scale factor or gain adjustment
    % A0 = sqrt(A0);
    
    % a and b coefficients
    a = zeros(n_modes, 3);
    b = zeros(n_modes, 3);
    for i = 1:n_modes
        b(i,:) = [A0(i), 0, -A0(i)]; % b coeff dependent of scaling gain factor
        a(i,:) = [1, -2*R(i)*cosT(i), R(i)^2]; % a coeff depending on R and cosT     
    end
    
    % a = zeros(n_modes, 4);
    % b = zeros(n_modes, 3);
    % for i = 1:n_modes
    %     u = 2*R(i)*cosT(i);
    %     v = R(i)^2;
    %     b(i,:) = [A0(i)*(1-damp), 0, -A0(i)*(1-damp)]; % b coeff dependent of scaling gain factor
    %     a(i,:) = [1, -(u+damp), v+u*damp, -v*damp]; % a coeff depending on R and cosT     
    % end
    
    
    %% main loop
    
    for i=1:Tsamp
        
        out(i) = 0;
        
        for j = 1:n_modes
            
            % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
            L(j, p_out(j)) = decay(j) * (b(j,1)*L(j, p_in(j)) + ...                               % b(j,2)*L(j, p_in1(j))... (=0)
                + b(j,3)*L(j, p_in2(j)) - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)));
            
    %         L(j, p_out(j)) = b(j,1)*L(j, p_in(j)) + b(j,3)*L(j, p_in2(j))...                      % b(j,2)*L(j, p_in1(j))... (=0)
    %              - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)) - a(j,4)*L(j, p_out3(j));
            
            out(i) = out(i) + L(j,p_out(j))*bandCoeff(j);
            
            % update and wrap pointers
            if (p_in(j)==d(j))
                p_in(j)=1;
            else
                p_in(j)=p_in(j)+1;
            end
            if (p_in1(j)==d(j))
                p_in1(j)=1;
            else
                p_in1(j)=p_in1(j)+1;
            end
            if (p_in2(j)==d(j))
                p_in2(j)=1;
            else
                p_in2(j)=p_in2(j)+1;
            end
            if (p_out(j)==d(j))
                p_out(j)=1;
            else
                p_out(j)=p_out(j)+1;
            end
            if (p_out1(j)==d(j))
                p_out1(j)=1;
            else
                p_out1(j)=p_out1(j)+1;
            end
            if (p_out2(j)==d(j))
                p_out2(j)=1;
            else
                p_out2(j)=p_out2(j)+1;
            end
    %         if (p_out3(j)==d(j))
    %             p_out3(j)=1;
    %         else
    %             p_out3(j)=p_out3(j)+1;
    %         end
            
        end
        
    end
    out = out / max(out);
    
end
%===================================