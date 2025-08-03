static const char norm_fg[] = "#c5c2c6";
static const char norm_bg[] = "#1a0d1e";
static const char norm_border[] = "#6d5c70";

static const char sel_fg[] = "#c5c2c6";
static const char sel_bg[] = "#92468B";
static const char sel_border[] = "#c5c2c6";

static const char urg_fg[] = "#c5c2c6";
static const char urg_bg[] = "#8C3A90";
static const char urg_border[] = "#8C3A90";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
