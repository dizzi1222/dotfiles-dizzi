'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const { findFontFiles, statMTimes } = require('../scanner');
const { buildTTF } = require('./fixture-builder');

function makeTempFontDir() {
	return fs.mkdtempSync(path.join(os.tmpdir(), 'fontscan-'));
}

test('finds .ttf, .otf, .ttc files in a directory and ignores other files', () => {
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'a.ttf'), buildTTF({ family: 'A', style: 'Regular' }));
		fs.writeFileSync(path.join(dir, 'b.otf'), buildTTF({ family: 'B', style: 'Regular' }));
		fs.writeFileSync(path.join(dir, 'c.ttc'), Buffer.from('ttcfdummy'));
		fs.writeFileSync(path.join(dir, 'README.txt'), 'not a font');
		fs.writeFileSync(path.join(dir, 'image.png'), Buffer.from([0x89, 0x50, 0x4e, 0x47]));

		const found = findFontFiles({ directories: [dir] });
		const names = found.map((p) => path.basename(p)).sort();
		assert.deepEqual(names, ['a.ttf', 'b.otf', 'c.ttc']);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('recurses into subdirectories', () => {
	const dir = makeTempFontDir();
	try {
		const sub = path.join(dir, 'nested', 'deep');
		fs.mkdirSync(sub, { recursive: true });
		fs.writeFileSync(path.join(sub, 'deep.ttf'), buildTTF({ family: 'Deep', style: 'Regular' }));
		fs.writeFileSync(path.join(dir, 'top.ttf'), buildTTF({ family: 'Top', style: 'Regular' }));

		const found = findFontFiles({ directories: [dir] });
		const names = found.map((p) => path.basename(p)).sort();
		assert.deepEqual(names, ['deep.ttf', 'top.ttf']);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('survives non-existent directories without throwing', () => {
	const found = findFontFiles({ directories: ['/no/such/dir', '/another/missing/path'] });
	assert.deepEqual(found, []);
});

test('survives unreadable subdirectory by skipping it', () => {
	const dir = makeTempFontDir();
	try {
		const goodSub = path.join(dir, 'good');
		const blockedSub = path.join(dir, 'blocked');
		fs.mkdirSync(goodSub);
		fs.mkdirSync(blockedSub);
		fs.writeFileSync(path.join(goodSub, 'good.ttf'), buildTTF({ family: 'Good', style: 'Regular' }));
		fs.writeFileSync(path.join(blockedSub, 'inside.ttf'), buildTTF({ family: 'Inside', style: 'Regular' }));
		// Remove read+execute permissions on blockedSub. As root this is bypassed,
		// so we accept either outcome (skipped or included).
		fs.chmodSync(blockedSub, 0o000);
		try {
			const found = findFontFiles({ directories: [dir] });
			const names = found.map((p) => path.basename(p));
			assert.ok(names.includes('good.ttf'), 'good.ttf must be discovered');
			assert.ok(found.length >= 1, 'scanner must not crash on unreadable dirs');
		} finally {
			fs.chmodSync(blockedSub, 0o700);
		}
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('does not loop on symlink cycles', () => {
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'real.ttf'), buildTTF({ family: 'Real', style: 'Regular' }));
		const sub = path.join(dir, 'cycle');
		fs.mkdirSync(sub);
		// link sub/back -> dir, creating a cycle
		fs.symlinkSync(dir, path.join(sub, 'back'));

		const found = findFontFiles({ directories: [dir] });
		const names = found.map((p) => path.basename(p));
		assert.ok(names.includes('real.ttf'));
		// We should hit the file at most a small bounded number of times despite the cycle.
		assert.ok(found.length < 10, `cycle protection failed: ${found.length} entries found`);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('statMTimes returns a Map with mtimeMs for present files only', () => {
	const dir = makeTempFontDir();
	try {
		const a = path.join(dir, 'a.ttf');
		fs.writeFileSync(a, 'x');
		const map = statMTimes([a, '/no/such/file.ttf']);
		assert.equal(map.size, 1);
		assert.equal(typeof map.get(a), 'number');
		assert.ok(map.get(a) > 0);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('case-insensitive font extension matching (.TTF, .Otf)', () => {
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'upper.TTF'), buildTTF({ family: 'Upper', style: 'Regular' }));
		fs.writeFileSync(path.join(dir, 'mixed.Otf'), buildTTF({ family: 'Mixed', style: 'Regular' }));

		const found = findFontFiles({ directories: [dir] });
		const names = found.map((p) => path.basename(p)).sort();
		assert.deepEqual(names, ['mixed.Otf', 'upper.TTF']);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});
