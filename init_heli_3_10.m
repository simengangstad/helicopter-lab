% FOR HELICOPTER NR 3-10
% This file contains the initialization for the helicopter assignment in
% the course TTK4115. Run this file before you execute QuaRC_ -> Build 
% to build the file heli_q8.mdl.

% Oppdatert h�sten 2006 av Jostein Bakkeheim
% Oppdatert h�sten 2008 av Arnfinn Aas Eielsen
% Oppdatert h�sten 2009 av Jonathan Ronen
% Updated fall 2010, Dominik Breu
% Updated fall 2013, Mark Haring
% Updated spring 2015, Mark Haring


%%%%%%%%%%% Calibration of the encoder and the hardware for the specific
%%%%%%%%%%% helicopter
Joystick_gain_x = 0.75;
Joystick_gain_y = 0.25;


%%%%%%%%%%% Physical constants
g = 9.81; % gravitational constant [m/s^2]
l_c = 0.46; % distance elevation axis to counterweight [m]
l_h = 0.66; % distance elevation axis to helicopter head [m]
l_p = 0.175; % distance pitch axis to motor [m]
m_c = 1.92; % Counterweight mass [kg]
m_p = 0.72; % Motor mass [kg]
J_p = 2*m_p*l_p.^2; % Moment of inertia around pitch
J_e = m_c*l_c.^2+2*m_p*l_h.^2;
J_l = m_c*l_c.^2+2*m_p*(l_h.^2+l_p.^2);


%%%%%%%%%%% IMU-port
PORT = 12;


%%%%%%%%%%% Offsets
e_offset =  -322.2611;
Vs_offset = 7.8394;


%%%%%%%%%%% Calculated values
Kf = -(l_c*m_c*g-l_h*2*m_p*g)/(l_h*Vs_offset);


%%%%%%%%%%% Model constants
L_1 = Kf*l_p; % Model constant for pitch
L_2 = l_c*m_c*g-l_h*2*m_p*g;
L_3 = l_h*Kf;
L_4 = l_h*Kf;
K_1 = L_1/J_p; % Linearization constant for pitch
K_2 = L_3/J_e; % Linearization constant for elevation
K_3 = L_4*Vs_offset/J_l; % Linearization constant for travel

%% %%%%%%%%% Monovariate control, PD Pitch controller values

%% Tuning diagram

K_pp = 11;
K_pd = 8;

%%  Pole placement
a = -sqrt(5/2);
b = sqrt(5/2);
lambda_1 = a+b*1i;
lambda_2 = a-b*1i;

K_pp = lambda_1*lambda_2 / K_1;
K_pd = -(lambda_1 + lambda_2) / K_1;

%% Second Order ODE method
w_0 = pi/2;
zeta = 1;

K_pp = w_0.^2 / K_1;
K_pd = 2*w_0*zeta / K_1;


%% %%%%%%%%% Multivariate control
%% Pole placement of K-matrix, no integral (p2t2)
K = zeros(2,3);
F = zeros(2,2);

A = [0 1 0;
     0 0 0;
     0 0 0];
B = [0      0;
    0       K_1;
    K_2     0];

p_1 = -2+1i;
p_2 = -2-1i;
p_3 = -sqrt(8);
p = [p_1 p_2 p_3];

K = place(A,B,p);


%% LQR method of control, no integral (p2t3)
K = zeros(2,3);
F = zeros(2,2);

A = [0 1 0;
     0 0 0;
     0 0 0];
B = [0      0;
    0       K_1;
    K_2     0];

Q = [40    0       0;
     0      120    0;
     0      0       100];
 
R = [0.1    0;
     0      1];

K = lqr(A, B, Q, R);

F(1,1) = K(1,1);
F(1,2) = K(1,3);
F(2,1) = K(2,1);
F(2,2) = K(2,3);


%% LQR method of control, with integral (p2t4)
K = zeros(2,5);
F = zeros(2,2);

A = [0  1   0   0   0;
    0  0   0   0   0;
    0  0   0   0   0;
    1  0   0   0   0;
    0  0   1   0   0];


B = [0      0;
    0      K_1;
    K_2    0;
    0      0;
    0      0];

G = [0      0; 
    0      0; 
    0      0;
    -1     0;
    0     -1];



Q = [10  0    0     0    0;
     0   1    0     0    0;
     0   0    1     0    0;
     0   0    0     0.5  0;
     0   0    0     0    100];
 
R = [0.1  0;
     0    0.1];
 
K = lqr(A, B, Q, R);
 
F(1,1) = K(1,1);
F(1,2) = K(1,3);
F(2,1) = K(2,1);
F(2,2) = K(2,3);

%% Random F

% F(1,1) = 1;
% F(1,2) = 0;
% F(2,1) = 0;
% F(2,2) = 1;


%% Luenberg observer
sys_speed = max(abs(real(eig(A-B*K))));


A = [0  1   0   0   0;
    0   0   0   0   0;
    0   0   0   1   0;
    0   0   0   0   0;
    K_3 0   0   0   0];

B = [0  0;
    0   K_1;
    0   0;
    K_2 0;
    0   0];

C = [0  0   1   0   0;
    0   0   0   0   1];

L = zeros(5,2);

sys_amp = 3;
pole_angle = 1;
deg2rad = pi / 180;
p = (-1)*sys_amp*sys_speed*[1 exp(-1*pole_angle*deg2rad*1i) exp(-2*pole_angle*deg2rad*1i) exp(1*pole_angle*deg2rad*1i) exp(2*pole_angle*deg2rad*1i)];

p = [-sqrt(9) -2+1i -2-1i -5+2i -5-2i];

close all
plot(p, '*');
xlim([-10 1]);
ylim([-5.5 5.5]);
grid on

L = place(A',C',p)';