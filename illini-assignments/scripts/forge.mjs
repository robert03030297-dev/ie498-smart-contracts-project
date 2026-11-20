import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
const args=process.argv.slice(2);
const compiler=process.env.FOUNDRY_SOLC || (fs.existsSync('.tools/solc')?path.resolve('.tools/solc'):null);
if(compiler)args.push('--use',compiler);
const r=spawnSync(process.execPath,['node_modules/@foundry-rs/forge/bin.mjs',...args],{stdio:'inherit'});
if(r.error)console.error(r.error.message); process.exit(r.status??1);

