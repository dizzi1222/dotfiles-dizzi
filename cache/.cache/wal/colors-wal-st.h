const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#0c0505", /* black   */
  [1] = "#AB1A11", /* red     */
  [2] = "#A32722", /* green   */
  [3] = "#D71F16", /* yellow  */
  [4] = "#D62116", /* blue    */
  [5] = "#A95E5B", /* magenta */
  [6] = "#9E807E", /* cyan    */
  [7] = "#c2c0c0", /* white   */

  /* 8 bright colors */
  [8]  = "#675555",  /* black   */
  [9]  = "#AB1A11",  /* red     */
  [10] = "#A32722", /* green   */
  [11] = "#D71F16", /* yellow  */
  [12] = "#D62116", /* blue    */
  [13] = "#A95E5B", /* magenta */
  [14] = "#9E807E", /* cyan    */
  [15] = "#c2c0c0", /* white   */

  /* special colors */
  [256] = "#0c0505", /* background */
  [257] = "#c2c0c0", /* foreground */
  [258] = "#c2c0c0",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
