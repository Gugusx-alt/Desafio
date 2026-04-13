import 'package:flutter/material.dart';

// ─── Paleta principal ────────────────────────────────────────────────────────
// Identidade: tech refinada — ardósia escura + acento âmbar dourado

const Color backgroundColor  = Color(0xFF0D1117);
const Color surfaceColor      = Color(0xFF161B22);
const Color surfaceElevated   = Color(0xFF21262D);
const Color borderColor       = Color(0xFF30363D);

// Acento âmbar — destoa do roxo genérico comum em dashboards
const Color primaryColor      = Color(0xFFE6A817);
const Color primaryDim        = Color(0xFF7D5A0C);
const Color primarySurface    = Color(0xFF1F1A0A);

// Texto
const Color textPrimary       = Color(0xFFF0F6FC);
const Color textSecondary     = Color(0xFF8B949E);
const Color textMuted         = Color(0xFF484F58);

// Status
const Color statusOpen        = Color(0xFF388BFD);
const Color statusProgress    = Color(0xFFD29922);
const Color statusDone        = Color(0xFF3FB950);
const Color statusCancelled   = Color(0xFFF85149);

// Categorias
const Color categoryBug       = Color(0xFFF85149);
const Color categoryAdjust    = Color(0xFFD29922);
const Color categoryImprove   = Color(0xFF3FB950);

// Utilitários
const Color whiteColor        = Color(0xFFFFFFFF);
const Color blackColor        = Color(0xFF000000);

// ─── Raios de borda ──────────────────────────────────────────────────────────
const double radiusS  = 6.0;
const double radiusM  = 10.0;
const double radiusL  = 16.0;
const double radiusXL = 24.0;

// ─── Sombras ─────────────────────────────────────────────────────────────────
const List<BoxShadow> shadowCard = [
  BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
];

const List<BoxShadow> glowShadow = [
  BoxShadow(color: Color(0x40E6A817), blurRadius: 20, offset: Offset(0, 4)),
];

// ─── Aliases de raio (compatibilidade) ───────────────────────────────────────
const double radiusMd = radiusM;
const double radiusLg = radiusL;

// ─── Cores adicionais ─────────────────────────────────────────────────────────
const Color secondaryColor = statusOpen;   // azul — papel de admin/destaque
const Color accentColor    = statusDone;   // verde — papel de desenvolvedor
const Color primaryLight   = Color(0xFFF0C04B); // âmbar claro

// ─── Gradientes ──────────────────────────────────────────────────────────────
const LinearGradient primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [primaryColor, Color(0xFF9D6E0B)],
);