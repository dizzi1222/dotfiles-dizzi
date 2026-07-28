'use strict';

// Tiny synthetic SFNT/TTC builder for tests.
// Produces a minimal but valid TTF with name, OS/2, head, post tables,
// enough that ttf-parser.js can extract every field on the IFontFigmaItem contract.
// NOT a general-purpose font writer; do not use outside tests.

function pad4(buf) {
	const rem = buf.length % 4;
	if (rem === 0) return buf;
	return Buffer.concat([buf, Buffer.alloc(4 - rem)]);
}

function utf16beEncode(str) {
	const out = Buffer.alloc(str.length * 2);
	for (let i = 0; i < str.length; i++) {
		const code = str.charCodeAt(i);
		out[i * 2] = (code >> 8) & 0xff;
		out[i * 2 + 1] = code & 0xff;
	}
	return out;
}

function macRomanEncode(str) {
	// Encode the ASCII subset; high bytes are not exercised by tests.
	const out = Buffer.alloc(str.length);
	for (let i = 0; i < str.length; i++) {
		const code = str.charCodeAt(i);
		out[i] = code < 0x80 ? code : 0x3F; // '?'
	}
	return out;
}

function buildNameTable(records) {
	// records: [{ platformID, encodingID, languageID, nameID, value }]
	const stringOffsets = [];
	let totalStringLen = 0;
	const encoded = records.map((r) => {
		const buf = r.platformID === 1 ? macRomanEncode(r.value) : utf16beEncode(r.value);
		stringOffsets.push(totalStringLen);
		totalStringLen += buf.length;
		return buf;
	});

	const recordsLen = records.length * 12;
	const headerLen = 6;
	const stringOffset = headerLen + recordsLen;

	const out = Buffer.alloc(stringOffset + totalStringLen);
	out.writeUInt16BE(0, 0); // format
	out.writeUInt16BE(records.length, 2);
	out.writeUInt16BE(stringOffset, 4);

	for (let i = 0; i < records.length; i++) {
		const r = records[i];
		const base = headerLen + i * 12;
		out.writeUInt16BE(r.platformID, base);
		out.writeUInt16BE(r.encodingID, base + 2);
		out.writeUInt16BE(r.languageID, base + 4);
		out.writeUInt16BE(r.nameID, base + 6);
		out.writeUInt16BE(encoded[i].length, base + 8);
		out.writeUInt16BE(stringOffsets[i], base + 10);
		encoded[i].copy(out, stringOffset + stringOffsets[i]);
	}
	return out;
}

function buildOS2Table(weight, widthClass) {
	const buf = Buffer.alloc(78);
	buf.writeUInt16BE(0, 0); // version
	buf.writeInt16BE(500, 2); // xAvgCharWidth
	buf.writeUInt16BE(weight, 4); // usWeightClass
	buf.writeUInt16BE(widthClass, 6); // usWidthClass
	// rest zero-initialized; parser does not read them
	return buf;
}

function buildHeadTable(italic) {
	const buf = Buffer.alloc(54);
	buf.writeUInt16BE(1, 0); // majorVersion
	buf.writeUInt16BE(0, 2); // minorVersion
	buf.writeUInt32BE(0x00010000, 4); // fontRevision
	buf.writeUInt32BE(0, 8); // checkSumAdjustment
	buf.writeUInt32BE(0x5F0F3CF5, 12); // magicNumber
	buf.writeUInt16BE(0, 16); // flags
	buf.writeUInt16BE(1024, 18); // unitsPerEm
	// created/modified at offset 20-35
	buf.writeInt16BE(0, 36); // xMin
	buf.writeInt16BE(0, 38); // yMin
	buf.writeInt16BE(1024, 40); // xMax
	buf.writeInt16BE(1024, 42); // yMax
	const macStyle = italic ? 0x02 : 0x00;
	buf.writeUInt16BE(macStyle, 44);
	buf.writeUInt16BE(8, 46); // lowestRecPPEM
	buf.writeInt16BE(2, 48); // fontDirectionHint
	buf.writeInt16BE(0, 50); // indexToLocFormat
	buf.writeInt16BE(0, 52); // glyphDataFormat
	return buf;
}

function buildPostTable(italic) {
	const buf = Buffer.alloc(32);
	buf.writeUInt32BE(0x00030000, 0); // version 3
	// italicAngle as Fixed (16.16) - non-zero indicates italic
	buf.writeInt32BE(italic ? -(15 << 16) : 0, 4);
	buf.writeInt16BE(-100, 8); // underlinePosition
	buf.writeInt16BE(50, 10); // underlineThickness
	buf.writeUInt32BE(0, 12); // isFixedPitch
	return buf;
}

// Build a minimal TTF buffer for the given face spec.
// spec: {
//   family, style, postscript, weight=400, stretch=5, italic=false,
//   typographicFamily?, typographicStyle?,   // emit nameID 16/17
//   platform?: 'windows'|'mac',              // default 'windows'
//   useUnicodePlatform?: boolean,            // emit platform=0 records
// }
function buildTTF(spec) {
	const family = spec.family;
	const style = spec.style || 'Regular';
	const postscript = spec.postscript || `${family}-${style}`.replace(/\s+/g, '');
	const weight = spec.weight != null ? spec.weight : 400;
	const stretch = spec.stretch != null ? spec.stretch : 5;
	const italic = !!spec.italic;
	const platform = spec.platform || 'windows';

	const records = [];
	const emit = (nameID, value) => {
		if (platform === 'windows') {
			records.push({ platformID: 3, encodingID: 1, languageID: 0x0409, nameID, value });
		} else {
			records.push({ platformID: 1, encodingID: 0, languageID: 0, nameID, value });
		}
		if (spec.useUnicodePlatform) {
			records.push({ platformID: 0, encodingID: 3, languageID: 0, nameID, value });
		}
	};
	emit(1, family);
	emit(2, style);
	emit(4, `${family} ${style}`);
	emit(6, postscript);
	if (spec.typographicFamily) emit(16, spec.typographicFamily);
	if (spec.typographicStyle) emit(17, spec.typographicStyle);

	// Name records must be sorted by (platformID, encodingID, languageID, nameID).
	records.sort((a, b) => {
		if (a.platformID !== b.platformID) return a.platformID - b.platformID;
		if (a.encodingID !== b.encodingID) return a.encodingID - b.encodingID;
		if (a.languageID !== b.languageID) return a.languageID - b.languageID;
		return a.nameID - b.nameID;
	});

	const tables = [
		{ tag: 'OS/2', data: buildOS2Table(weight, stretch) },
		{ tag: 'head', data: buildHeadTable(italic) },
		{ tag: 'name', data: buildNameTable(records) },
		{ tag: 'post', data: buildPostTable(italic) },
	];
	tables.sort((a, b) => (a.tag < b.tag ? -1 : a.tag > b.tag ? 1 : 0));

	const numTables = tables.length;
	const headerLen = 12 + numTables * 16;
	let cursor = headerLen;
	const tablePlacement = tables.map((t) => {
		const offset = cursor;
		cursor += t.data.length;
		const padded = (cursor + 3) & ~3;
		const padBytes = padded - cursor;
		cursor = padded;
		return { ...t, offset, padBytes };
	});

	const total = cursor;
	const buf = Buffer.alloc(total);

	// SFNT header
	buf.writeUInt32BE(0x00010000, 0); // sfntVersion (TTF)
	buf.writeUInt16BE(numTables, 4);
	let entrySelector = 0;
	let n = numTables;
	while (n > 1) { n >>= 1; entrySelector++; }
	const searchRange = (1 << entrySelector) * 16;
	buf.writeUInt16BE(searchRange, 6);
	buf.writeUInt16BE(entrySelector, 8);
	buf.writeUInt16BE(numTables * 16 - searchRange, 10);

	// Table records
	for (let i = 0; i < tablePlacement.length; i++) {
		const t = tablePlacement[i];
		const recOffset = 12 + i * 16;
		buf.write(t.tag, recOffset, 4, 'latin1');
		buf.writeUInt32BE(0, recOffset + 4); // checkSum (not validated)
		buf.writeUInt32BE(t.offset, recOffset + 8);
		buf.writeUInt32BE(t.data.length, recOffset + 12);
		t.data.copy(buf, t.offset);
	}

	return buf;
}

// Build a TTC by composing N face buffers. Each face's table directory and tables are
// embedded, sharing nothing; offsets are file-relative which matches how ttc-parser reads them.
function buildTTC(specs) {
	const faceBufs = specs.map(buildTTF);
	const numFonts = faceBufs.length;
	const headerLen = 12 + numFonts * 4; // ttc header + per-face offset

	// Place faces back-to-back, 4-byte aligned.
	let cursor = headerLen;
	const offsets = [];
	const padded = [];
	for (const fb of faceBufs) {
		const aligned = (cursor + 3) & ~3;
		const pad = aligned - cursor;
		if (pad) padded.push(Buffer.alloc(pad));
		else padded.push(Buffer.alloc(0));
		cursor = aligned;
		offsets.push(cursor);
		cursor += fb.length;
	}

	// We embed faces verbatim, but their table records have offsets relative to the
	// start of the face. TTC requires they be relative to start of file. Patch offsets.
	const patchedFaces = faceBufs.map((fb, idx) => {
		const out = Buffer.from(fb);
		const numTables = out.readUInt16BE(4);
		const baseShift = offsets[idx];
		for (let i = 0; i < numTables; i++) {
			const recOff = 12 + i * 16;
			const orig = out.readUInt32BE(recOff + 8);
			out.writeUInt32BE(orig + baseShift, recOff + 8);
		}
		return out;
	});

	const headerBuf = Buffer.alloc(headerLen);
	headerBuf.write('ttcf', 0, 4, 'latin1');
	headerBuf.writeUInt16BE(1, 4); // majorVersion
	headerBuf.writeUInt16BE(0, 6); // minorVersion
	headerBuf.writeUInt32BE(numFonts, 8);
	for (let i = 0; i < numFonts; i++) {
		headerBuf.writeUInt32BE(offsets[i], 12 + i * 4);
	}

	const parts = [headerBuf];
	for (let i = 0; i < numFonts; i++) {
		parts.push(padded[i]);
		parts.push(patchedFaces[i]);
	}
	return Buffer.concat(parts);
}

module.exports = {
	buildTTF,
	buildTTC,
	pad4,
	utf16beEncode,
};
