#!/usr/bin/env node
// Turns text pixel-art files (art/<set>/*.txt) into game textures.
//
//   node scripts/build-art.js art/flight-trivia [addons/<Addon>/media]
//
// For each sprite it writes:
//   <art dir>/preview/<name>.png   8x scaled preview with a checkerboard
//   <media dir>/<name>.tga         32-bit TGA sprite sheet, power-of-two size
//   <media dir>/Sprites.lua        frame sizes and texture coordinates
//
// Text format (see art/flight-trivia/thrall_windrider.txt):
//   size WxH
//   palette            then lines "<char> <rrggbb|transparent> [comment]"
//   frame              then H lines of W characters
// Frames are laid out left to right in the sheet.

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

function parseArt(file) {
    const lines = fs.readFileSync(file, 'utf8').split(/\r?\n/);
    const sprite = { name: path.basename(file, '.txt'), palette: {}, frames: [] };
    let mode = null;
    let frame = null;
    for (const raw of lines) {
        const line = raw.replace(/\s+$/, '');
        if (line.startsWith('#')) continue;
        if (line === '') { continue; }
        let m;
        if ((m = line.match(/^size (\d+)x(\d+)$/))) {
            sprite.w = +m[1]; sprite.h = +m[2]; continue;
        }
        if (line === 'palette') { mode = 'palette'; continue; }
        if (line === 'frame') { mode = 'frame'; frame = []; sprite.frames.push(frame); continue; }
        if (mode === 'palette') {
            const [ch, color] = line.trim().split(/\s+/);
            if (color === 'transparent') sprite.palette[ch] = [0, 0, 0, 0];
            else sprite.palette[ch] = [
                parseInt(color.slice(0, 2), 16),
                parseInt(color.slice(2, 4), 16),
                parseInt(color.slice(4, 6), 16),
                255,
            ];
        } else if (mode === 'frame') {
            frame.push(line);
        }
    }
    if (!sprite.w || !sprite.h) throw new Error(`${file}: missing "size WxH"`);
    sprite.frames.forEach((rows, i) => {
        if (rows.length !== sprite.h) throw new Error(`${file}: frame ${i + 1} has ${rows.length} rows, want ${sprite.h}`);
        rows.forEach((row, y) => {
            if (row.length !== sprite.w) throw new Error(`${file}: frame ${i + 1} row ${y} is ${row.length} wide, want ${sprite.w}`);
            for (const ch of row) {
                if (!(ch in sprite.palette)) throw new Error(`${file}: frame ${i + 1} row ${y} uses "${ch}", not in palette`);
            }
        });
    });
    return sprite;
}

const pow2 = (n) => { let p = 1; while (p < n) p *= 2; return p; };

// RGBA pixel buffer for the whole sheet, top row first.
function renderSheet(sprite) {
    const sheetW = sprite.w * sprite.frames.length;
    const texW = pow2(sheetW);
    const texH = pow2(sprite.h);
    const px = Buffer.alloc(texW * texH * 4);
    sprite.frames.forEach((rows, f) => {
        rows.forEach((row, y) => {
            [...row].forEach((ch, x) => {
                const [r, g, b, a] = sprite.palette[ch];
                const i = (y * texW + f * sprite.w + x) * 4;
                px[i] = r; px[i + 1] = g; px[i + 2] = b; px[i + 3] = a;
            });
        });
    });
    return { px, texW, texH };
}

function writeTGA(file, px, w, h) {
    const header = Buffer.alloc(18);
    header[2] = 2;                    // uncompressed true-color
    header.writeUInt16LE(w, 12);
    header.writeUInt16LE(h, 14);
    header[16] = 32;                  // bits per pixel
    header[17] = 8;                   // 8 alpha bits, bottom-left origin
    const body = Buffer.alloc(w * h * 4);
    for (let y = 0; y < h; y++) {
        const srcRow = (h - 1 - y) * w * 4; // TGA stores the bottom row first
        for (let x = 0; x < w; x++) {
            const s = srcRow + x * 4;
            const d = (y * w + x) * 4;
            body[d] = px[s + 2]; body[d + 1] = px[s + 1]; body[d + 2] = px[s]; body[d + 3] = px[s + 3];
        }
    }
    fs.writeFileSync(file, Buffer.concat([header, body]));
}

const CRC_TABLE = (() => {
    const t = new Uint32Array(256);
    for (let n = 0; n < 256; n++) {
        let c = n;
        for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
        t[n] = c >>> 0;
    }
    return t;
})();

function crc32(buf) {
    let c = 0xffffffff;
    for (const b of buf) c = CRC_TABLE[(c ^ b) & 0xff] ^ (c >>> 8);
    return (c ^ 0xffffffff) >>> 0;
}

function pngChunk(type, data) {
    const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
    const td = Buffer.concat([Buffer.from(type), data]);
    const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
    return Buffer.concat([len, td, crc]);
}

function writePNG(file, px, w, h) {
    const raw = Buffer.alloc((w * 4 + 1) * h);
    for (let y = 0; y < h; y++) {
        raw[y * (w * 4 + 1)] = 0;
        px.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4);
    }
    const ihdr = Buffer.alloc(13);
    ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
    ihdr[8] = 8; ihdr[9] = 6; // 8-bit RGBA
    fs.writeFileSync(file, Buffer.concat([
        Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        pngChunk('IHDR', ihdr),
        pngChunk('IDAT', zlib.deflateSync(raw)),
        pngChunk('IEND', Buffer.alloc(0)),
    ]));
}

// Preview: frames side by side with a 1px gap, scaled, on a checkerboard.
function writePreview(file, sprite, scale) {
    const gap = 2;
    const w = (sprite.w * sprite.frames.length + gap * (sprite.frames.length - 1)) * scale;
    const h = sprite.h * scale;
    const px = Buffer.alloc(w * h * 4);
    for (let y = 0; y < h; y++) {
        for (let x = 0; x < w; x++) {
            const i = (y * w + x) * 4;
            const light = ((x >> 3) + (y >> 3)) % 2 === 0;
            px[i] = px[i + 1] = px[i + 2] = light ? 0x9a : 0x7a; px[i + 3] = 255;
        }
    }
    sprite.frames.forEach((rows, f) => {
        const ox = f * (sprite.w + gap) * scale;
        rows.forEach((row, y) => {
            [...row].forEach((ch, x) => {
                const [r, g, b, a] = sprite.palette[ch];
                if (!a) return;
                for (let dy = 0; dy < scale; dy++) {
                    for (let dx = 0; dx < scale; dx++) {
                        const i = ((y * scale + dy) * w + ox + x * scale + dx) * 4;
                        px[i] = r; px[i + 1] = g; px[i + 2] = b; px[i + 3] = 255;
                    }
                }
            });
        });
    });
    writePNG(file, px, w, h);
}

function main() {
    const [artDir, mediaDir] = process.argv.slice(2);
    if (!artDir) {
        console.error('usage: node scripts/build-art.js <art dir> [media dir]');
        process.exit(1);
    }
    const files = fs.readdirSync(artDir).filter((f) => f.endsWith('.txt')).sort();
    const previewDir = path.join(artDir, 'preview');
    fs.mkdirSync(previewDir, { recursive: true });
    if (mediaDir) fs.mkdirSync(mediaDir, { recursive: true });

    const luaEntries = [];
    for (const f of files) {
        const sprite = parseArt(path.join(artDir, f));
        writePreview(path.join(previewDir, sprite.name + '.png'), sprite, 8);
        const { px, texW, texH } = renderSheet(sprite);
        if (mediaDir) writeTGA(path.join(mediaDir, sprite.name + '.tga'), px, texW, texH);
        luaEntries.push(
            `    ${sprite.name} = { file = "${sprite.name}", w = ${sprite.w}, h = ${sprite.h}, ` +
            `frames = ${sprite.frames.length}, texW = ${texW}, texH = ${texH} },`);
        console.log(`${sprite.name}: ${sprite.frames.length} frame(s) ${sprite.w}x${sprite.h}, sheet ${texW}x${texH}`);
    }

    if (mediaDir) {
        const lua = [
            '-- Generated by scripts/build-art.js. Do not edit by hand.',
            'local _, ns = ...',
            'ns.sprites = {',
            ...luaEntries,
            '}',
            '',
        ].join('\n');
        fs.writeFileSync(path.join(mediaDir, 'Sprites.lua'), lua);
    }
}

main();
