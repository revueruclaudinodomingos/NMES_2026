// ============================================================
// NMES High-Voltage Cable - Parameters (Per-core lead sheaths)
// Version: V1.4 (screens aligned to ABB Table 44 capacitance; outer screen 0.6 = Open; d_trefoil 41.2 keeps 0.5 mm sheath gap)
// Units: millimetres
// Source: ABB 2GM5007 Table 44 (45 kV, 240 mm²)
// ============================================================

DefineConstant[
  // --- Core layer outer radii (mm) ---
  r_cond        = {9.05,  Name "Geometry/r_cond [mm]"},
  r_semi_in     = {10.25,  Name "Geometry/r_semi_in [mm]"},
  r_xlpe        = {18.25, Name "Geometry/r_xlpe [mm]"},
  r_semi_out    = {18.85, Name "Geometry/r_semi_out [mm]"},
  r_lead        = {20.35, Name "Geometry/r_lead [mm]"},

  // --- Layout ---
  d_trefoil     = {41.2,  Name "Geometry/d_trefoil [mm]"},

  // --- Outer layers ---
  r_fill        = {45.0,  Name "Geometry/r_fill [mm]"},
  r_armour_out  = {49.0,  Name "Geometry/r_armour_out [mm]"},
  r_outer       = {62.0,  Name "Geometry/r_outer [mm]"},
  r_soil        = {310.0, Name "Geometry/r_soil [mm]"},   // ~5× outer

  // --- Mesh sizes ---
  lc_cond       = {0.5,   Name "Mesh/lc_cond"},
  lc_semi       = {0.2,   Name "Mesh/lc_semi"},
  lc_xlpe       = {0.5,   Name "Mesh/lc_xlpe"},
  lc_lead       = {0.5,   Name "Mesh/lc_lead"},
  lc_fill       = {2.0,   Name "Mesh/lc_fill"},
  lc_armour     = {1.0,   Name "Mesh/lc_armour"},
  lc_outer      = {3.0,   Name "Mesh/lc_outer"},
  lc_soil       = {15.0,  Name "Mesh/lc_soil"}
];

r_armour_in = r_fill;                 // single source of truth
R_trefoil   = d_trefoil / Sqrt(3);

DefineConstant[ s_mesh = {1.0, Name "Mesh/Global size factor"} ];
lc_cond = lc_cond*s_mesh; lc_semi = lc_semi*s_mesh; lc_xlpe = lc_xlpe*s_mesh; lc_lead = lc_lead*s_mesh;
lc_fill = lc_fill*s_mesh; lc_armour = lc_armour*s_mesh; lc_outer = lc_outer*s_mesh; lc_soil = lc_soil*s_mesh;

DefineConstant[
  Flag_Defect = {0,    Name "Defect/Enable (0 off, 1 on)"},
  r_def       = {0.5,  Name "Defect/Radius [mm]"},
  d_def       = {11.5, Name "Defect/Distance from core C centre [mm]"}
];
lc_void = r_def/10;

