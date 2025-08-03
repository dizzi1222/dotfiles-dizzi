/* Taken from https://github.com/djpohly/dwl/issues/466 */
#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

static const float rootcolor[]             = COLOR(0x1a0d1eff);
static uint32_t colors[][3]                = {
	/*               fg          bg          border    */
	[SchemeNorm] = { 0xc5c2c6ff, 0x1a0d1eff, 0x6d5c70ff },
	[SchemeSel]  = { 0xc5c2c6ff, 0x92468Bff, 0x8C3A90ff },
	[SchemeUrg]  = { 0xc5c2c6ff, 0x8C3A90ff, 0x92468Bff },
};
