function FRU_PFR_Model
 
%Code written by: Pierre Desir
%Date: 06-13-16

% Plots of reactor performance at 11 temperatures are shown in this code

%This MatLab Code solves the PFR model for the acid-catalyzed dehydration of
%fructose to HMF using HCl as the catalyst and generates the kinetic data
%for conversion, yield, and selectivity of the species as a function of
%temperature, pH, and time. All the kinetic and thermodynamic parameters 
%were taken from the kinetic model by T. Dallas Swift et al. ACS Catal 
%2014, 4,259-267.

clear all
clear figure
clc
close all
format short
 
 tic
 %-------------------------------------------------------------------------
 %INPUT PARAMETERS: n_T, pH, Tmin_degC, Tmax_degC, tmin, tmax, Fru0
 n_T = 11; %Number of temperature points
 pH = 0.7; %Rxn pH
 Tmin_degC = 100; %Min rxn temperature [�C]
 Tmax_degC = 200; %Max rxn temperature [�C]
 t0 = 0; %Initial time point [min]
 tf = 1e3; %Final time point[min]
 Fru0 = 1; %Normalized initial fructose concentration (always equal to 1)
 %-------------------------------------------------------------------------
 %VARIABLE REACTION PARAMETERS
 C_Hplus = 10^(-pH); %H+ concentraction [mol/L]
 T_degC = linspace(Tmin_degC,Tmax_degC,n_T); %Rxn temperature [�C]
 T_K = T_degC + 273*ones(1,length(T_degC)); %Rxn temperature [K]
 %-------------------------------------------------------------------------

 for i = 1:n_T   
     
     %SOLVING FOR THE PFR MODEL     
     options = odeset('RelTol',1e-6,'bdf','on' );
     [Tau,Conc]= ode15s(@PFR,[t0,tf],[Fru0 0 0 0 ],options);
     %Tau is the residence (space) time in the PFR [min]
     %Conc is the species concentration matrix [mol/L]
     
    %RESULTS
    Fru = round(Conc(:,1),4); %Fructose normalized concentration 
    HMF = round(Conc(:,2),4); %HMF normalized concentration 
    LA = round(Conc(:,3),4); %Levulinic acid (LA) concentration 
    FA = round(Conc(:,4),4); %Formic acid (FA) concentration 
    Conv = round(100*(1-Fru),4); %Fructose conversion [%]
    HMF_Yield = 100*HMF; %HMF yield [%]
    HMF_Select = 100*HMF_Yield./Conv; %HMF selectivity [%]
    LA_Yield = 100*LA; %LA yield [%]
    FA_Yield = 100*FA; %FA yield [%]
    
    %OPTIMAL CONDITIONS FOR MAX HMF YIELD
    Max_HMF_Yield(i) = max(HMF_Yield); %Maximum HMF Yield [%]
    index_range = (find(HMF_Yield == Max_HMF_Yield(i))); % Index of matrix 
    %element where the HMF yield is at its max value
    index(i) = index_range(max(find(Conv(index_range) == max(Conv(index_range)))));
    %index of matrix element for optimal conditions for max HMF yield
    Tau_opt(i) = Tau(index(i)); %Optimal residence time to reach maximum HMF 
    %yield [min]
    Opt_Conv(i) = round(Conv(index(i))); %Fructose conversion at max HMF yield [%]
    Opt_Select(i) = HMF_Select(index(i)); %HMF selectivity at max HMF yield [%]
    
    %REPORTING OPTIMAL CONDITIONS
    Opt_Cond(i,:) = [T_degC(i) Tau_opt(i) Max_HMF_Yield(i) Opt_Conv(i) Opt_Select(i)];
    %Temperature, optimal residence time, max HMF yield, conversion at max
    %HMF yield, HMF selectivity at max HMF yield
    
   
    %PLOTTING THE RESULTS
    %FIG.1 : HMF selectivity vs. FRU conversion
    figure(1);
    fig1(i)= plot(Conv,HMF_Select,'DisplayName',...
        strcat(num2str(round(T_degC(i),2)),' ^oC'));
    xlabel('Fructose Conversion (%)');
    ylabel('HMF Selectity (%)');xlim([5 100]);
    title('HMF Selectivity');
    hold on
    
    %FIG.2 : FRU Conversion vs. residence time
    figure(2);
    fig2(i)= semilogx(Tau,Conv,'DisplayName',...
        strcat(num2str(round(T_degC(i),2)),' ^oC'));
    xlim([t0 tf]);
    xlabel('Residence Time (min)');
    ylabel('Fructose Conversion (%)');xlim([t0 tf]); 
    title('Fructose Conversion');
    hold on
    
    %FIG.3 : HMF yield vs. residence time
    figure(3);
    fig3(i)= semilogx(Tau,HMF_Yield,'DisplayName',...
        strcat(num2str(round(T_degC(i),2)),' ^oC')); 
    xlabel('Residence Time (min)');
    ylabel('HMF Yield (%)'); 
    xlim([t0 tf]);title('HMF Yield');
    hold on
    
    %FIG.4 : LA yield vs. residence time
    figure(4);
    fig4(i)= semilogx(Tau,LA_Yield,'DisplayName',...
        strcat(num2str(round(T_degC(i),2)),' ^oC')); 
    xlabel('Residence Time (min)');
    ylabel('LA Yield (%)'); 
    xlim([t0 tf]);title('LA Yield');
    hold on
    
    %FIG.5 : FA yield vs. residence time
    figure(5);
    fig5(i)= semilogx(Tau,FA_Yield,'DisplayName',...
        strcat(num2str(round(T_degC(i),2)),' ^oC')); 
    xlabel('Residence Time (min)');
    ylabel('FA Yield (%)'); 
    xlim([t0 tf]);title('FA Yield');
    hold on
 
 end

 hold off
 
 %FIG.6 : Max HMF yield vs. temperature
 figure(6);
 fig6 = plot(T_degC,Max_HMF_Yield);    
 xlabel('Temperature (�C)');
 ylabel('Max HMF Yield (%)'); 
 title('Max HMF Yield');
 
 %FIG.7 : Optimal residence time vs. temperature
 figure(7);
 fig7 = semilogy(T_degC,Tau_opt);    
 xlabel('Temperature (�C)');
 ylabel('Optimal Residence Time (min)'); 
 title('Optimal Residence Time');
 
 
 %ADDING LEGENDS TO PLOTS
 legend(fig1);legend(fig2);legend(fig3);legend(fig4);legend(fig5);
 
toc
  
    function rhs = PFR(t,C)
        %The "PFR" function describes the species conservative equation as a
        %set of ODEs
        
        %CONSTANTS
        R = 8.314; %Ideal gas law constant [J/mol-K]
        Tm = 381; %Mean temperature of all Rxn [K]

        %OTHER MODEL PARAMETERS
        C_H2O(i) = 47.522423477254065 + 0.06931572301966918*T_K(i)...
           -0.00014440077466393135*T_K(i)^2; %Water 
        %concentration as a function of temperature from 25 �C to 300 �C
        %[mol/L]
       
        
        %TAUTOMER PARAMETERS
        %Enthalpy of Rxn b/t open-chain fructose and tautomers
        %Note: a = alpha; b = beta; p = pyrannose; f = furannose
        delH_bp = -30.2e3; %[J/mol]
        delH_bf = -19e3; %[J/mol]
        delH_ap = -5.5e3; %J/mol]
        delH_af = -14.2e3; %[J/mol]
        
        %Equilibrium constants b/t open-chain fructose and tautomers at 303 K
        K_bp303 = 59.2;
        K_bf303 = 26.4;
        K_ap303 = 0.6;
        K_af303 = 6.4;
        
        %Equilibirium constants b/t open-chain fructose and tautomers as a 
        %function of temperature
        K_bp(i) = K_bp303*exp(-(delH_bp/R)*(1/T_K(i)-1/303));
        K_bf(i) = K_bf303*exp(-(delH_bf/R)*(1/T_K(i)-1/303));
        K_ap(i) = K_ap303*exp(-(delH_ap/R)*(1/T_K(i)-1/303));
        K_af(i) = K_af303*exp(-(delH_af/R)*(1/T_K(i)-1/303));
        
        %Furanose fraction at equilibirum as a function of temperature
        phi_f(i) = (K_af(i)+K_bf(i))/(1+K_af(i)+K_bf(i)+K_ap(i)+K_bp(i));
        
        %ACTIVATIONS ENERGIES FOR RXN1,RXN2,...,RXN5
        Ea = [127 133 97 64 129]*10^3; %[J/mol]
        
        %NTURAL LOG OF RXN RATE CONSTANTS AT 381 K FOR RXN1,RXN2,...,RXN5
        lnk381 = [1.44 -4.22 -3.25 -5.14 -4.92];
 
        %RXN RATE CONSTANTS FOR RXN1,RXN2,...,RXN5 AS A FUNCTION OF 
        %TEMPERATURE
        k(i,1) = exp(lnk381(1)-(Ea(1)/R)*(1/T_K(i)-1/Tm)); %[min^-1.M^-1]
        k(i,2) = exp(lnk381(2)-(Ea(2)/R)*(1/T_K(i)-1/Tm)); %[min^-1.M^-1]
        k(i,3) = exp(lnk381(3)-(Ea(3)/R)*(1/T_K(i)-1/Tm)); %[min^-1.M^-1]
        k(i,4) = exp(lnk381(4)-(Ea(4)/R)*(1/T_K(i)-1/Tm)); %[min^-1.M^-1]
        k(i,5) = exp(lnk381(5)-(Ea(5)/R)*(1/T_K(i)-1/Tm)); %[min^-1.M^-1]
        
        %RXN RATES FOR THE RXN NETWORK OF FRUCTOSE DEHYDRATION
        %Note: C(1) = Normalized Fructose concentration; C(2) = Normalized
        %HMF concentration; C(3) = Normalized LA concentration; 
        %C(4) = Normalized FA concentration;
        Rxn = zeros(5,length(T_K)); %[mol/L-min]
        Rxn(1,i) = k(i,1)*phi_f(i)*C(1)*C_Hplus/C_H2O(i);
        %[mol/L-min]
        Rxn(2,i) = k(i,2)*C(1)*C_Hplus; %[min^-1]
        Rxn(3,i) = k(i,3)*C(2)*C_Hplus; %[min^-1]
        Rxn(4,i) = k(i,4)*C(2)*C_Hplus; %[min^-1]
        Rxn(5,i) = k(i,5)*C(1)*C_Hplus; %[min^-1]
 
        %SPECIES CONSERVATIVE EQUATIONS
        %Notation: rhs = dC/dt
        rhs(1,1) = (-Rxn(1,i)-Rxn(2,i)-Rxn(5,i)); %Fructose
        rhs(2,1) = (Rxn(1,i)-Rxn(3,i)-Rxn(4,i)); %HMF
        rhs(3,1) = Rxn(3,i); %LA
        rhs(4,1) = (Rxn(3,i)+Rxn(5,i)); %FA
  
    end
end

