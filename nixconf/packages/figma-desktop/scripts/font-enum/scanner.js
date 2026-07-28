'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const FONT_EXT = /\.(ttf|otf|ttc|otc)$/i;

function defaultDirectories() {
	const home = os.homedir();
	const xdgDataHome = process.env.XDG_DATA_HOME || path.join(home, '.local', 'share');
	return [
		path.join(xdgDataHome, 'fonts'),
		path.join(home, '.fonts'),
		'/usr/local/share/fonts',
		'/usr/share/fonts',
	];
}

function tryFcList() {
	try {
		// Pattern ":" matches all fonts; element "file" restricts output to just
		// the file path. The two arguments must stay separate — passing ":file"
		// as a single argument is parsed as a pattern (not an element selector)
		// and fc-list falls back to its default full-record format
		// "/path/to/font.ttf: Family:style=Style", which the regex below would
		// reject and cause this whole branch to silently return nothing.
		const out = execFileSync('fc-list', [':', 'file'], {
			encoding: 'utf8',
			maxBuffer: 32 * 1024 * 1024,
			stdio: ['ignore', 'pipe', 'ignore'],
			timeout: 10000,
		});
		const paths = new Set();
		for (const line of out.split('\n')) {
			// Each line from `fc-list : file` is "/path/to/font.ttf:" (trailing colon).
			const trimmed = line.trim();
			if (!trimmed) continue;
			const stripped = trimmed.replace(/:$/, '');
			if (FONT_EXT.test(stripped)) paths.add(stripped);
		}
		return [...paths];
	} catch {
		return null;
	}
}

function walkDir(dir, found, visited, depth) {
	if (depth > 10) return;
	let real;
	try {
		real = fs.realpathSync(dir);
	} catch {
		return;
	}
	if (visited.has(real)) return;
	visited.add(real);
	let entries;
	try {
		entries = fs.readdirSync(dir, { withFileTypes: true });
	} catch {
		return;
	}
	for (const entry of entries) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) {
			walkDir(full, found, visited, depth + 1);
		} else if (entry.isFile() && FONT_EXT.test(entry.name)) {
			found.push(full);
		} else if (entry.isSymbolicLink()) {
			let st;
			try {
				st = fs.statSync(full);
			} catch {
				continue;
			}
			if (st.isDirectory()) walkDir(full, found, visited, depth + 1);
			else if (st.isFile() && FONT_EXT.test(entry.name)) found.push(full);
		}
	}
}

function manualScan(directories) {
	const found = [];
	const visited = new Set();
	for (const dir of directories) {
		try {
			if (!fs.statSync(dir).isDirectory()) continue;
		} catch {
			continue;
		}
		walkDir(dir, found, visited, 0);
	}
	return found;
}

// Find font files via fc-list (preferred) or manual filesystem walk (fallback).
// Pass `directories` to override the defaults (used in tests).
function findFontFiles(options) {
	const opts = options || {};
	if (opts.directories) return manualScan(opts.directories);
	if (opts.useFcList !== false) {
		const fcResult = tryFcList();
		if (fcResult && fcResult.length > 0) return fcResult;
	}
	return manualScan(defaultDirectories());
}

// Stat each path; returns map path -> mtimeMs (skips missing files).
function statMTimes(paths) {
	const result = new Map();
	for (const p of paths) {
		try {
			const st = fs.statSync(p);
			result.set(p, st.mtimeMs);
		} catch {
			// missing or unreadable; skip
		}
	}
	return result;
}

module.exports = {
	findFontFiles,
	statMTimes,
	defaultDirectories,
	FONT_EXT,
};
