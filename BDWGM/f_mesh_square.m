function y = f_mesh_square( NJ, decayFactor, a, exc_size, exc_pos, Tsamp, fs )
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

excite_size = floor(NJ*exc_size/100); % excitation size
excite_pos = round(NJ*exc_pos/100); % excitation centrale position (gravity center of the strike)
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

%soundsc(y,fs)
%plot(y)

end

