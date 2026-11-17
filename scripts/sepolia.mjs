import fs from 'node:fs';
import {JsonRpcProvider,Wallet,getAddress,parseEther} from 'ethers';
import {suite,saveEvidence,record} from './common.mjs';
// Encrypted keystore only. Do not put private keys or passwords in source/arguments.
const required=['SEPOLIA_RPC_URL','SEPOLIA_KEYSTORE','KEYSTORE_PASSWORD','BOB_ADDRESS','CHARLIE_ADDRESS','DANA_ADDRESS'];
const missing=required.filter(k=>!process.env[k]);
if(missing.length){console.log('SKIPPED: optional Sepolia deployment; missing '+missing.join(', '));process.exit(0);}
let p;
try {
  p=new JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
  if((await p.getNetwork()).chainId!==11155111n)throw Error('Sepolia chain ID required');
  const a=(await Wallet.fromEncryptedJson(fs.readFileSync(process.env.SEPOLIA_KEYSTORE,'utf8'),process.env.KEYSTORE_PASSWORD)).connect(p);
  const others=['BOB_ADDRESS','CHARLIE_ADDRESS','DANA_ADDRESS'].map(k=>getAddress(process.env[k]));
  const addresses=[a.address,...others]; if(new Set(addresses.map(x=>x.toLowerCase())).size!==4||others.some(x=>x==='0x0000000000000000000000000000000000000000'))throw Error('Four distinct nonzero test addresses required');
  if(await p.getBalance(a.address)===0n)throw Error('Deployer needs free Sepolia faucet ETH; no real funds required');
  const signers=[a,...others.map(address=>({getAddress:async()=>address}))];
  const contracts=await suite(signers);
  for(const x of addresses)await record('mint:wallet',contracts.t.mint(x,parseEther('1000')));
  for(const [x,amount] of [[contracts.f.target,'1000'],[contracts.q.target,'500'],[contracts.l.target,'50']])await record('mint:contract',contracts.t.mint(x,parseEther(amount)));
  saveEvidence('evidence/sepolia',{chainId:11155111,wallets:addresses,contracts:Object.fromEntries(Object.entries(contracts).map(([n,c])=>[n,c.target]))});
  console.log('Sepolia deployed. Public receipts saved in evidence/sepolia.');
} catch {
  // Avoid exposing credential-bearing RPC URLs or provider request payloads.
  console.error('Sepolia deployment failed. Check chain, keystore/password, addresses, RPC availability and free test ETH balance.');
  saveEvidence('evidence/sepolia-partial',{status:'incomplete'});process.exitCode=1;
} finally {p?.destroy();}
