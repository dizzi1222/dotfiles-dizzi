// Inject frame fix before main app loads
const Module = require('module');
const originalRequire = Module.prototype.require;

console.log('[Frame Fix] Wrapper loaded');

const WIN_USER_AGENT = `Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${process.versions.chrome} Safari/537.36`;

function applyWindowsUserAgent(webContents) {
	if (process.platform !== 'linux' || !webContents) return;
	try {
		webContents.setUserAgent(WIN_USER_AGENT);
	} catch (_err) {
		// Some utility views may not expose a mutable user agent.
	}
}

// Build the patched BrowserWindow class and Menu interceptor once,
// on first require('electron'), then reuse via Proxy on every access.
let PatchedBrowserWindow = null;
let PatchedWebContentsView = null;
let PatchedBrowserView = null;
let patchedSetApplicationMenu = null;

Module.prototype.require = function(id) {
	const result = originalRequire.apply(this, arguments);

	if (id === 'electron' || id === 'electron/main') {
		// Build patches once from the real electron module
		if (!PatchedBrowserWindow) {
			console.log('[Frame Fix] Intercepting electron module');
			const OriginalBrowserWindow = result.BrowserWindow;
			const OriginalWebContentsView = result.WebContentsView;
			const OriginalBrowserView = result.BrowserView;
			const OriginalMenu = result.Menu;

			PatchedBrowserWindow = class BrowserWindowWithFrame extends OriginalBrowserWindow {
				constructor(options) {
					// Detect tray window by its preload script path
					const preloadPath = options?.webPreferences?.preload || '';
					const isTrayWindow = preloadPath.includes('tray_binding_renderer');

					if (isTrayWindow) {
						console.log('[Frame Fix] Tray notification BrowserWindow detected');
					} else {
						console.log('[Frame Fix] BrowserWindow constructor called');
					}

					if (process.platform === 'linux') {
						options = options || {};
						const originalFrame = options.frame;
						// Force native frame
						options.frame = true;
						// Hide the menu bar by default (Alt key will toggle it)
						options.autoHideMenuBar = true;
						// Remove custom titlebar options
						delete options.titleBarStyle;
						delete options.titleBarOverlay;
						console.log(`[Frame Fix] Modified frame from ${originalFrame} to true`);
					}
					super(options);

					if (process.platform === 'linux') {
						if (!isTrayWindow) {
							applyWindowsUserAgent(this.webContents);
						}

						// Hide menu bar after window creation
						this.setMenuBarVisibility(false);

						// Ensure menu bar stays hidden on show events
						this.on('show', () => {
							this.setMenuBarVisibility(false);
						});

						if (!isTrayWindow) {
							// Patch getContentBounds() to read from getSize() directly,
							// bypassing Chromium's LayoutManagerBase cache. The cache is
							// only invalidated via OnWindowStateChanged() -> ScheduleRelayout()
							// -> InvalidateLayout(), which requires _NET_WM_STATE atom changes.
							// KWin's corner-snap/quick-tile and Wayland compositors never set
							// those atoms, so the cache stays stale after tiling/maximize.
							// getSize() reads from Widget/platform window bounds updated by
							// X11 ConfigureNotify before JS events fire, so it always reflects
							// the real geometry. Under XWayland, frame overhead is 0x0 (WM
							// draws outside app bounds), so frameW/H will calibrate to zero.
							let frameW = 0;
							let frameH = 0;
							let calibrated = false;
							const origGetContentBounds = this.getContentBounds.bind(this);

							this.getContentBounds = () => {
								if (calibrated && !this.isDestroyed()) {
									const [w, h] = this.getSize();
									const width = w - frameW;
									const height = h - frameH;
									// Guard against stale/invalid getSize() data during
									// transitions — fall back rather than set child to 0x0.
									if (width > 0 && height > 0) {
										return { x: 0, y: 0, width, height };
									}
								}
								return origGetContentBounds();
							};

							// For maximize/unmaximize/fullscreen, Chromium's layout cache
							// is definitively stale. Re-emit resize twice — immediately
							// and after one frame — so the app's layout handler runs with
							// fresh getSize() data from our patched getContentBounds().
							const reemitResize = () => {
								if (this.isDestroyed()) return;
								this.emit('resize');
								setTimeout(() => {
									if (!this.isDestroyed()) this.emit('resize');
								}, 16);
							};

							this.on('maximize', reemitResize);
							this.on('unmaximize', reemitResize);
							this.on('enter-full-screen', reemitResize);
							this.on('leave-full-screen', reemitResize);

							// ready-to-show fires once per window lifecycle
							this.once('ready-to-show', () => {
								this.setMenuBarVisibility(false);
								// One-time jiggle for initial layout
								const [w, h] = this.getSize();
								this.setSize(w + 1, h + 1);
								setTimeout(() => {
									if (this.isDestroyed()) return;
									this.setSize(w, h);
									// Calibrate frame overhead after layout stabilizes.
									// origGetContentBounds() is accurate at rest; stale data
									// only occurs during active geometry operations.
									setTimeout(() => {
										if (this.isDestroyed()) return;
										const [winW, winH] = this.getSize();
										const cb = origGetContentBounds();
										const fw = winW - cb.width;
										const fh = winH - cb.height;
										// Reject if content bounds are zero or overhead is
										// implausibly large (would indicate a bad read).
										if (cb.width > 0 && cb.height > 0 && fw >= 0 && fh >= 0
											&& fw < 200 && fh < 200) {
											frameW = fw;
											frameH = fh;
											calibrated = true;
											console.log(`[Frame Fix] Frame overhead calibrated: ${fw}x${fh}`);
										} else {
											console.log(`[Frame Fix] Calibration failed, using fallback. win=${winW}x${winH} content=${cb.width}x${cb.height}`);
											// Fallback: assume zero frame overhead (safe for XWayland/Wayland)
											frameW = 0;
											frameH = 0;
											calibrated = true;
										}
									}, 100);
								}, 50);
							});

							// Fallback calibration if ready-to-show doesn't fire
							this.once('show', () => {
								setTimeout(() => {
									if (this.isDestroyed() || calibrated) return;
									console.log('[Frame Fix] Fallback calibration via show event');
									const [winW, winH] = this.getSize();
									const cb = origGetContentBounds();
									const fw = winW - cb.width;
									const fh = winH - cb.height;
									if (cb.width > 0 && cb.height > 0 && fw >= 0 && fh >= 0
										&& fw < 200 && fh < 200) {
										frameW = fw;
										frameH = fh;
									}
									calibrated = true;
									console.log(`[Frame Fix] Fallback calibrated: ${frameW}x${frameH}`);
								}, 500);
							});
						}

						// Debug: open DevTools for tray notification window
						if (isTrayWindow && process.env.FIGMA_DEBUG === '1') {
							console.log('[Frame Fix] DEBUG: Opening DevTools for tray window');
							this.webContents.on('dom-ready', () => {
								this.webContents.openDevTools({ mode: 'detach' });
							});
						}

						console.log('[Frame Fix] Linux patches applied');
					}
				}
			};

			if (OriginalWebContentsView) {
				PatchedWebContentsView = class WebContentsViewWithUserAgent extends OriginalWebContentsView {
					constructor(options) {
						super(options);
						applyWindowsUserAgent(this.webContents);
					}
				};
			}

			if (OriginalBrowserView) {
				PatchedBrowserView = class BrowserViewWithUserAgent extends OriginalBrowserView {
					constructor(options) {
						super(options);
						applyWindowsUserAgent(this.webContents);
					}
				};
			}

			// Copy static methods and properties from original
			for (const key of Object.getOwnPropertyNames(OriginalBrowserWindow)) {
				if (key !== 'prototype' && key !== 'length' && key !== 'name') {
					try {
						const descriptor = Object.getOwnPropertyDescriptor(OriginalBrowserWindow, key);
						if (descriptor) {
							Object.defineProperty(PatchedBrowserWindow, key, descriptor);
						}
					} catch (e) {
						// Ignore errors for non-configurable properties
					}
				}
			}

			// Intercept Menu.setApplicationMenu to hide menu bar on Linux
			const originalSetAppMenu = OriginalMenu.setApplicationMenu.bind(OriginalMenu);
			patchedSetApplicationMenu = function(menu) {
				console.log('[Frame Fix] Intercepting setApplicationMenu');
				originalSetAppMenu(menu);
				if (process.platform === 'linux') {
					for (const win of PatchedBrowserWindow.getAllWindows()) {
						if (win.isDestroyed()) continue;
						win.setMenuBarVisibility(false);
					}
					console.log('[Frame Fix] Menu bar hidden on all windows');
				}
			};

			console.log('[Frame Fix] Patches built successfully');
		}

		// Return a Proxy that intercepts property access on the electron module.
		// This is needed because electron's exports use non-configurable getters,
		// so we cannot directly reassign module.BrowserWindow.
		return new Proxy(result, {
			get(target, prop, receiver) {
				if (prop === 'BrowserWindow') return PatchedBrowserWindow;
				if (prop === 'WebContentsView' && PatchedWebContentsView) return PatchedWebContentsView;
				if (prop === 'BrowserView' && PatchedBrowserView) return PatchedBrowserView;
				if (prop === 'Menu') {
					// Return a proxy for Menu that intercepts setApplicationMenu
					const originalMenu = target.Menu;
					return new Proxy(originalMenu, {
						get(menuTarget, menuProp) {
							if (menuProp === 'setApplicationMenu') return patchedSetApplicationMenu;
							return Reflect.get(menuTarget, menuProp);
						}
					});
				}
				return Reflect.get(target, prop, receiver);
			}
		});
	}

	return result;
};
