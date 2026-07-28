'use strict';

const { findFontFiles, statMTimes } = require('./scanner');
const { parseAnyFontFileSync } = require('./ttc-parser');

// Module-level cache.
// State:
//   cachedFonts: Map<filePath, IFontFigmaItem[]>
//   cachedMTimes: Map<filePath, mtimeMs>
//   lastScanAt: number  (mtime threshold for getModifiedFonts; 0 means "never scanned")
let cachedFonts = new Map();
let cachedMTimes = new Map();
let lastScanAt = 0;

function resetCacheForTests() {
	cachedFonts = new Map();
	cachedMTimes = new Map();
	lastScanAt = 0;
}

function buildResultObject(fontMap) {
	const out = {};
	for (const [path, faces] of fontMap.entries()) {
		out[path] = faces;
	}
	return out;
}

function faceWithAgentMetadata(face, modifiedAtMs) {
	return {
		...face,
		modified_at: Math.floor((modifiedAtMs || 0) / 1000),
		user_installed: true,
	};
}

function buildFontFilesObject(fontMap, mtimeMap) {
	const out = {};
	for (const [p, faces] of fontMap.entries()) {
		if (faces.length > 0) {
			const modifiedAtMs = mtimeMap.get(p) || 0;
			out[p] = faces.map((face) => faceWithAgentMetadata(face, modifiedAtMs));
		}
	}
	return out;
}

function fullScan(options) {
	const paths = findFontFiles(options);
	const mtimes = statMTimes(paths);
	const fonts = new Map();
	for (const [p, mtime] of mtimes.entries()) {
		const faces = parseAnyFontFileSync(p);
		if (faces.length > 0) fonts.set(p, faces);
		else fonts.set(p, []); // remember the path so we don't re-parse on every call
	}
	cachedFonts = fonts;
	cachedMTimes = mtimes;
	lastScanAt = Date.now();
	return fonts;
}

// Public API: returns JSON string mirroring desktop_rust.getFonts() contract.
function getFonts(options) {
	const fonts = fullScan(options);
	// Drop empty arrays from final output to match Figma's expectations
	// (paths with no parseable faces are uninteresting to the renderer).
	const result = {};
	for (const [p, faces] of fonts.entries()) {
		if (faces.length > 0) result[p] = faces;
	}
	return JSON.stringify(result);
}

// Returns JSON matching neetly/figma-agent-linux's /figma/font-files endpoint.
// Figma's web surface probes this localhost helper when the user agent advertises
// a supported desktop OS, so the packaged app exposes the same shape in-process.
function getFontFilesPayload(options) {
	const fonts = fullScan(options);
	const fontFiles = buildFontFilesObject(fonts, cachedMTimes);
	return JSON.stringify({
		fontFiles,
		modified_at: null,
		modified_fonts: null,
		package: 'figma-agent-linux',
		version: 1,
	});
}

// Returns the most recent mtime across known font files (in ms).
// Cheap: re-stats only, no font parsing. Mirrors desktop_rust.getFontsModifiedAt().
function getFontsModifiedAt(options) {
	const paths = findFontFiles(options);
	const mtimes = statMTimes(paths);
	let max = 0;
	for (const m of mtimes.values()) if (m > max) max = m;
	// Account for deletions: if a previously-cached file is gone, that's a change too.
	for (const p of cachedMTimes.keys()) {
		if (!mtimes.has(p)) {
			max = Math.max(max, Date.now());
			break;
		}
	}
	return Math.floor(max);
}

// Returns JSON string with only fonts whose mtime > lastScanAt OR whose path is new.
// Updates cache so subsequent calls only return further changes.
function getModifiedFonts(options) {
	const paths = findFontFiles(options);
	const mtimes = statMTimes(paths);
	const result = {};
	const newCachedFonts = new Map();

	for (const [p, mtime] of mtimes.entries()) {
		const previousMtime = cachedMTimes.get(p);
		const isNew = previousMtime === undefined;
		const isChanged = !isNew && mtime > previousMtime;
		if (isNew || isChanged) {
			const faces = parseAnyFontFileSync(p);
			if (faces.length > 0) {
				result[p] = faces;
				newCachedFonts.set(p, faces);
			} else {
				newCachedFonts.set(p, []);
			}
		} else {
			newCachedFonts.set(p, cachedFonts.get(p) || []);
		}
	}

	cachedFonts = newCachedFonts;
	cachedMTimes = mtimes;
	lastScanAt = Date.now();
	return JSON.stringify(result);
}

function hasKnownFontFile(filePath) {
	return cachedFonts.has(filePath) && (cachedFonts.get(filePath) || []).length > 0;
}

module.exports = {
	getFonts,
	getFontFilesPayload,
	getFontsModifiedAt,
	getModifiedFonts,
	hasKnownFontFile,
	// Test-only helpers (not part of the public contract).
	_internal: {
		resetCacheForTests,
		buildResultObject,
		buildFontFilesObject,
		fullScan,
	},
};
