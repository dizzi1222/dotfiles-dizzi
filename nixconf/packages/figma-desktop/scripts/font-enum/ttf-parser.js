'use strict';

const fs = require('fs');

// SFNT version magic numbers
const SFNT_TTF = 0x00010000;
const SFNT_OTF_CFF = 0x4F54544F; // 'OTTO'
const SFNT_TRUE = 0x74727565; // 'true' (legacy Mac TTF)
const SFNT_TYP1 = 0x74797031; // 'typ1'

// usWidthClass -> stretch (1..9, 5 = normal)
function widthClassToStretch(w) {
	if (typeof w !== 'number' || w < 1 || w > 9) return 5;
	return w;
}

// Decode a name record's bytes per platform/encoding.
// Returns null if encoding unknown.
function decodeNameString(buf, platformID, encodingID) {
	// Windows (3) - all encodings on Windows are 16-bit, big-endian.
	if (platformID === 3) return bigEndianUtf16(buf);
	// Unicode (0) - UTF-16BE
	if (platformID === 0) return bigEndianUtf16(buf);
	// Mac (1) - encoding 0 = Mac Roman; we map a useful subset of Mac Roman to Unicode.
	if (platformID === 1 && encodingID === 0) return decodeMacRoman(buf);
	// ISO (2) - rarely used; assume ASCII subset.
	if (platformID === 2) return buf.toString('latin1');
	return null;
}

function bigEndianUtf16(buf) {
	if (buf.length % 2 !== 0) return null;
	let out = '';
	for (let i = 0; i < buf.length; i += 2) {
		out += String.fromCharCode((buf[i] << 8) | buf[i + 1]);
	}
	return out;
}

// Mac Roman -> Unicode for the high half (0x80..0xFF).
const MAC_ROMAN_HIGH = [
	0x00C4, 0x00C5, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00E1,
	0x00E0, 0x00E2, 0x00E4, 0x00E3, 0x00E5, 0x00E7, 0x00E9, 0x00E8,
	0x00EA, 0x00EB, 0x00ED, 0x00EC, 0x00EE, 0x00EF, 0x00F1, 0x00F3,
	0x00F2, 0x00F4, 0x00F6, 0x00F5, 0x00FA, 0x00F9, 0x00FB, 0x00FC,
	0x2020, 0x00B0, 0x00A2, 0x00A3, 0x00A7, 0x2022, 0x00B6, 0x00DF,
	0x00AE, 0x00A9, 0x2122, 0x00B4, 0x00A8, 0x2260, 0x00C6, 0x00D8,
	0x221E, 0x00B1, 0x2264, 0x2265, 0x00A5, 0x00B5, 0x2202, 0x2211,
	0x220F, 0x03C0, 0x222B, 0x00AA, 0x00BA, 0x03A9, 0x00E6, 0x00F8,
	0x00BF, 0x00A1, 0x00AC, 0x221A, 0x0192, 0x2248, 0x2206, 0x00AB,
	0x00BB, 0x2026, 0x00A0, 0x00C0, 0x00C3, 0x00D5, 0x0152, 0x0153,
	0x2013, 0x2014, 0x201C, 0x201D, 0x2018, 0x2019, 0x00F7, 0x25CA,
	0x00FF, 0x0178, 0x2044, 0x20AC, 0x2039, 0x203A, 0xFB01, 0xFB02,
	0x2021, 0x00B7, 0x201A, 0x201E, 0x2030, 0x00C2, 0x00CA, 0x00C1,
	0x00CB, 0x00C8, 0x00CD, 0x00CE, 0x00CF, 0x00CC, 0x00D3, 0x00D4,
	0xF8FF, 0x00D2, 0x00DA, 0x00DB, 0x00D9, 0x0131, 0x02C6, 0x02DC,
	0x00AF, 0x02D8, 0x02D9, 0x02DA, 0x00B8, 0x02DD, 0x02DB, 0x02C7,
];

function decodeMacRoman(buf) {
	let out = '';
	for (let i = 0; i < buf.length; i++) {
		const b = buf[i];
		out += b < 0x80 ? String.fromCharCode(b) : String.fromCharCode(MAC_ROMAN_HIGH[b - 0x80]);
	}
	return out;
}

// Score platform/encoding/language preference. Lower is better.
// Prefer Windows BMP en-US, then Unicode, then Mac Roman en, then anything.
function scoreNameRecord(platformID, encodingID, languageID) {
	let score = 1000;
	if (platformID === 3 && encodingID === 1 && languageID === 0x0409) score = 0;
	else if (platformID === 3 && encodingID === 1) score = 10;
	else if (platformID === 3 && encodingID === 10) score = 20; // UCS-4
	else if (platformID === 0) score = 30;
	else if (platformID === 1 && encodingID === 0 && languageID === 0) score = 40;
	else if (platformID === 1 && encodingID === 0) score = 50;
	else score = 100;
	return score;
}

// Read a name table at given file offset/length and return a map of nameID -> string.
function readNameTable(fd, tableOffset, tableLength) {
	if (tableLength < 6) return {};
	const headerBuf = Buffer.alloc(6);
	fs.readSync(fd, headerBuf, 0, 6, tableOffset);
	const count = headerBuf.readUInt16BE(2);
	const stringOffset = headerBuf.readUInt16BE(4);
	const recordsLen = count * 12;
	if (recordsLen + 6 > tableLength) return {};
	const recordsBuf = Buffer.alloc(recordsLen);
	fs.readSync(fd, recordsBuf, 0, recordsLen, tableOffset + 6);

	// Pick best record per nameID.
	const best = new Map(); // nameID -> { score, plat, enc, len, off }
	for (let i = 0; i < count; i++) {
		const base = i * 12;
		const platformID = recordsBuf.readUInt16BE(base);
		const encodingID = recordsBuf.readUInt16BE(base + 2);
		const languageID = recordsBuf.readUInt16BE(base + 4);
		const nameID = recordsBuf.readUInt16BE(base + 6);
		const length = recordsBuf.readUInt16BE(base + 8);
		const offset = recordsBuf.readUInt16BE(base + 10);
		// Only collect IDs we care about.
		if (nameID !== 1 && nameID !== 2 && nameID !== 4 && nameID !== 6 && nameID !== 16 && nameID !== 17) continue;
		const score = scoreNameRecord(platformID, encodingID, languageID);
		const prev = best.get(nameID);
		if (!prev || score < prev.score) {
			best.set(nameID, { score, platformID, encodingID, length, offset });
		}
	}

	const result = {};
	for (const [nameID, r] of best.entries()) {
		if (r.length === 0) continue;
		const stringDataOffset = tableOffset + stringOffset + r.offset;
		if (stringDataOffset + r.length > tableOffset + tableLength) continue;
		const strBuf = Buffer.alloc(r.length);
		fs.readSync(fd, strBuf, 0, r.length, stringDataOffset);
		// Windows is always UTF-16BE (encoding 1 BMP, encoding 10 UCS-4 we treat as UTF-16BE pairs).
		let decoded;
		if (r.platformID === 3) decoded = bigEndianUtf16(strBuf);
		else decoded = decodeNameString(strBuf, r.platformID, r.encodingID);
		if (typeof decoded === 'string' && decoded.length > 0) result[nameID] = decoded;
	}
	return result;
}

// Read one face's offset table at a given file offset and resolve table directory entries.
// Returns map: tag -> { offset, length }.
function readTableDirectory(fd, faceOffset) {
	const headerBuf = Buffer.alloc(12);
	fs.readSync(fd, headerBuf, 0, 12, faceOffset);
	const sfntVersion = headerBuf.readUInt32BE(0);
	if (sfntVersion !== SFNT_TTF && sfntVersion !== SFNT_OTF_CFF && sfntVersion !== SFNT_TRUE && sfntVersion !== SFNT_TYP1) {
		return null;
	}
	const numTables = headerBuf.readUInt16BE(4);
	if (numTables === 0 || numTables > 256) return null;
	const recordsLen = numTables * 16;
	const recordsBuf = Buffer.alloc(recordsLen);
	fs.readSync(fd, recordsBuf, 0, recordsLen, faceOffset + 12);
	const tables = {};
	for (let i = 0; i < numTables; i++) {
		const base = i * 16;
		const tag = recordsBuf.toString('latin1', base, base + 4);
		const offset = recordsBuf.readUInt32BE(base + 8);
		const length = recordsBuf.readUInt32BE(base + 12);
		tables[tag] = { offset, length };
	}
	return tables;
}

// Read a single face starting at faceOffset (0 for plain TTF/OTF, or per-face offset for TTC).
function parseFace(fd, faceOffset) {
	const tables = readTableDirectory(fd, faceOffset);
	if (!tables) return null;
	const nameTbl = tables['name'];
	if (!nameTbl) return null;
	const names = readNameTable(fd, nameTbl.offset, nameTbl.length);

	// Family / style. Prefer typographic (16/17) for richer family grouping (e.g. Roboto + Light vs Roboto Light + Regular).
	const family = names[16] || names[1];
	const style = names[17] || names[2] || 'Regular';
	if (!family) return null;
	const postscript = names[6] || `${family}-${style}`.replace(/\s+/g, '');

	// Weight: OS/2 usWeightClass at offset 4.
	let weight = 400;
	const os2 = tables['OS/2'];
	if (os2 && os2.length >= 8) {
		const buf = Buffer.alloc(4);
		fs.readSync(fd, buf, 0, 4, os2.offset + 4);
		weight = buf.readUInt16BE(0);
		// Some fonts set weight 0; normalize to 400.
		if (weight === 0) weight = 400;
	}

	// Stretch: OS/2 usWidthClass at offset 6.
	let stretch = 5;
	if (os2 && os2.length >= 8) {
		const buf = Buffer.alloc(2);
		fs.readSync(fd, buf, 0, 2, os2.offset + 6);
		stretch = widthClassToStretch(buf.readUInt16BE(0));
	}

	// Italic: head.macStyle bit 1 (offset 44 in head table).
	let italic = false;
	const head = tables['head'];
	if (head && head.length >= 46) {
		const buf = Buffer.alloc(2);
		fs.readSync(fd, buf, 0, 2, head.offset + 44);
		const macStyle = buf.readUInt16BE(0);
		italic = (macStyle & 0x02) !== 0;
	}
	// Fallback: post.italicAngle != 0.
	if (!italic) {
		const post = tables['post'];
		if (post && post.length >= 8) {
			const buf = Buffer.alloc(4);
			fs.readSync(fd, buf, 0, 4, post.offset + 4);
			// italicAngle is Fixed (16.16); non-zero means italic.
			const fixed = buf.readInt32BE(0);
			if (fixed !== 0) italic = true;
		}
	}

	// id - Figma uses family as id when typographic family is present, else family.
	const id = (names[16] || family).trim();

	return {
		postscript: postscript.trim(),
		family: family.trim(),
		id,
		style: style.trim(),
		weight,
		stretch,
		italic,
	};
}

// Public API.

function parseFontFileSync(filePath) {
	let fd;
	try {
		fd = fs.openSync(filePath, 'r');
	} catch {
		return [];
	}
	try {
		const sigBuf = Buffer.alloc(4);
		fs.readSync(fd, sigBuf, 0, 4, 0);
		const sig = sigBuf.readUInt32BE(0);
		// TTC handled by ttc-parser; here we only do single-face files.
		if (sig === 0x74746366) return []; // 'ttcf'
		const face = parseFace(fd, 0);
		return face ? [face] : [];
	} catch {
		return [];
	} finally {
		try { fs.closeSync(fd); } catch { /* ignore */ }
	}
}

module.exports = {
	parseFontFileSync,
	parseFace,
	readTableDirectory,
	readNameTable,
	widthClassToStretch,
	bigEndianUtf16,
	decodeMacRoman,
};
