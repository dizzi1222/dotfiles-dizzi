// Stub implementation of Figma native modules (bindings.node + desktop_rust.node) for Linux
// These modules are Windows-specific native addons that need stubbing on Linux

let nativeTheme = null;
try {
	nativeTheme = require('electron').nativeTheme;
} catch (e) {
	// May fail in utility process where electron main APIs aren't available
}

// Optional integration with external font agents such as neetly/figma-agent-linux.
// Figma's desktop_rust.getFonts() API is synchronous, so network I/O happens in
// the background and getFonts() returns the latest cached agent result when one
// is available. The built-in JS font scanner remains the fallback.
const http = require('http');
const fs = require('fs');
const { URL } = require('url');

const FONT_AGENT_URL = process.env.FIGMA_FONT_AGENT_URL || 'http://127.0.0.1:44950/figma/font-files';
const FONT_AGENT_DISABLED = process.env.FIGMA_FONT_AGENT_DISABLED === '1';
const BUILTIN_FONT_AGENT_DISABLED = process.env.FIGMA_BUILTIN_FONT_AGENT_DISABLED === '1';
const FONTS_CACHE_TTL_MS = 60_000;

let cachedAgentFontsJson = null;
let cachedAgentFontsTimestamp = 0;
let fetchInProgress = false;
let builtInFontAgentServer = null;

function normalizeAgentFontsResponse(data) {
	try {
		const parsed = JSON.parse(data);
		if (parsed && typeof parsed === 'object' && parsed.fontFiles && typeof parsed.fontFiles === 'object') {
			return JSON.stringify(parsed.fontFiles);
		}
		if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
			return JSON.stringify(parsed);
		}
	} catch (_err) {
		// Ignore malformed agent responses and keep the local scanner fallback.
	}
	return null;
}

function fetchAgentFontsInBackground() {
	if (FONT_AGENT_DISABLED || fetchInProgress) return;
	fetchInProgress = true;

	try {
		const req = http.get(FONT_AGENT_URL, { timeout: 2000 }, (res) => {
			let data = '';
			res.setEncoding('utf8');
			res.on('data', (chunk) => { data += chunk; });
			res.on('end', () => {
				fetchInProgress = false;
				if (res.statusCode !== 200) return;
				const normalized = normalizeAgentFontsResponse(data);
				if (!normalized) return;
				cachedAgentFontsJson = normalized;
				cachedAgentFontsTimestamp = Date.now();
			});
		});
		req.on('error', () => { fetchInProgress = false; });
		req.on('timeout', () => {
			req.destroy();
			fetchInProgress = false;
		});
	} catch (_err) {
		fetchInProgress = false;
	}
}

function getFontsFromExternalAgent() {
	if (FONT_AGENT_DISABLED) return null;
	if (!cachedAgentFontsJson || Date.now() - cachedAgentFontsTimestamp >= FONTS_CACHE_TTL_MS) {
		fetchAgentFontsInBackground();
	}
	return cachedAgentFontsJson;
}

function writeAgentCorsHeaders(res) {
	res.setHeader('Access-Control-Allow-Origin', 'https://www.figma.com');
	res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
	res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
	res.setHeader('Access-Control-Allow-Private-Network', 'true');
	res.setHeader('Vary', 'Origin');
}

function sendAgentJson(res, statusCode, payload) {
	writeAgentCorsHeaders(res);
	res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
	res.end(payload);
}

function serveKnownFontFile(reqUrl, res) {
	let filePath = '';
	try {
		filePath = reqUrl.searchParams.get('file') || '';
	} catch (_err) {
		filePath = '';
	}
	if (!filePath) {
		sendAgentJson(res, 400, JSON.stringify({ error: 'missing file' }));
		return;
	}

	// Refresh the cache, then only serve files that the scanner identified as
	// fonts. This keeps the local helper from becoming an arbitrary file server.
	try {
		fontEnum.getFonts();
	} catch (_err) {
		sendAgentJson(res, 500, JSON.stringify({ error: 'font scan failed' }));
		return;
	}

	if (!fontEnum.hasKnownFontFile(filePath)) {
		sendAgentJson(res, 404, JSON.stringify({ error: 'font not found' }));
		return;
	}

	writeAgentCorsHeaders(res);
	res.writeHead(200, { 'Content-Type': 'application/octet-stream' });
	fs.createReadStream(filePath)
		.on('error', () => {
			if (!res.headersSent) {
				sendAgentJson(res, 404, JSON.stringify({ error: 'font not found' }));
			} else {
				res.destroy();
			}
		})
		.pipe(res);
}

function startBuiltInFontAgent() {
	if (BUILTIN_FONT_AGENT_DISABLED || builtInFontAgentServer || !fontEnum) return;

	let bindUrl;
	try {
		bindUrl = new URL(FONT_AGENT_URL);
	} catch (_err) {
		bindUrl = new URL('http://127.0.0.1:44950/figma/font-files');
	}

	const hostname = bindUrl.hostname || '127.0.0.1';
	const port = Number(bindUrl.port || 44950);
	const server = http.createServer((req, res) => {
		writeAgentCorsHeaders(res);
		if (req.method === 'OPTIONS') {
			res.writeHead(204);
			res.end();
			return;
		}
		if (req.method !== 'GET') {
			sendAgentJson(res, 405, JSON.stringify({ error: 'method not allowed' }));
			return;
		}

		const reqUrl = new URL(req.url || '/', `http://${hostname}:${port}`);
		if (reqUrl.pathname === '/figma/version') {
			sendAgentJson(res, 200, JSON.stringify({ package: 'figma-agent-linux', version: 1 }));
		} else if (reqUrl.pathname === '/figma/font-files') {
			sendAgentJson(res, 200, fontEnum.getFontFilesPayload());
		} else if (reqUrl.pathname === '/figma/font-file') {
			serveKnownFontFile(reqUrl, res);
		} else if (reqUrl.pathname === '/figma/font-preview') {
			// Font preview is optional in neetly/figma-agent-linux. Figma can still
			// load and use the fonts when this endpoint is unavailable.
			sendAgentJson(res, 404, JSON.stringify({ error: 'font preview unavailable' }));
		} else {
			sendAgentJson(res, 404, JSON.stringify({ error: 'not found' }));
		}
	});

	server.on('error', (err) => {
		// EADDRINUSE normally means the user already runs figma-agent-linux.
		// Keep startup non-fatal and let getFonts() use the native scanner fallback.
		if (err && err.code !== 'EADDRINUSE') {
			console.error('[figma-native-stub] built-in font helper failed:', err.message);
		}
	});
	server.listen(port, hostname, () => {
		builtInFontAgentServer = server;
	});
}

// ---- bindings.node stubs ----
// All methods that xe.* references in main.js

module.exports = {
	// System detection
	isSystemDarkMode: () => nativeTheme ? nativeTheme.shouldUseDarkColors : false,
	isP3ColorSpaceCapable: () => false,
	getCurrentKeyboardLayout: () => 'com.apple.keylayout.US',
	getExecutableVersion: () => '0.0.0',
	getBundleVersion: () => '0',
	getAppPathForProtocol: () => '',
	getActiveNSScreens: () => [],
	getOSNotificationsEnabled: () => true,

	// Window management
	isWindowUnderPoint: () => false,
	getWindowUnderCursor: () => null,
	getWindowScreenshot: () => null,
	forceFocusWindow: () => {},

	// Panel management (macOS-specific NSPanel)
	makePanel: () => null,
	showPanel: () => {},
	hidePanel: () => {},
	positionPanel: () => {},
	destroyPanel: () => {},
	getPanelVisibility: () => false,

	// GPU stats (Windows-specific)
	getWindowsGPUStats: () => ({}),
	getGpuProcessMemorySharedUsageMB: () => 0,
	getGpuProcessMemoryDedicatedUsageMB: () => 0,
	getGpu3dUsageAsync: (callback) => { if (callback) callback(0); },

	// Cursor/Eyedropper (Windows/macOS native)
	startEyedropperSession: () => {},
	stopEyedropperSession: () => {},
	sampleEyedropperAtPoint: () => null,
	setEyedropperCursor: () => {},
	setDefaultCursor: () => {},
	requestEyedropperPermission: () => true,
	updateEyedropperColorSpace: () => {},
	startCursorTracker: () => {},

	// Haptic feedback (macOS-specific)
	triggerHaptic: () => {},

	// File type registration (Windows-specific)
	registerFileTypes: () => {},
	unregisterFileTypes: () => {},

	// Menu shortcuts
	setMenuShortcuts: () => {},

	// Spellcheck / Dictionary
	SetDictionary: () => {},
	GetAvailableDictionaries: () => [],

	// macOS-specific
	launchApp: () => {},
	removeBundleDirectory: () => {},
	removeAgentRegistryLoginItem: () => {},
};

// ---- desktop_rust.node replacement ----
// Used by main.js directly (kl variable) and by bindings_worker.js utility process.
// Provides font enumeration on Windows/macOS via native Rust code; on Linux we
// reimplement the same JSON contract in pure JavaScript by parsing TTF/OTF/TTC
// headers directly. See ./font-enum/ for the implementation and tests.
let fontEnum;
try {
	fontEnum = require('./font-enum');
} catch (e) {
	// Defensive fallback: if font-enum fails to load, fall back to empty results
	// rather than crashing the renderer. Logs go to the Electron console.
	console.error('[figma-native-stub] failed to load font-enum:', e && e.message);
	fontEnum = {
		getFonts: () => JSON.stringify({}),
		getFontFilesPayload: () => JSON.stringify({
			fontFiles: {},
			modified_at: null,
			modified_fonts: null,
			package: 'figma-agent-linux',
			version: 1,
		}),
		getFontsModifiedAt: () => 0,
		getModifiedFonts: () => JSON.stringify({}),
		hasKnownFontFile: () => false,
	};
}

fetchAgentFontsInBackground();
startBuiltInFontAgent();

module.exports.desktop_rust = {
	getFonts: () => getFontsFromExternalAgent() || fontEnum.getFonts(),
	getFontsModifiedAt: () => fontEnum.getFontsModifiedAt(),
	getModifiedFonts: () => fontEnum.getModifiedFonts(),
};
