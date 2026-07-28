#!/usr/bin/env bash
set -euo pipefail

scripts_dir="$1"
app_staging_dir="$2"
asar_bin="$3"

cd "$app_staging_dir"

asar_prefix=$(dirname "$(dirname "$asar_bin")")
export NODE_PATH="$asar_prefix/lib/node_modules${NODE_PATH:+:$NODE_PATH}"

require_file() {
  local file="$1"
  local desc="$2"
  if [ ! -f "$file" ]; then
    echo "Required patch target missing: $desc ($file)" >&2
    exit 1
  fi
}

rm -rf app.asar.contents
node <<'NODE'
const asar = require('@electron/asar');
const fs = require('fs');
const path = require('path');

const asarPath = 'app.asar';
const outDir = 'app.asar.contents';
const unpackedDir = 'app.asar.unpacked';
const manifestPath = '.asar-unpacked-files.json';
const header = JSON.parse(asar.getRawHeader(asarPath).headerString);
const asarBuf = fs.readFileSync(asarPath);
const headerBufSize = asarBuf.readUInt32LE(4);
const dataStart = 8 + headerBufSize;
const unpackedFiles = [];

function walk(files, prefix = '') {
  for (const [name, entry] of Object.entries(files)) {
    const rel = prefix ? `${prefix}/${name}` : name;
    if (entry.files) {
      walk(entry.files, rel);
      continue;
    }

    const outPath = path.join(outDir, rel);
    fs.mkdirSync(path.dirname(outPath), { recursive: true });

    if (entry.unpacked) {
      const src = path.join(unpackedDir, rel);
      if (!fs.existsSync(src)) {
        throw new Error(`ASAR header marks ${rel} unpacked, but ${src} is missing`);
      }
      fs.copyFileSync(src, outPath);
      unpackedFiles.push(rel);
      continue;
    }

    if (entry.size < 0 || entry.offset === undefined) {
      continue;
    }

    const size = entry.size;
    const offset = Number(entry.offset || 0);
    const buf = Buffer.alloc(size);
    asarBuf.copy(buf, 0, dataStart + offset, dataStart + offset + size);
    fs.writeFileSync(outPath, buf);
  }
}

fs.mkdirSync(outDir, { recursive: true });
walk(header.files);
fs.writeFileSync(manifestPath, JSON.stringify(unpackedFiles, null, 2));
NODE

original_main_json=$(node -e "const pkg = require('./app.asar.contents/package.json'); process.stdout.write(JSON.stringify('./' + pkg.main));")
cp "$scripts_dir/frame-fix-wrapper.js" app.asar.contents/frame-fix-wrapper.js
cat > app.asar.contents/frame-fix-entry.js <<EOF
// Load frame fix first
require('./frame-fix-wrapper.js');
// Then load original main
require($original_main_json);
EOF

main_js='app.asar.contents/main.js'
shell_js='app.asar.contents/desktop_shell.js'
shell_html='app.asar.contents/shell.html'
worker_js='app.asar.contents/bindings_worker.js'

require_file "$main_js" 'main process runtime patches'
require_file "$shell_js" 'desktop shell frame/menu patches'
require_file "$shell_html" 'shell caption-button CSS patch'
require_file "$worker_js" 'font utility native-module patch'

node <<'NODE'
const fs = require('fs');
const file = 'app.asar.contents/main.js';
let code = fs.readFileSync(file, 'utf8');
let replacements = 0;
for (const [pattern, replacement] of [
  [/frame:!1/g, 'frame:true'],
  [/frame:!0/g, 'frame:true'],
  [/frame\s*:\s*false/g, 'frame:true'],
  [/titleBarStyle:"hidden"/g, 'titleBarStyle:"default"'],
]) {
  const before = code;
  code = code.replace(pattern, replacement);
  if (code !== before) replacements++;
}
if (replacements === 0) {
  console.error('Required frame patch failed: no BrowserWindow frame/titleBarStyle patterns found in main.js');
  process.exit(1);
}
const menuPattern = 'process.platform==="win32"&&(this.windowsAppMenu=';
if (!code.includes(menuPattern) && !code.includes('process.platform!=="darwin"&&(this.windowsAppMenu=')) {
  console.error('Required menu patch failed: windowsAppMenu platform gate not found in main.js');
  process.exit(1);
}
code = code.replaceAll(menuPattern, 'process.platform!=="darwin"&&(this.windowsAppMenu=');
fs.writeFileSync(file, code);
NODE

node <<'NODE'
const fs = require('fs');
const file = 'app.asar.contents/desktop_shell.js';
let code = fs.readFileSync(file, 'utf8');
let frameReplacements = 0;
for (const [pattern, replacement] of [[/frame:!1/g, 'frame:true'], [/frame:!0/g, 'frame:true']]) {
  const before = code;
  code = code.replace(pattern, replacement);
  if (code !== before) frameReplacements++;
}
if (frameReplacements === 0) {
  console.error('Optional shell frame patch skipped: no frame patterns found in desktop_shell.js');
}
const platformPattern = /\b\w{2}="win32"===\w\.platform\b/;
const m = code.match(platformPattern);
if (!m && !/\b\w{2}="darwin"!==e\.platform\b/.test(code)) {
  console.error('Required shell menu patch failed: win32 platform check not found in desktop_shell.js');
  process.exit(1);
}
if (m) {
  const varName = m[0].split('=')[0];
  code = code.replace(m[0], `${varName}="darwin"!==e.platform`);
}
fs.writeFileSync(file, code);
NODE

node <<'NODE'
const fs = require('fs');
const file = 'app.asar.contents/shell.html';
let code = fs.readFileSync(file, 'utf8');
if (!code.includes('</head>')) {
  console.error('Required shell CSS patch failed: </head> not found in shell.html');
  process.exit(1);
}
code = code.replace('</head>', `<style>
#__MINIMIZE_CAPTION_BUTTON__,
#__MAXIMIZE_CAPTION_BUTTON__,
#__CLOSE_CAPTION_BUTTON__ { display: none !important; }
</style>
</head>`);
fs.writeFileSync(file, code);
NODE

node <<'NODE'
const fs = require('fs');
const pkgPath = './app.asar.contents/package.json';
const pkg = require(pkgPath);
pkg.originalMain = pkg.originalMain || pkg.main;
pkg.main = 'frame-fix-entry.js';
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2));
NODE

cp "$scripts_dir/figma-native-stub.js" app.asar.contents/figma-native-stub.js
mkdir -p app.asar.contents/font-enum
for js_file in "$scripts_dir"/font-enum/*.js; do
  [ -f "$js_file" ] || continue
  cp "$js_file" app.asar.contents/font-enum/
done

node <<'NODE'
const fs = require('fs');
const files = ['app.asar.contents/main.js', 'app.asar.contents/bindings_worker.js'];
const workerFile = 'app.asar.contents/bindings_worker.js';
const nativeRequireReplacements = [
  ['require("./bindings.node")', 'require("./figma-native-stub.js")'],
  ['require("../build/Debug/bindings.node")', 'require("./figma-native-stub.js")'],
  ['require("../build/Release/bindings.node")', 'require("./figma-native-stub.js")'],
  ['require("./desktop_rust.node")', 'require("./figma-native-stub.js").desktop_rust'],
  ['require("../rust/desktop_rust.node")', 'require("./figma-native-stub.js").desktop_rust'],
];
let total = 0;
let workerPatched = false;
for (const file of files) {
  let code = fs.readFileSync(file, 'utf8');
  const before = code;
  for (const [pattern, replacement] of nativeRequireReplacements) {
    code = code.split(pattern).join(replacement);
  }
  if (code !== before) {
    total++;
    if (file === workerFile) workerPatched = true;
    fs.writeFileSync(file, code);
  }
}
if (total === 0) {
  console.error('Required native runtime patch failed: no native module require patterns found in main.js or bindings_worker.js');
  process.exit(1);
}
const workerCode = fs.readFileSync(workerFile, 'utf8');
if (!workerPatched) {
  console.error('Required worker native runtime patch failed: no native module require patterns found in bindings_worker.js');
  process.exit(1);
}
for (const [pattern] of nativeRequireReplacements) {
  if (workerCode.includes(pattern)) {
    console.error(`Required worker native runtime patch failed: bindings_worker.js still contains native require pattern ${pattern}`);
    process.exit(1);
  }
}
NODE

node <<'NODE'
const fs = require('fs');
const main_js = 'app.asar.contents/main.js';
let code = fs.readFileSync(main_js, 'utf8');
const pattern = /async handleCommandLineArgs\((\w+)\)\{let (\w+)=(\w+)\.app\.isPackaged\?1:2;if\(\1\.length>\2\)\{let (\w+)=\1\[\2\];if\((\w+)\(\4,\{isExternalOpen:!0\}\)\)return!0;if\((\w+)\.default\.statSync\(\4,\{throwIfNoEntry:!1\}\)\)return await (\w+)\(\4\)\}return!1\}/;
const m = code.match(pattern);
if (!m) {
  console.warn('Optional argv patch skipped: handleCommandLineArgs pattern not found (figma:// URL opening may be limited, but the local MCP server still works).');
  // Non-fatal: do not exit 1 — the MCP server at 127.0.0.1:3845 is unaffected.
  process.exit(0);
}
const [fullMatch, arg, , , innerVar, urlFn, statMod, openFn] = m;
const replacement = 'async handleCommandLineArgs(' + arg + '){for(let _i=1;_i<' + arg + '.length;_i++){let ' + innerVar + '=' + arg + '[_i];if(' + innerVar + '.startsWith("-")||' + innerVar + '.endsWith(".asar")||' + innerVar + '.endsWith(".js"))continue;if(' + urlFn + '(' + innerVar + ',{isExternalOpen:!0}))return!0;if(' + statMod + '.default.statSync(' + innerVar + ',{throwIfNoEntry:!1}))return await ' + openFn + '(' + innerVar + ')}return!1}';
code = code.replace(fullMatch, replacement);
fs.writeFileSync(main_js, code);
NODE

node <<'NODE'
const fs = require('fs');
const main_js = 'app.asar.contents/main.js';
let code = fs.readFileSync(main_js, 'utf8');
const pattern = /this\.electronTray\.setToolTip\((\w+)\.name\),this\.electronTray\.on\("right-click",\(\)=>\{var (\w+);\(\2=this\.electronTray\)==null\|\|\2\.popUpContextMenu\((\w+)\(\)\)\}\)/;
const m = code.match(pattern);
if (!m) {
  console.error('Required tray patch failed: tray context menu pattern not found in main.js');
  process.exit(1);
}
const [fullMatch, modName, varName, menuFn] = m;
const replacement = 'this.electronTray.setToolTip(' + modName + '.name),this.electronTray.setContextMenu(' + menuFn + '()),this.electronTray.on("right-click",()=>{var ' + varName + ';(' + varName + '=this.electronTray)==null||' + varName + '.popUpContextMenu(' + menuFn + '())})';
code = code.replace(fullMatch, replacement);
fs.writeFileSync(main_js, code);
NODE

rm -f app.asar
node <<'NODE'
const asar = require('@electron/asar');
const fs = require('fs');
const path = require('path');

function unpackGlob(file) {
  // @electron/asar matches the glob against absolute filenames. Prefixing the
  // original archive-relative path with **/ keeps the matcher independent of the
  // Nix build directory while preserving exactly the original unpacked entries.
  return `**/${file}`;
}

(async () => {
  const unpackedFiles = JSON.parse(fs.readFileSync('.asar-unpacked-files.json', 'utf8'));
  const options = {};
  if (unpackedFiles.length > 0) {
    options.unpack = unpackedFiles.length === 1
      ? unpackGlob(unpackedFiles[0])
      : `{${unpackedFiles.map(unpackGlob).join(',')}}`;
  }
  await asar.createPackageWithOptions('app.asar.contents', 'app.asar', options);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
NODE
rm -f .asar-unpacked-files.json
