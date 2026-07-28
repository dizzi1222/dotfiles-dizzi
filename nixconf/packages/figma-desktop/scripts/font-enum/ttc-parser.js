'use strict';

const fs = require('fs');
const { parseFace } = require('./ttf-parser');

const TTC_TAG = 0x74746366; // 'ttcf'

// Parse a TrueType/OpenType Collection: returns array of face objects.
function parseCollectionSync(filePath) {
	let fd;
	try {
		fd = fs.openSync(filePath, 'r');
	} catch {
		return [];
	}
	try {
		const headerBuf = Buffer.alloc(12);
		fs.readSync(fd, headerBuf, 0, 12, 0);
		const tag = headerBuf.readUInt32BE(0);
		if (tag !== TTC_TAG) return [];
		const numFonts = headerBuf.readUInt32BE(8);
		if (numFonts === 0 || numFonts > 1024) return [];
		const offsetsBuf = Buffer.alloc(numFonts * 4);
		fs.readSync(fd, offsetsBuf, 0, numFonts * 4, 12);
		const faces = [];
		for (let i = 0; i < numFonts; i++) {
			const faceOffset = offsetsBuf.readUInt32BE(i * 4);
			const face = parseFace(fd, faceOffset);
			if (face) faces.push(face);
		}
		return faces;
	} catch {
		return [];
	} finally {
		try { fs.closeSync(fd); } catch { /* ignore */ }
	}
}

// Sniff a file and dispatch to the right parser.
function parseAnyFontFileSync(filePath) {
	let fd;
	try {
		fd = fs.openSync(filePath, 'r');
	} catch {
		return [];
	}
	let isCollection = false;
	try {
		const sigBuf = Buffer.alloc(4);
		fs.readSync(fd, sigBuf, 0, 4, 0);
		isCollection = sigBuf.readUInt32BE(0) === TTC_TAG;
	} catch {
		try { fs.closeSync(fd); } catch { /* ignore */ }
		return [];
	}
	try { fs.closeSync(fd); } catch { /* ignore */ }
	if (isCollection) return parseCollectionSync(filePath);
	const { parseFontFileSync } = require('./ttf-parser');
	return parseFontFileSync(filePath);
}

module.exports = {
	parseCollectionSync,
	parseAnyFontFileSync,
};
