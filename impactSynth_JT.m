classdef impactSynth_JT < audioPlugin
    % audio plugin for producing bubble sounds

    properties
        % interfaced parameters
        strikePos = 1;
        strikeVig = 1;
        dimension = 1;
        material = 0;
        % test param
        bandwidth = 0.999;
        n_Modes = 24;

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

        storedParamSet = zeros(4,6); % stored parameters
        newParamSet = [1 1 1 0 0.999 55;
                       1 1 1 0 0.999 55;
                       1 1 1 0 0.999 55;
                       1 1 1 0 0.999 55]; % new parameters

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
           audioPluginParameter('dimension','DisplayName','Dimension','Mapping',{'lin',0.5,1.3}),...
           audioPluginParameter('material','DisplayName','Material','Mapping',{'lin',0,1}),...
           audioPluginParameter('bandwidth','DisplayName','Bandwidth','Mapping',{'lin',0.7,0.999}),...
           audioPluginParameter('n_Modes','DisplayName','Number of modes','Mapping',{'int',1,55}),...
           audioPluginParameter('paramID','DisplayName','ParameterID','Mapping',{'int',1,4}),...
           audioPluginParameter('instID','DisplayName','ID','Mapping',{'int',1,4}),...
           audioPluginParameter('trig','DisplayName','Trigger','Mapping',{'enum','noteOff','noteOn_'}),...
           'InputChannels',1,'OutputChannels',1);
    end
%----------------------------------------------------------------------------------------------------------
    methods
        function obj = impactSynth_JT() % constructor
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
                              791 1216 1291 1339 1469 1874 1958 3049 zeros(1,55-20)]; % 4616 5656
            obj.modes(3,:) = [79 693 836 883 1212 1511 1793 1863 2666 3198 3657 ...
                              3741 4556 4725  zeros(1,55-14)];  % 6461 4867 5005 6165 5768
            obj.modes(4,:) = [27 44 54 72 100 123 151 170 232 247 263 299 317 ...
                              331 353 368 409 618 zeros(1,55-18)];

            obj.decay(1,:) = [0.9999 0.9999 0.9998 0.9998 0.9998 0.9997 0.9997 0.9996 ...
                              0.9996 0.9995 0.9995 0.9994 0.9994 0.9993 0.9993 0.9992 0.9992 0.9991 ...
                              0.9991 0.999 0.999 0.998 0.998 0.997 0.997 0.996 0.996 0.995 0.995 0.994 ...
                              0.994 0.993 0.993 0.992 0.992 0.991 0.991 0.991 0.991 0.991 0.991 0.991 ...
                              0.991 0.991 0.99 0.993 0.992 0.991 0.99 0.98 0.98 0.98 0.97 0.97 0.97];
            obj.decay(2,:) = [0.99 0.99 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 ...
                              0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 0.98 zeros(1,55-20)];
            obj.decay(3,:) = [0.99 0.9998 0.9998 0.9989 0.999 0.995 0.995 0.995 0.9999 0.994 ...
                              0.9998 0.9998 0.9998 0.994 zeros(1,55-14)]; % 0.994 0.999 0.999 0.999
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
                obj.newParamSet(obj.paramID, 5) = obj.bandwidth;
                obj.newParamSet(obj.paramID, 6) = obj.n_Modes;
                %====================================================================== sound synthesis and parameter mapping

                if obj.storedParamSet(obj.instID,1) ~= obj.newParamSet(obj.instID, 1) || obj.storedParamSet(obj.instID,2) ~= obj.newParamSet(obj.instID, 2)...
                        || obj.storedParamSet(obj.instID,3) ~= obj.newParamSet(obj.instID, 3) || obj.storedParamSet(obj.instID,4) ~= obj.newParamSet(obj.instID, 4)...
                        || obj.storedParamSet(obj.instID,5) ~= obj.newParamSet(obj.instID, 5) || obj.storedParamSet(obj.instID,6) ~= obj.newParamSet(obj.instID, 6) % synth new waveform only if parameters are changed for the triggered instrument
                    obj.lpfPole = 0.00009+(0.001-0.00009)*obj.newParamSet(obj.instID,4); % scaling: v2 = a + (b-a) * v1
                    obj.m = (obj.strikeGain(length(obj.strikeGain))-obj.newParamSet(obj.instID,1)) / (length(obj.strikeGain)-1);
                    obj.strikeGain = obj.m * [1:length(obj.strikeGain)] + obj.newParamSet(obj.instID,1) - obj.m; % (y=mx+b)
                    deca = obj.decay(obj.instID, 1:obj.newParamSet(obj.instID,6)); % decay and modes local variables
                    freqs = obj.modes(obj.instID, 1:obj.newParamSet(obj.instID,6));
                    deca = deca(deca ~= 0 ); % remove zero padding
                    freqs = freqs(freqs ~= 0 );
                    
                    % bwg
                    if (obj.instID == 1 || obj.instID == 2 || obj.instID == 4) % tom, snare, kick
                        obj.buff(obj.instID,:) = f_bdwg(obj.instID, freqs*obj.newParamSet(obj.instID,3), deca, length(obj.buff(1,:)), obj.fs, [obj.newParamSet(obj.instID,5); 2-obj.newParamSet(obj.instID,5)], obj.lpfPole, obj.strikeGain)'; % banded waveguide
                    else % cymbal
                        obj.buff(obj.instID,:) = f_bdwg(obj.instID, freqs*obj.newParamSet(obj.instID,3), deca+(0.0001+(-0.01-0.0001))*obj.material, length(obj.buff(1,:)), obj.fs, [obj.newParamSet(obj.instID,5); 2-obj.newParamSet(obj.instID,5)], obj.lpfPole, obj.strikeGain)'; % banded waveguide
                    end
                    % mesh
                    if (obj.instID == 2 || obj.instID == 3) % snare, cymbal add mesh
                        obj.buff(obj.instID,:) = obj.buff(obj.instID,:) + f_mesh_square(10, 0.99999, obj.fs, length(obj.buff(obj.instID,:)));
                    end
    
                    obj.buff(obj.instID,:) = real(ifft(fft(obj.buff(obj.instID,:)) .* fft(obj.resPadded(obj.instID,:)))); % convolution with residual (multiplication of spectrums)
                    
                    obj.buff(obj.instID,:) = obj.buff(obj.instID,:) / max(obj.buff(obj.instID,:)); % normalisation of synth buffer
    
                    obj.buff(obj.instID,:) = obj.buff(obj.instID,:) * obj.newParamSet(obj.instID,2); % linear scaling
                    
                    obj.storedParamSet(obj.instID, 1) = obj.newParamSet(obj.instID, 1); % update stored parameters for triggered instrument
                    obj.storedParamSet(obj.instID, 2) = obj.newParamSet(obj.instID, 2);
                    obj.storedParamSet(obj.instID, 3) = obj.newParamSet(obj.instID, 3);
                    obj.storedParamSet(obj.instID, 4) = obj.newParamSet(obj.instID, 4);
                    obj.storedParamSet(obj.instID, 5) = obj.newParamSet(obj.instID, 5);
                    obj.storedParamSet(obj.instID, 6) = obj.newParamSet(obj.instID, 6);
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
function out = f_bdwg(instID, freqs, decay, Tsamp, fs, low_high, damp, bandCoeff) % banded waveguide
    % Banded digital waveguide function
    
    %% variables
    
    %freqs = freqs(freqs ~= 0 ); % remove zero padding
    
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
    
    f_low_high = low_high*freqs;
    B = f_low_high(2,:) - f_low_high(1,:); % bandwidth
    % B = B';
    B_rad = 2*pi/fs*B; % bandwidth in radians/samp
    psi = 2*pi/fs*freqs; % center frequencies in radians/samp
    R = 1 - B_rad/2;
    cosT = 2*R/(1+R.^2) * cos(psi);
    A0 = (1-R.^2)/2; % normalization scale factor or gain adjustment
    
    % delay line pointers
    if (instID == 1 || instID == 2 || instID == 4) % instruments using LPF
        p_out =  3*ones(1,n_modes); % pointers out
        p_out1 = 2*ones(1,n_modes);
        p_out2 = 1*ones(1,n_modes);
        
        p_in =  7*ones(1,n_modes); % pointers in
        p_in1 = 6*ones(1,n_modes);
        p_in2 = 5*ones(1,n_modes);
        p_in3 = 4*ones(1,n_modes);
        
        a = zeros(n_modes, 3);
        b = zeros(n_modes, 4);
        for i = 1:n_modes
            u = 2*R(i)*cosT(i);
            v = R(i)^2;
            b(i,:) = A0(i)*[1, -damp, -1, damp];
            a(i,:) = [1, -(damp+u-u*damp), v*(1-damp)];
        end
        
        for i=1:Tsamp
            
            out(i) = 0;
            
            for j = 1:n_modes
                % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
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
            end
        end
    else                                           % instruments using predefined decay rates
        p_out =  3*ones(1,n_modes);
        p_out1 = 2*ones(1,n_modes);
        p_out2 = 1*ones(1,n_modes);
        
        p_in =  6*ones(1,n_modes);
        p_in1 = 5*ones(1,n_modes);
        p_in2 = 4*ones(1,n_modes);
        
        a = zeros(n_modes, 3);
        b = zeros(n_modes, 3);
        for i = 1:n_modes
            b(i,:) = [A0(i), 0, -A0(i)]; % b coeff dependent of scaling gain factor
            a(i,:) = [1, -2*R(i)*cosT(i), R(i)^2]; % a coeff depending on R and cosT
        end
        
        for i=1:Tsamp
            
            out(i) = 0;
            
            for j = 1:n_modes
                % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
                L(j, p_out(j)) = decay(j) * (b(j,1)*L(j, p_in(j)) + ...                               % b(j,2)*L(j, p_in1(j))... (=0)
                    + b(j,3)*L(j, p_in2(j)) - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)));
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
            end
        end
    end
    
    out = out / max(out);
    
%     %% bandpass according to paper (following Steiglitz's DSP book, 1996)
%     
%     f_low_high = low_high*freqs;
%     B = f_low_high(2,:) - f_low_high(1,:); % bandwidth
%     % B = B';
%     B_rad = 2*pi/fs*B; % bandwidth in radians/samp
%     psi = 2*pi/fs*freqs; % center frequencies in radians/samp
%     R = 1 - B_rad/2;
%     cosT = 2*R/(1+R.^2) * cos(psi);
%     A0 = (1-R.^2)/2; % normalization scale factor or gain adjustment
%     
%     % a and b coefficients bandpass and lowpass
%     if (instID == 1 || instID == 2 || instID == 4)
%         a = zeros(n_modes, 3);
%         b = zeros(n_modes, 4);
%         for i = 1:n_modes
%             u = 2*R(i)*cosT(i);
%             v = R(i)^2;
%             b(i,:) = A0(i)*[1, -damp, -1, damp];
%             a(i,:) = [1, -(damp+u-u*damp), v*(1-damp)];
%         end
%     else
%         a = zeros(n_modes, 3);
%         b = zeros(n_modes, 3);
%         for i = 1:n_modes
%             b(i,:) = [A0(i), 0, -A0(i)]; % b coeff dependent of scaling gain factor
%             a(i,:) = [1, -2*R(i)*cosT(i), R(i)^2]; % a coeff depending on R and cosT
%         end
%     end
% 
%     %% main loop
%     
%     if (instID == 1 || instID == 2 || instID == 4)
%         for i=1:Tsamp
%             
%             out(i) = 0;
%             
%             for j = 1:n_modes
%                 % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
%                 % bandpass and lowpass
%                 L(j, p_out(j)) = b(j,1)*L(j, p_in(j)) + b(j,2)*L(j, p_in1(j)) + b(j,3)*L(j, p_in2(j)) + b(j,4)*L(j, p_in3(j))...
%                     - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j));
%                 out(i) = out(i) + L(j,p_out(j))*bandCoeff(j);
%                 % update and wrap pointers
%                 if (p_in(j)==d(j))
%                     p_in(j)=1;
%                 else
%                     p_in(j)=p_in(j)+1;
%                 end
%                 if (p_in1(j)==d(j))
%                     p_in1(j)=1;
%                 else
%                     p_in1(j)=p_in1(j)+1;
%                 end
%                 if (p_in2(j)==d(j))
%                     p_in2(j)=1;
%                 else
%                     p_in2(j)=p_in2(j)+1;
%                 end
%                 if (p_in3(j)==d(j))
%                     p_in3(j)=1;
%                 else
%                     p_in3(j)=p_in3(j)+1;
%                 end
%                 if (p_out(j)==d(j))
%                     p_out(j)=1;
%                 else
%                     p_out(j)=p_out(j)+1;
%                 end
%                 if (p_out1(j)==d(j))
%                     p_out1(j)=1;
%                 else
%                     p_out1(j)=p_out1(j)+1;
%                 end
%                 if (p_out2(j)==d(j))
%                     p_out2(j)=1;
%                 else
%                     p_out2(j)=p_out2(j)+1;
%                 end
%             end
%         end
%     else
%         for i=1:Tsamp
%             
%             out(i) = 0;
%             
%             for j = 1:n_modes
%                 % bandpass filter y[n] = b1*x[n] + b2*x[n-1] + b3*x[n-2] - a2*y[n-1] - a3*y[n-2]
%                 L(j, p_out(j)) = decay(j) * (b(j,1)*L(j, p_in(j)) + ...                               % b(j,2)*L(j, p_in1(j))... (=0)
%                     + b(j,3)*L(j, p_in2(j)) - a(j,2)*L(j, p_out1(j)) - a(j,3)*L(j, p_out2(j)));
%                 out(i) = out(i) + L(j,p_out(j))*bandCoeff(j);
%                 % update and wrap pointers
%                 if (p_in(j)==d(j))
%                     p_in(j)=1;
%                 else
%                     p_in(j)=p_in(j)+1;
%                 end
%                 if (p_in1(j)==d(j))
%                     p_in1(j)=1;
%                 else
%                     p_in1(j)=p_in1(j)+1;
%                 end
%                 if (p_in2(j)==d(j))
%                     p_in2(j)=1;
%                 else
%                     p_in2(j)=p_in2(j)+1;
%                 end
%                 if (p_out(j)==d(j))
%                     p_out(j)=1;
%                 else
%                     p_out(j)=p_out(j)+1;
%                 end
%                 if (p_out1(j)==d(j))
%                     p_out1(j)=1;
%                 else
%                     p_out1(j)=p_out1(j)+1;
%                 end
%                 if (p_out2(j)==d(j))
%                     p_out2(j)=1;
%                 else
%                     p_out2(j)=p_out2(j)+1;
%                 end
%             end
%         end
%     end
%     
%     out = out / max(out);
    
end
%% ========================================================================

function y = f_mesh_square( NJ, decayFactor, fs, tim)
y = zeros(1,tim);
a = 0.001;
Tsamp=round(0.6*fs);
excite_size = ceil(NJ/5); % excitation size
excite_pos = ceil(NJ/2); % excitation centrale position (gravity center of the strike)

% Square mesh function based on STK
% Square Junctions
% No animation

%% Variables and initialization

% initialize calculation matrices

vE = zeros(NJ, NJ); % east velocity wave
vW = zeros(NJ, NJ); % west velocity wave
vN = zeros(NJ, NJ); % north velocity wave
vS = zeros(NJ, NJ); % south velocity wave

% alternating matrix (matrix for first step, it will contain the excitation)

vE1 = zeros(NJ, NJ); % east velocity wave
vW1 = zeros(NJ, NJ); % west velocity wave
vN1 = zeros(NJ, NJ); % north velocity wave
vS1 = zeros(NJ, NJ); % south velocity wave

v = zeros(NJ-1, NJ-1); % junctions' velocity

y = zeros(1, Tsamp); % output

% reflexion
% r_coeff = -1; % reflexion coefficient (-1 for perfect inverse phase reflection)
b = 1 - abs(a);


%% Excitation parameters

% excitation position and size

%excite_size = floor(NJ*exc_size/100); % excitation size
%excite_pos = round(NJ*exc_pos/100); % excitation centrale position (gravity center of the strike)
% exite_pos = round((NJ-exite_size)/2); % center position (middle-10%)

% excitation shape and velocity

excite_temp = zeros(NJ-1, 1); % temporary excitation vector
% fill values around excitation point with a sine shape
excite_temp(excite_pos-round(excite_size/2):excite_pos-round(excite_size/2)+excite_size-1)...
    = 0.25*sin(pi*[0:excite_size-1]/(excite_size)); % 0.25 is the amplitude, thus the strike force!
% transpose to make it an area (vector becomes a matrix)
excite = excite_temp*transpose(excite_temp); % excitation!
% excite mesh with our sine excitation signal -> fill the alternating matrix
vW1(1:NJ-1, 1:NJ-1) = excite;
vN1(1:NJ-1, 1:NJ-1) = excite;
vE1(1:NJ-1, 2:NJ) = excite;
vS1(2:NJ, 1:NJ-1) = excite;

%% Main loop

% update junctions' velocitiy with excitation signal
v = 0.5 * (vW1(1:NJ-1,1:NJ-1) + vE1(1:NJ-1,2:NJ) + vN1(1:NJ-1,1:NJ-1) + vS1(2:NJ,1:NJ-1));

for i = 1:Tsamp
    
    if (mod(i,2) == 0) % clock 0 (even)
        
        % Velocities
        v = 0.5 * (vW(1:NJ-1,1:NJ-1) + vE(1:NJ-1,2:NJ) + vN(1:NJ-1,1:NJ-1) + vS(2:NJ,1:NJ-1));
        
        % v^+ = v_j - v^-
        vW1(1:NJ-1,2:NJ)   = v - vE(1:NJ-1,2:NJ);
        vN1(2:NJ,1:NJ-1)   = v - vS(2:NJ,1:NJ-1);
        vE1(1:NJ-1,1:NJ-1) = v - vW(1:NJ-1,1:NJ-1);
        vS1(1:NJ-1,1:NJ-1) = v - vN(1:NJ-1,1:NJ-1);
        
        % Boundaries
        vW1(1:NJ-1,1)  = decayFactor * filter(b, [1 a],   vE(1:NJ-1,1));
        vE1(1:NJ-1,NJ) = decayFactor * filter(b, [1 a],   vW(1:NJ-1,NJ));
        vN1(1,1:NJ-1)  = decayFactor * filter(b, [1 a],   vS(1,1:NJ-1));
        vS1(NJ,1:NJ-1) = decayFactor * filter(b, [1 a],   vN(NJ,1:NJ-1));
        
    else               % clock 1 (odd)
        
        % Velocities
        v = 0.5 * (vW1(1:NJ-1,1:NJ-1) + vE1(1:NJ-1,2:NJ) + vN1(1:NJ-1,1:NJ-1) + vS1(2:NJ,1:NJ-1));
        
        % v^+ = v_j - v^-
        vW(1:NJ-1,2:NJ)   = v - vE1(1:NJ-1,2:NJ);
        vN(2:NJ,1:NJ-1)   = v - vS1(2:NJ,1:NJ-1);
        vE(1:NJ-1,1:NJ-1) = v - vW1(1:NJ-1,1:NJ-1);
        vS(1:NJ-1,1:NJ-1) = v - vN1(1:NJ-1,1:NJ-1);
%         
        % Boundaries
        vW(1:NJ-1,1)  = decayFactor * filter(b, [1 a],   vE1(1:NJ-1,1));
        vE(1:NJ-1,NJ) = decayFactor * filter(b, [1 a],   vW1(1:NJ-1,NJ));
        vN(1,1:NJ-1)  = decayFactor * filter(b, [1 a],   vS1(1,1:NJ-1));
        vS(NJ,1:NJ-1) = decayFactor * filter(b, [1 a],   vN1(NJ,1:NJ-1));
        
    end
    
    % sound output pick up location
    y(i) = v(NJ-1,NJ-1);
end
y=[y zeros(1,tim-length(y))];
end
