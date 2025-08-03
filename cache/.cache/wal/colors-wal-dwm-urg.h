static const char norm_fg[] = "#c2c0c0";
static const char norm_bg[] = "#0c0505";
static const char norm_border[] = "#675555";

static const char sel_fg[] = "#c2c0c0";
static const char sel_bg[] = "#A32722";
static const char sel_border[] = "#c2c0c0";

static const char urg_fg[] = "#c2c0c0";
static const char urg_bg[] = "#AB1A11";
static const char urg_border[] = "#AB1A11";

static const char *colors[][3]      = {
    /*               fg           bg         border                         */
    [SchemeNorm] = { norm_fg,     norm_bg,   norm_border }, // unfocused wins
    [SchemeSel]  = { sel_fg,      sel_bg,    sel_border },  // the focused win
    [SchemeUrg] =  { urg_fg,      urg_bg,    urg_border },
};
