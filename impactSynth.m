classdef impactSynth < audioPlugin
    % audio plugin for producing bubble sounds

    properties
        % interfaced parameters
        strikePos = 1;
        strikeVig = 1;
        dimension = 1;
        material = 0;

        paramID = 1; % parameter ID (selected instrument)
        instID = 1; % instrument ID (triggered instrument)
    end
    
    properties (Dependent)
        trig = 'noteOff'; % noteState
    end
    
    properties (Access = private)
        % vst parameters
        fs; % sampling rate
        
        buff; % buffer for generated waveform
        t = 2; % buffer length in seconds
        readIndex = ones(4,1); % reading position in buffers
        soundOut = zeros(4,1); % state variable decides whether to output the signal from the buffer or not

        frameBuff; % buffer for output frame
        maxFrameSize; % maximum frame size in samples

        noteState = 'noteOff'; % trig

        storedParamSet = zeros(4,4); % stored parameters
        newParamSet = [1 1 1 0;
                       1 1 1 0;
                       1 1 1 0;
                       1 1 1 0]; % new parameters

        %====================================================================== synth parameters
        modes = zeros(4,55);
        decay = zeros(4,55);

        lpfPole = 0.0009; % lowpass filter pole radius - loss filter damping
        strikeGain; % gain coefficient for each mode
        m = 0; % slope of transfer fuction
        
        resBank = [audioread('Analyses/tom_res.wav')'; % extracted residuals
                   audioread('Analyses/snare_res.wav')';
                   audioread('Analyses/cymbal_res.wav')';
                   audioread('Analyses/kick_res.wav')'];
        resPadded; % zero padded residuals
        
        %======================================================================
    end
    
    properties (Constant)
       PluginInterface = audioPluginInterface(...
           audioPluginParameter('strikePos','DisplayName','StrikePosition','Mapping',{'lin',0,1}),...
           audioPluginParameter('strikeVig','DisplayName','StrikeVigor','Mapping',{'lin',0,1}),...
           audioPluginParameter('dimension','DisplayName','Dimension','Mapping',{'lin',0.5,1.5}),...
           audioPluginParameter('material','DisplayName','Material','Mapping',{'lin',0,1}),...
           audioPluginParameter('paramID','DisplayName','ParameterID','Mapping',{'int',1,4}),...
           audioPluginParameter('instID','DisplayName','ID','Mapping',{'int',1,4}),...
           audioPluginParameter('trig','DisplayName','Trigger','Mapping',{'enum','noteOff','noteOn_'}),...
           'InputChannels',1,'OutputChannels',1);      
    end
%----------------------------------------------------------------------------------------------------------
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

            obj.modes(1,:) = [112, 203, 259, 279, 300, 332, 345, 375, 398, 407,...
                              450, 473, 488, 488, 547, 596, 625, 653, 679, 692, 705, 760, 773,...
                              806, 852, 899, 924, 975, 998, 1019, 1046, 1109, 1134, 1164, 1192,...
                              1226, 1309, 1358, 1379, 1411, 1461, 1532, 1610, 1683, 1758, 1880,...
                              2027, 2131, 2271, 2515, 2731, 2809, 2922, 3224, 4694];
            obj.modes(2,:) = [706 190 705 1145 967 957 985 1003 835 294 415 530 ...
                              791 1216 1291 1339 1469 1874 1958 3049 4616 5656 zeros(1,55-22)];
            obj.modes(3,:) = [79 693 836 883 1212 1511 1793 1863 2666 3198 3657 ...
                              3741 4556 4725 4867 5005 6165 5768 zeros(1,55-18)];  % 6461
            obj.modes(4,:) = [27 44 54 72 100 123 151 170 232 247 263 299 317 ...
                              331 353 368 409 618 zeros(1,55-18)];

            obj.decay(1,:) = [0.9999 0.9999 0.9998 0.9998 0.9998 0.9997 0.9997 0.9996 ...
                              0.9996 0.9995 0.9995 0.9994 0.9994 0.9993 0.9993 0.9992 0.9992 0.9991 ...
                              0.9991 0.999 0.999 0.998 0.998 0.997 0.997 0.996 0.996 0.995 0.995 0.994 ...
                              0.994 0.993 0.993 0.992 0.992 0.991 0.991 0.991 0.991 0.991 0.991 0.991 ...
                              0.991 0.991 0.99 0.993 0.992 0.991 0.99 0.98 0.98 0.98 0.97 0.97 0.97];
            obj.decay(2,:) = [0.99 0.99 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 ...
                              0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 ...
                              0.98 zeros(1,55-22)];
            obj.decay(3,:) = [0.99 0.9998 0.9998 0.9989 0.999 0.995 0.995 0.995 0.9999 0.994 ...
                              0.9998 0.9998 0.9998 0.994 0.994 0.999 0.999 0.999 zeros(1,55-18)];
            obj.decay(4,:) = [0.999 0.99 0.99 0.99 0.99 0.9 0.9 0.98 0.9 0.94 0.94 0.98 ...
                              0.94 0.94 0.94 0.94 0.93 0.92 zeros(1,55-18)];
     
        end
        
        function reset(obj)
            obj.readIndex = ones(4,1);
            obj.soundOut = zeros(4,1);
        end 
        
        function set.trig(obj, val)
            if val == 'noteOn_'

                obj.newParamSet(obj.paramID, 1) = obj.strikePos; % get new parameters for selected instrument
                obj.newParamSet(obj.paramID, 2) = obj.strikeVig;
                obj.newParamSet(obj.paramID, 3) = obj.dimension;
                obj.newParamSet(obj.paramID, 4) = obj.material;
                %====================================================================== sound synthesis and parameter mapping

                if obj.storedParamSet(obj.instID,1) ~= obj.newParamSet(obj.instID, 1) || obj.storedParamSet(obj.instID,2) ~= obj.newParamSet(obj.instID, 2) || obj.storedParamSet(obj.instID,3) ~= obj.newParamSet(obj.instID, 3) || obj.storedParamSet(obj.instID,4) ~= obj.newParamSet(obj.instID, 4) % synth new waveform only if parameters are changed for the triggered instrument
                    obj.lpfPole = 0.00009+(0.001-0.00009)*obj.newParamSet(obj.instID,4); % scaling: v2 = a + (b-a) * v1
                    obj.m = (obj.strikeGain(length(obj.strikeGain))-obj.newParamSet(obj.instID,1)) / (length(obj.strikeGain)-1);
                    obj.strikeGain = obj.m * [1:length(obj.strikeGain)] + obj.newParamSet(obj.instID,1) - obj.m; % (y=mx+b)

                    obj.buff(obj.instID,:) = f_bdwg(obj.modes(obj.instID, 1:24)*obj.newParamSet(obj.instID,3), obj.decay(obj.instID, 1:24), length(obj.buff(1,:)), obj.fs, [0.999; 1.001], obj.lpfPole, obj.strikeGain)'; % banded waveguide
                    % waveguide mesh
    
                    obj.buff(obj.instID,:) = real(ifft(fft(obj.buff(obj.instID,:)) .* fft(obj.resPadded(obj.instID,:)))); % convolution with residual (multiplication of spectrums)
                    
                    obj.buff(obj.instID,:) = obj.buff(obj.instID,:) / max(obj.buff(obj.instID,:)); % normalisation of synth buffer
    
                    obj.buff(obj.instID,:) = obj.buff(obj.instID,:) * obj.newParamSet(obj.instID,2); % linear scaling
                    
                    obj.storedParamSet(obj.instID, 1) = obj.newParamSet(obj.instID, 1); % update stored parameters for triggered instrument
                    obj.storedParamSet(obj.instID, 2) = obj.newParamSet(obj.instID, 2);
                    obj.storedParamSet(obj.instID, 3) = obj.newParamSet(obj.instID, 3);
                    obj.storedParamSet(obj.instID, 4) = obj.newParamSet(obj.instID, 4);
                    
                end
                %======================================================================

                obj.readIndex(obj.instID) = 1; % init readIndex of respective buffer
                obj.soundOut(obj.instID) = 1; % trigger sound according to instrument ID
           
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
            
            out = obj.frameBuff(1:length(in))'; % output
            obj.frameBuff = zeros(1,length(obj.frameBuff)); % clear frame buffer

        end  
    end
%----------------------------------------------------------------------------------------------------------
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
%----------------------------------------------------------------------------------------------------------
function out = f_bdwg( freqs, decay, Tsamp, fs, low_high, damp, bandCoeff) % banded waveguide
    % Banded digital waveguide function
    
    %% variables
    
    freqs = freqs(freqs ~=0 ); % remove zero padding
    
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
    p_in = 7*ones(1,n_modes); % pointers in
    p_in1 = 6*ones(1,n_modes);
    p_in2 = 5*ones(1,n_modes);
    p_in3 = 4*ones(1,n_modes);

    
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
    
    % a and b coefficients bandpass and lowpass
    a = zeros(n_modes, 3);
    b = zeros(n_modes, 4);
    for i = 1:n_modes
        u = 2*R(i)*cosT(i);
        v = R(i)^2;
        b(i,:) = A0(i)*[1, -damp, -1, damp];
        a(i,:) = [1, -(damp+u-u*damp), v*(1-damp)];
    end
    
%     a = zeros(n_modes, 3);
%     b = zeros(n_modes, 3);
%     for i = 1:n_modes
%         b(i,:) = [A0(i), 0, -A0(i)]; % b coeff dependent of scaling gain factor
%         a(i,:) = [1, -2*R(i)*cosT(i), R(i)^2]; % a coeff depending on R and cosT     
%     end
    
    
    
    %% main loop
    
    for i=1:Tsamp
        
        out(i) = 0;
        
        for j = 1:n_modes
            
%             % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
%             L(j, p_out(j)) = decay(j) * (b(j,1)*L(j, p_in(j)) + ...                               % b(j,2)*L(j, p_in1(j))... (=0)
%                 + b(j,3)*L(j, p_in2(j)) - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)));
            
            % bandpass and lowpass
            L(j, p_out(j)) = b(j,1)*L(j, p_in(j)) + b(j,2)*L(j, p_in1(j)) + b(j,3)*L(j, p_in2(j)) + b(j,4)*L(j, p_in3(j))...
                            - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j));

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
            if (p_in3(j)==d(j))
                p_in3(j)=1;
            else
                p_in3(j)=p_in3(j)+1;
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