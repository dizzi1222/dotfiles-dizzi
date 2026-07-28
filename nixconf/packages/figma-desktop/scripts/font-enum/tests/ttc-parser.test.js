'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const { parseCollectionSync, parseAnyFontFileSync } = require('../ttc-parser');
const { buildTTC, buildTTF } = require('./fixture-builder');

function withTempFile(buffer, ext, fn) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fontenum-'));
	const file = path.join(dir, `fixture${ext}`);
	fs.writeFileSync(file, buffer);
	try {
		return fn(file);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
}

test('parses 3-face TTC with each face independently', () => {
	const buf = buildTTC([
		{ family: 'Helvetica', style: 'Regular', weight: 400 },
		{ family: 'Helvetica', style: 'Bold', weight: 700 },
		{ family: 'Helvetica', style: 'Bold Italic', weight: 700, italic: true },
	]);
	withTempFile(buf, '.ttc', (file) => {
		const faces = parseCollectionSync(file);
		assert.equal(faces.length, 3);
		assert.equal(faces[0].family, 'Helvetica');
		assert.equal(faces[0].style, 'Regular');
		assert.equal(faces[0].weight, 400);
		assert.equal(faces[0].italic, false);

		assert.equal(faces[1].weight, 700);
		assert.equal(faces[1].italic, false);

		assert.equal(faces[2].weight, 700);
		assert.equal(faces[2].italic, true);
		assert.equal(faces[2].style, 'Bold Italic');
	});
});

test('parseAnyFontFileSync dispatches TTC -> collection parser', () => {
	const buf = buildTTC([
		{ family: 'A', style: 'Regular' },
		{ family: 'B', style: 'Regular' },
	]);
	withTempFile(buf, '.ttc', (file) => {
		const faces = parseAnyFontFileSync(file);
		assert.equal(faces.length, 2);
		assert.equal(faces[0].family, 'A');
		assert.equal(faces[1].family, 'B');
	});
});

test('parseAnyFontFileSync dispatches plain TTF -> single-face parser', () => {
	const buf = buildTTF({ family: 'Solo', style: 'Regular' });
	withTempFile(buf, '.ttf', (file) => {
		const faces = parseAnyFontFileSync(file);
		assert.equal(faces.length, 1);
		assert.equal(faces[0].family, 'Solo');
	});
});

test('parseCollectionSync returns empty for non-TTC file', () => {
	const buf = buildTTF({ family: 'NotATTC', style: 'Regular' });
	withTempFile(buf, '.ttf', (file) => {
		assert.deepEqual(parseCollectionSync(file), []);
	});
});

test('handles TTC with bogus numFonts header', () => {
	const buf = Buffer.alloc(64);
	buf.write('ttcf', 0, 4, 'latin1');
	buf.writeUInt32BE(99999, 8); // numFonts way too high
	withTempFile(buf, '.ttc', (file) => {
		// We allow up to 1024 fonts; 99999 is rejected outright.
		assert.deepEqual(parseCollectionSync(file), []);
	});
});
