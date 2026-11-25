// ============================================================
// cable_mag.pro  -  Section 3: magnetoquasistatic (MQS) model of the ABB 45 kV 3x240 mm2 Al cable
// Version V0.1 (team draft, Claude-assisted - declare in README).  Geometry: cable_geometry.geo (V1.4)
// Units: SI (the .geo converts mm -> m).  Phasors are PEAK values, x(t) = Re{x exp(i w t)}.
// ============================================================

DefineConstant[
  Freq        = {50.0,   Name "Cable/Excitation/Freq [Hz]"},
  I_rms       = {385.0,  Name "Cable/Excitation/I_rms per phase [A]"},      // ABB rating, Manufacturer-confirmed

  // --- Modelling switches (Q3.2, Q3.3, Q3.4) ---
  Flag_Conductor = {1,   Name "Model/Conductor (1 stranded: imposed uniform j, 2 massive: net I, eddy currents)"},
  Flag_Bonding   = {1,   Name "Model/Bonding (1 solid: U'=0 in sheaths+armour, 2 single-point: I=0)"},
  Flag_Soil      = {1,   Name "Model/Seabed conducting (1 yes, 0 no)"},
  Flag_Semi      = {0,   Name "Model/Semiconducting screens conducting (1 yes, 0 no)"},
  Flag_Armour    = {1,   Name "Model/Armour present (1 yes, 0 no)"},
  Flag_OneCore   = {0,   Name "Model/One core only: core A + own sheath, no armour (1) or full cable (0)"},
  Flag_Degree_a  = {1,   Name "Model/Polynomial degree of a (1 or 2)"},

  // --- Materials ---
  sigma_Al    = {3.77e7, Name "Cable/Materials/Aluminium/sigma"},           // Table 3
  alpha_Al    = {0.0039, Name "Cable/Materials/Aluminium/alpha [1/K]"},     // Appendix A
  Theta_Al    = {20.0,   Name "Cable/Materials/Aluminium/Temperature [C]"}, // 20 C: sigma = sigma_Al
  fill_Al     = {1.0,    Name "Cable/Materials/Aluminium/Fill factor on sigma (1 = Table 3)"},
  sigma_Lead  = {4.55e6, Name "Cable/Materials/Lead/sigma"},                // [Open: source needed]
  sigma_Armour= {4.7e6,  Name "Cable/Materials/Armour/sigma"},              // Table 3
  mur_Armour  = {4.0,    Name "Cable/Materials/Armour/mu_r"},               // Table 3 (assume); Open: justify
  sigma_Semi  = {2.0,    Name "Cable/Materials/Semicon/sigma"},
  sigma_Soil  = {0.5,    Name "Cable/Materials/Soil/sigma"},                // Q1.2 (source Open)
  r_cond_mm   = {9.05,   Name "Geometry/r_cond [mm]"},
  r_soil_mm   = {310.0,  Name "Geometry/r_soil [mm]"},               // truncation radius (same ONELAB name as in the .geo)
  Flag_BC     = {0,      Name "Model/Truncation BC (0 Dirichlet a=0, 1 asymptotic mixed BC)"},
  m_asym      = {1.0,    Name "Model/Asymptotic BC: leading harmonic m"}
];
R_trunc = r_soil_mm*1e-3;

mu0 = 4e-7*Pi;
Ipk = Sqrt[2]*I_rms;                      // peak phase current: 544.47 A
Pa = 0.0;  Pb = -2*Pi/3;  Pc = 2*Pi/3;    // phase angles 0, -120, +120 deg

Group {
  Ind_1 = Region[1]; Ind_2 = Region[2]; Ind_3 = Region[3];
  Inds  = Region[{Ind_1, Ind_2, Ind_3}];
  XLPE  = Region[{4,5,6}];  SemiIn = Region[{7,8,9}];  SemiOut = Region[{10,11,12}];
  Lead  = Region[{13,14,15}];
  Filling = Region[16];  Steel = Region[17];  Outer = Region[18];  Soil = Region[19];
  OuterBC = Region[20];
  Lead_A = Region[13]; Lead_B = Region[14]; Lead_C = Region[15];
  APLSheath = Region[Lead];                  // name used in the template post-operation

  Domain_Mag = Region[{Inds, XLPE, SemiIn, SemiOut, Lead, Filling, Steel, Outer, Soil}];

  // ---- conducting (massive) regions ----
  DomainC_Mag = Region[{Lead}];
  If(Flag_Armour)   DomainC_Mag += Region[{Steel}];   EndIf
  If(Flag_Soil)     DomainC_Mag += Region[{Soil}];    EndIf
  If(Flag_Semi)     DomainC_Mag += Region[{SemiIn, SemiOut}]; EndIf
  If(Flag_Conductor == 2) DomainC_Mag += Region[{Inds}]; EndIf

  // ---- stranded (imposed uniform current density) ----
  If(Flag_Conductor == 1)
    DomainS_Mag = Region[{Inds}];
  Else
    DomainS_Mag = Region[{}];
  EndIf
  DomainS0_Mag = Region[{}];

  // ---- massive regions closed by an imposed NET CURRENT (Current_2D) ----
  DomainCWithI_Mag = Region[{}];
  If(Flag_Conductor == 2) DomainCWithI_Mag += Region[{Inds}]; EndIf
  If(Flag_Soil)           DomainCWithI_Mag += Region[{Soil}]; EndIf
  If(Flag_Semi)           DomainCWithI_Mag += Region[{SemiIn, SemiOut}]; EndIf
  If(Flag_Bonding == 2)
    DomainCWithI_Mag += Region[{Lead}];
    If(Flag_Armour) DomainCWithI_Mag += Region[{Steel}]; EndIf
  EndIf
}

Function {
  sigma[Ind_1]    = fill_Al*sigma_Al/(1+alpha_Al*(Theta_Al-20.0));
  sigma[Region[{Ind_2, Ind_3}]] = Flag_OneCore ? 1e-3 : fill_Al*sigma_Al/(1+alpha_Al*(Theta_Al-20.0));   // one-core test: B, C are inert
  sigma[Lead_A]   = sigma_Lead;
  sigma[Region[{Lead_B, Lead_C}]] = Flag_OneCore ? 0.0 : sigma_Lead;   // one-core test: sheaths B, C removed
  sigma[Steel]    = Flag_OneCore ? 0.0 : sigma_Armour;                 // one-core test: armour removed
  sigma[Soil]     = sigma_Soil;
  sigma[SemiIn]   = sigma_Semi;
  sigma[SemiOut]  = sigma_Semi;
  sigma[Region[{XLPE, Filling, Outer}]] = 0.0;

  mur_eff = (Flag_Armour && !Flag_OneCore) ? mur_Armour : 1.0;
  nu[Region[{Inds, XLPE, SemiIn, SemiOut, Lead, Filling, Outer, Soil}]] = 1.0/mu0;
  nu[Steel] = 1.0/(mu0*mur_eff);

  // stranded conductors: Ns turns, section Sc
  Ns[] = 1;
  Sc[] = Pi*(r_cond_mm*1e-3)^2;
  js0[] = 0;
}

Constraint {
  { Name MagneticVectorPotential_2D;
    Case { If(Flag_BC == 0) { Region OuterBC; Value 0.0; } EndIf }   // n x a = 0 on the truncation boundary (Flag_BC = 0)
  }
  { Name Current_2D;
    Case {
      If(Flag_OneCore)
        { Region Ind_1; Value Ipk*Complex[Cos[Pa], Sin[Pa]]; }
        { Region Ind_2; Value 0.0; }
        { Region Ind_3; Value 0.0; }
      Else
        { Region Ind_1; Value Ipk*Complex[Cos[Pa], Sin[Pa]]; }
        { Region Ind_2; Value Ipk*Complex[Cos[Pb], Sin[Pb]]; }
        { Region Ind_3; Value Ipk*Complex[Cos[Pc], Sin[Pc]]; }
      EndIf
      { Region Soil; Value 0.0; }                      // no net current in the seabed
      If(Flag_Semi) { Region SemiIn; Value 0.0; } { Region SemiOut; Value 0.0; } EndIf
      If(Flag_Bonding == 2)                            // single-point bonding: net sheath/armour current = 0
        { Region Lead; Value 0.0; }
        { Region Steel; Value 0.0; }
      EndIf
    }
  }
  { Name Voltage_2D;
    Case {
      If(Flag_Bonding == 1)                            // solid bonding: U' = 0 in every sheath and in the armour
        { Region Lead;  Value 0.0; }
        { Region Steel; Value 0.0; }
      EndIf
    }
  }
}

Include "Jacobian_Integration.pro"
Include "magnetodynamic_formulation.pro"
