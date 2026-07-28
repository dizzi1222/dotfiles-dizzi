'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');

const { parseFontFileSync } = require('../ttf-parser');
const { buildTTF } = require('./fixture-builder');

function withTempFile(buffer, fn) {
	const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'fontenum-'));
	const file = path.join(dir, 'fixture.ttf');
	fs.writeFileSync(file, buffer);
	try {
		return fn(file);
	} finally {
		fs.rmSync(dir, { recursive: true, force: true });
	}
}

test('parses Roboto-Regular-style TTF: family/style/weight/postscript/italic', () => {
	const buf = buildTTF({
		family: 'Roboto',
		style: 'Regular',
		postscript: 'Roboto-Regular',
		weight: 400,
		stretch: 5,
		italic: false,
	});
	withTempFile(buf, (file) => {
		const faces = parseFontFileSync(file);
		assert.equal(faces.length, 1);
		const f = faces[0];
		assert.equal(f.family, 'Roboto');
		assert.equal(f.style, 'Regular');
		assert.equal(f.postscript, 'Roboto-Regular');
		assert.equal(f.weight, 400);
		assert.equal(f.stretch, 5);
		assert.equal(f.italic, false);
		assert.equal(f.id, 'Roboto');
	});
});

test('parses bold italic with non-default weight, italic flag, and stretch', () => {
	const buf = buildTTF({
		family: 'OpenSans',
		style: 'Bold Italic',
		postscript: 'OpenSans-BoldItalic',
		weight: 700,
		stretch: 3,
		italic: true,
	});
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.weight, 700);
		assert.equal(f.italic, true);
		assert.equal(f.stretch, 3);
		assert.equal(f.style, 'Bold Italic');
	});
});

test('decodes UTF-16BE name records (Cyrillic family name)', () => {
	const buf = buildTTF({
		family: 'Кириллица',
		style: 'Regular',
		postscript: 'Cyrillic-Regular',
	});
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.family, 'Кириллица');
		// Name record encoded UTF-16BE round-trips losslessly.
		assert.equal(f.family.length, 9);
	});
});

test('prefers typographic family/subfamily (nameID 16/17) over basic (1/2)', () => {
	const buf = buildTTF({
		family: 'Roboto Light', // basic family includes the weight name
		style: 'Regular',
		typographicFamily: 'Roboto', // typographic groups all weights as one family
		typographicStyle: 'Light',
		weight: 300,
	});
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.family, 'Roboto');
		assert.equal(f.style, 'Light');
		assert.equal(f.id, 'Roboto');
		assert.equal(f.weight, 300);
	});
});

test('detects italic via post.italicAngle when head.macStyle bit is unset', () => {
	const buf = buildTTF({
		family: 'TestItalic',
		style: 'Italic',
		italic: true,
	});
	// Manually clear head.macStyle (offset 44 in head table) but leave post.italicAngle non-zero.
	// Find the head table entry in the table directory and zero out macStyle in the table data.
	const numTables = buf.readUInt16BE(4);
	for (let i = 0; i < numTables; i++) {
		const recOff = 12 + i * 16;
		const tag = buf.toString('latin1', recOff, recOff + 4);
		if (tag === 'head') {
			const tableOff = buf.readUInt32BE(recOff + 8);
			buf.writeUInt16BE(0, tableOff + 44);
			break;
		}
	}
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.italic, true, 'italic must still be detected via post.italicAngle');
	});
});

test('returns empty array for non-font file', () => {
	withTempFile(Buffer.from('not a font'), (file) => {
		assert.deepEqual(parseFontFileSync(file), []);
	});
});

test('returns empty array for missing file', () => {
	const faces = parseFontFileSync('/no/such/path/fontfile.ttf');
	assert.deepEqual(faces, []);
});

test('returns empty array for truncated TTF (corrupt header)', () => {
	const buf = buildTTF({ family: 'Trunc', style: 'Regular' });
	const truncated = buf.slice(0, 20);
	withTempFile(truncated, (file) => {
		assert.deepEqual(parseFontFileSync(file), []);
	});
});

test('parses Mac platform name records (legacy)', () => {
	const buf = buildTTF({
		family: 'OldMacFont',
		style: 'Regular',
		platform: 'mac',
	});
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.family, 'OldMacFont');
	});
});

test('falls back to weight 400 when OS/2 weight is zero', () => {
	const buf = buildTTF({
		family: 'NoWeight',
		style: 'Regular',
		weight: 0,
	});
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.weight, 400);
	});
});

test('clamps invalid usWidthClass to 5 (medium)', () => {
	const buf = buildTTF({
		family: 'BadStretch',
		style: 'Regular',
		stretch: 99,
	});
	withTempFile(buf, (file) => {
		const [f] = parseFontFileSync(file);
		assert.equal(f.stretch, 5);
	});
});
