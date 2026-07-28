'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const fontEnum = require('../index');
const { buildTTF, buildTTC } = require('./fixture-builder');

function makeTempFontDir() {
	return fs.mkdtempSync(path.join(os.tmpdir(), 'fontint-'));
}

// Mirrors IFontFigmaItem from old Figma-Linux: src/main/Fonts/TTF.ts:144-156.
// All 7 fields, exact types.
function assertFigmaContractShape(face, label) {
	const expectedKeys = ['postscript', 'family', 'id', 'style', 'weight', 'stretch', 'italic'];
	const actualKeys = Object.keys(face).sort();
	assert.deepEqual(actualKeys, expectedKeys.slice().sort(), `${label}: keys must match Figma contract`);
	assert.equal(typeof face.postscript, 'string', `${label}: postscript must be string`);
	assert.equal(typeof face.family, 'string', `${label}: family must be string`);
	assert.equal(typeof face.id, 'string', `${label}: id must be string`);
	assert.equal(typeof face.style, 'string', `${label}: style must be string`);
	assert.equal(typeof face.weight, 'number', `${label}: weight must be number`);
	assert.equal(typeof face.stretch, 'number', `${label}: stretch must be number`);
	assert.equal(typeof face.italic, 'boolean', `${label}: italic must be boolean`);
}

test('getFonts() returns valid JSON string with Figma-contract shape per face', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'roboto-regular.ttf'),
			buildTTF({ family: 'Roboto', style: 'Regular', weight: 400 }));
		fs.writeFileSync(path.join(dir, 'roboto-bold.ttf'),
			buildTTF({ family: 'Roboto', style: 'Bold', weight: 700 }));

		const json = fontEnum.getFonts({ directories: [dir] });
		assert.equal(typeof json, 'string', 'getFonts must return a string');
		const parsed = JSON.parse(json);

		const paths = Object.keys(parsed);
		assert.equal(paths.length, 2);
		for (const p of paths) {
			assert.ok(Array.isArray(parsed[p]), `${p} must map to an array`);
			assert.ok(parsed[p].length > 0, `${p} must have at least one face`);
			parsed[p].forEach((face, idx) => assertFigmaContractShape(face, `${p}[${idx}]`));
		}
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getFonts() handles TTC: returns one path with multiple faces', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const ttcPath = path.join(dir, 'helvetica.ttc');
		fs.writeFileSync(ttcPath, buildTTC([
			{ family: 'Helvetica', style: 'Regular', weight: 400 },
			{ family: 'Helvetica', style: 'Bold', weight: 700 },
			{ family: 'Helvetica', style: 'Italic', weight: 400, italic: true },
		]));

		const parsed = JSON.parse(fontEnum.getFonts({ directories: [dir] }));
		assert.deepEqual(Object.keys(parsed), [ttcPath]);
		assert.equal(parsed[ttcPath].length, 3);
		parsed[ttcPath].forEach((face, i) => assertFigmaContractShape(face, `face[${i}]`));
		assert.equal(parsed[ttcPath][2].italic, true);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getFonts() omits paths with no parseable faces (corrupt files)', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		fs.writeFileSync(path.join(dir, 'good.ttf'),
			buildTTF({ family: 'Good', style: 'Regular' }));
		fs.writeFileSync(path.join(dir, 'corrupt.ttf'), Buffer.from('totally not a font'));

		const parsed = JSON.parse(fontEnum.getFonts({ directories: [dir] }));
		const names = Object.keys(parsed).map((p) => path.basename(p));
		assert.deepEqual(names, ['good.ttf']);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('weight, stretch, italic round-trip through full getFonts pipeline', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const file = path.join(dir, 'condensed-italic.ttf');
		fs.writeFileSync(file, buildTTF({
			family: 'Test',
			style: 'Condensed Italic',
			postscript: 'Test-CondensedItalic',
			weight: 300,
			stretch: 3,
			italic: true,
		}));

		const parsed = JSON.parse(fontEnum.getFonts({ directories: [dir] }));
		const face = parsed[file][0];
		assert.equal(face.weight, 300);
		assert.equal(face.stretch, 3);
		assert.equal(face.italic, true);
		assert.equal(face.postscript, 'Test-CondensedItalic');
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getFonts() returns valid JSON for empty font directory', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const json = fontEnum.getFonts({ directories: [dir] });
		assert.equal(json, '{}');
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});

test('getFontFilesPayload() matches figma-agent-linux endpoint shape', () => {
	fontEnum._internal.resetCacheForTests();
	const dir = makeTempFontDir();
	try {
		const file = path.join(dir, 'agent.ttf');
		fs.writeFileSync(file, buildTTF({ family: 'Agent', style: 'Regular' }));

		const parsed = JSON.parse(fontEnum.getFontFilesPayload({ directories: [dir] }));
		assert.equal(parsed.package, 'figma-agent-linux');
		assert.equal(parsed.version, 1);
		assert.equal(parsed.modified_at, null);
		assert.equal(parsed.modified_fonts, null);
		assert.deepEqual(Object.keys(parsed.fontFiles), [file]);

		const face = parsed.fontFiles[file][0];
		for (const key of ['postscript', 'family', 'id', 'style', 'weight', 'stretch', 'italic']) {
			assert.ok(Object.hasOwn(face, key), `agent payload face: missing ${key}`);
		}
		assert.equal(typeof face.modified_at, 'number');
		assert.equal(face.user_installed, true);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
});
