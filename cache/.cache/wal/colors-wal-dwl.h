/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x0c0505ff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc2c0c0ff, 0x0c0505ff, 0x675555ff },
	[SchemeSel]  = { 0xc2c0c0ff, 0xA32722ff, 0xAB1A11ff },
	[SchemeUrg]  = { 0xc2c0c0ff, 0xAB1A11ff, 0xA32722ff },
};
