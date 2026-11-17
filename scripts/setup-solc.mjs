import fs from 'node:fs';
import {createHash} from 'node:crypto';
// Project-local compiler avoids global installations and verifies the official checksum.
const platform=process.platform==='darwin'?'macosx-amd64':process.platform==='linux'&&process.arch==='x64'?'linux-amd64':null;
if(!platform) throw Error('Use a native solc 0.8.30 and set FOUNDRY_SOLC to its absolute path on this platform.');
const base=`https://binaries.soliditylang.org/${platform}/`;
const res=await fetch(base+'list.json'); if(!res.ok)throw Error('Compiler manifest download failed');
const list=await res.json(); const name=list.releases['0.8.30']; const build=list.builds.find(b=>b.path===name);
const response=await fetch(base+name); if(!response.ok)throw Error('Compiler download failed');
const bytes=Buffer.from(await response.arrayBuffer());
if('0x'+createHash('sha256').update(bytes).digest('hex')!==build.sha256)throw Error('Compiler checksum mismatch');
fs.mkdirSync('.tools',{recursive:true}); fs.writeFileSync('.tools/solc',bytes,{mode:0o755});
console.log('Verified Solidity 0.8.30 installed in .tools/solc');
