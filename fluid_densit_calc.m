
clear all
close all
clc

t = 0.762*10^-3; %pipe thickness
u_t = 0.0005*0.0254;
d = 41/1000; %inner diameter
u_d = 0.0005*0.0254;
l = 3*0.0254; %length submerged
u_l = 0.005*0.0254;
F_b = 0.07; %buoyant force
u_F_b = 0.005;
g = 9.81; % gravity


V_sub = pi * t * (d+t) * l;
rho_f = F_b / (V_sub * g); %fluid density

u = [u_t, u_d, u_l, u_F_b];
p = rho_f./[t, d, l, F_b];

temp = 0;
for i = 1:1:length(u)
    temp = temp + (u(i)*p(i))^2;
end

u_rho_f = temp^0.5;
