const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1a0d1e", /* black   */
  [1] = "#8C3A90", /* red     */
  [2] = "#92468B", /* green   */
  [3] = "#A96196", /* yellow  */
  [4] = "#C579B3", /* blue    */
  [5] = "#358B9B", /* magenta */
  [6] = "#39A9AF", /* cyan    */
  [7] = "#c5c2c6", /* white   */

  /* 8 bright colors */
  [8]  = "#6d5c70",  /* black   */
  [9]  = "#8C3A90",  /* red     */
  [10] = "#92468B", /* green   */
  [11] = "#A96196", /* yellow  */
  [12] = "#C579B3", /* blue    */
  [13] = "#358B9B", /* magenta */
  [14] = "#39A9AF", /* cyan    */
  [15] = "#c5c2c6", /* white   */

  /* special colors */
  [256] = "#1a0d1e", /* background */
  [257] = "#c5c2c6", /* foreground */
  [258] = "#c5c2c6",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
