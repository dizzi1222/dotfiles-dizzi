'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const fontEnum = require('../index');
const { buildTTF } = require('./fixture-builder');

function makeTempFontDir() {
	return fs.mkdtempSync(path.join(os.tmpdir(), 'fontcache-'));
}

// Bump mtime forward by setting it explicitly. We use fs.utimesSync to set future mtime
// which avoids race conditions with the previous getFonts call that might have happened
// in the same millisecond.
function bumpMtime(file, deltaMs) {
	const future = new Date(Date.now() + deltaMs);
	fs.utimesSync(file, future, future);
	return future.getTime();
}

test('getFontsModifiedAt() returns the maximum mtime in ms', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const a = path.join(dir, 'a.ttf');
		const b = path.join(dir, 'b.ttf');
		fs.writeFileSync(a, buildTTF({ family: 'A', style: 'Regular' }));
		fs.writeFileSync(b, buildTTF({ family: 'B', style: 'Regular' }));
		const newest = bumpMtime(b, 60000); // 1 minute in the future

		const result = fontEnum.getFontsModifiedAt({ directories: [dir] });
		assert.equal(typeof result, 'number');
		assert.ok(result >= Math.floor(newest) - 1, `expected >= ${newest}, got ${result}`);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getFontsModifiedAt() returns 0 for empty directory', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		assert.equal(fontEnum.getFontsModifiedAt({ directories: [dir] }), 0);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getModifiedFonts() returns all fonts on first call (none previously cached)', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const a = path.join(dir, 'a.ttf');
		const b = path.join(dir, 'b.ttf');
		fs.writeFileSync(a, buildTTF({ family: 'A', style: 'Regular' }));
		fs.writeFileSync(b, buildTTF({ family: 'B', style: 'Regular' }));

		const parsed = JSON.parse(fontEnum.getModifiedFonts({ directories: [dir] }));
		assert.equal(Object.keys(parsed).length, 2);
		assert.ok(parsed[a] && parsed[a][0].family === 'A');
		assert.ok(parsed[b] && parsed[b][0].family === 'B');
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getModifiedFonts() returns empty {} when nothing has changed since last call', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'a.ttf'), buildTTF({ family: 'A', style: 'Regular' }));
		// Prime the cache.
		fontEnum.getModifiedFonts({ directories: [dir] });
		// Second call with no changes:
		const parsed = JSON.parse(fontEnum.getModifiedFonts({ directories: [dir] }));
		assert.deepEqual(parsed, {});
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getModifiedFonts() returns only changed files on second call', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const a = path.join(dir, 'a.ttf');
		const b = path.join(dir, 'b.ttf');
		fs.writeFileSync(a, buildTTF({ family: 'A', style: 'Regular' }));
		fs.writeFileSync(b, buildTTF({ family: 'B', style: 'Regular' }));
		// Prime the cache so both are known.
		fontEnum.getModifiedFonts({ directories: [dir] });

		// Touch only b with a future mtime.
		bumpMtime(b, 60000);
		const parsed = JSON.parse(fontEnum.getModifiedFonts({ directories: [dir] }));
		const names = Object.keys(parsed).map((p) => path.basename(p));
		assert.deepEqual(names, ['b.ttf']);
		assert.equal(parsed[b][0].family, 'B');
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getModifiedFonts() picks up newly added files', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'a.ttf'), buildTTF({ family: 'A', style: 'Regular' }));
		fontEnum.getModifiedFonts({ directories: [dir] });

		// Add a new font after first scan.
		const newPath = path.join(dir, 'new.ttf');
		fs.writeFileSync(newPath, buildTTF({ family: 'New', style: 'Regular' }));

		const parsed = JSON.parse(fontEnum.getModifiedFonts({ directories: [dir] }));
		const names = Object.keys(parsed).map((p) => path.basename(p));
		assert.deepEqual(names, ['new.ttf']);
		assert.equal(parsed[newPath][0].family, 'New');
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getFonts() repopulates the cache (does not error on cache reset)', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'a.ttf'), buildTTF({ family: 'A', style: 'Regular' }));
		const json1 = fontEnum.getFonts({ directories: [dir] });
		fontEnum._internal.resetCacheForTests();
		const json2 = fontEnum.getFonts({ directories: [dir] });
		assert.equal(json1, json2, 'getFonts should be deterministic for the same directory');
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});
