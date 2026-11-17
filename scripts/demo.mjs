import {spawn} from 'node:child_process';
import assert from 'node:assert/strict';
import {JsonRpcProvider,parseEther as E,formatEther,MaxUint256,Wallet} from 'ethers';
import {suite,record,saveEvidence,names,records} from './common.mjs';
if(process.argv.includes('--watch'))process.env.DEMO_WATCH='1';
const port=18545;
// Fresh ephemeral mnemonic; never written to disk or printed. RPC only listens on loopback.
const mnemonic=Wallet.createRandom().mnemonic.phrase;
const child=spawn(process.execPath,['node_modules/@foundry-rs/anvil/bin.mjs','--host','127.0.0.1','--port',String(port),'--chain-id','31337','--mnemonic',mnemonic,'--silent'],{stdio:'ignore'});
let spawnError; child.on('error',e=>{spawnError=e;});
const p=new JsonRpcProvider(`http://127.0.0.1:${port}`,31337,{staticNetwork:true,cacheTimeout:-1});
p.pollingInterval=50;
const failures=[]; const snapshots=[];
async function rejected(label,fn) {
  let failed=false;
  try { await record(label,fn()); } catch(err) {
    failed=true; const r=err.receipt;
    if(process.env.DEMO_WATCH==='1')console.log(`✓ 安全拦截（预期回滚）: ${label} | status=${r?.status} | gas=${r?.gasUsed}`);
    assert(r && r.status===0, `${label}: expected a mined revert, not a transport error`);
    failures.push({label,kind:r?'mined-revert':'estimate-revert',status:r?.status??null,hash:r?.hash??null,gasUsed:r?.gasUsed.toString()??null,feeWei:r?.fee.toString()??null});
  } assert(failed,`${label} unexpectedly succeeded`);
}
try {
  let ready=false;
  for(let i=0;i<100;i++){ if(spawnError) throw spawnError; if(child.exitCode!==null)throw Error('Anvil exited (port may be occupied)'); try{await p.send('eth_chainId',[]);ready=true;break;}catch{await new Promise(r=>setTimeout(r,100));} }
  assert(ready,'Anvil startup timeout');
  const signers=await Promise.all([0,1,2,3].map(i=>p.getSigner(i)));
  const addresses=await Promise.all(signers.map(s=>s.getAddress()));
  const [A,B,C,D]=signers; const [a,b,c,d]=addresses;
  const {t,f,v,s,m,e,l,q,lab}=await suite(signers);
  const contracts={token:t.target,faucet:f.target,vault:v.target,spender:s.target,marketplace:m.target,escrow:e.target,timelock:l.target,treasury:q.target,lab:lab.target};
  async function snap(stage) {
    snapshots.push({stage,block:await p.getBlockNumber(),wallets:Object.fromEntries(await Promise.all(addresses.map(async(x,i)=>[names[i],{address:x,ILT:formatEther(await t.balanceOf(x)),ETH:formatEther(await p.getBalance(x))}]))),contracts:Object.fromEntries(await Promise.all(Object.entries(contracts).map(async([k,x])=>[k,formatEther(await t.balanceOf(x))]))),totalSupply:formatEther(await t.totalSupply()),vaultLiability:formatEther(await v.totalDeposits()),labAllowance: (await t.allowance(a,lab.target)).toString()});
  }
  for(const x of addresses) await record('mint:wallet',t.mint(x,E('1000')));
  for(const [x,amount] of [[f.target,'1000'],[q.target,'500'],[l.target,'50']])await record('mint:contract',t.mint(x,E(amount)));
  await snap('initial');
  await record('token:transfer',t.transfer(b,E('10'))); await record('token:burn',t.connect(B).burn(E('5')));
  await record('faucet:claim',f.claim()); await rejected('faucet:cooldown',()=>f.claim({gasLimit:150000}));
  await record('vault:approve',t.approve(v.target,E('40'))); await record('vault:deposit',v.deposit(E('40')));
  await snap('vault-funded'); await rejected('vault:other-user',()=>v.connect(D).withdraw(1,{gasLimit:150000})); await record('vault:withdraw',v.withdraw(E('40')));
  await record('spender:approve',t.approve(s.target,E('20'))); await rejected('spender:unauthorized',()=>s.connect(D).spend(a,d,1,{gasLimit:150000}));
  await record('spender:spend',s.connect(B).spend(a,c,E('20')));
  await record('market:set',m.connect(B).setProduct(1,E('15'),true)); await record('market:approve',t.approve(m.target,E('15'))); await record('market:buy',m.buy(1)); assert(await m.purchased(a,1));
  await record('escrow:approve',t.approve(e.target,E('60')));
  let now=(await p.getBlock('latest')).timestamp;
  await record('escrow:create-confirm',e.create(b,E('30'),now+100)); await record('escrow:confirm',e.confirm(0));
  await record('escrow:create-refund',e.create(b,E('30'),now+100)); await rejected('escrow:early-refund',()=>e.refund(1,{gasLimit:150000}));
  await record('multisig:propose',q.propose(d,E('100'))); await record('multisig:approve-A',q.approve(0));
  await rejected('multisig:one-signature',()=>q.execute(0,{gasLimit:150000})); await record('multisig:approve-B',q.connect(B).approve(0)); await record('multisig:execute',q.connect(C).execute(0));
  await rejected('timelock:early',()=>l.release({gasLimit:150000}));
  await p.send('evm_increaseTime',[86400]); await p.send('evm_mine',[]);
  await record('escrow:timeout-refund',e.refund(1)); await record('timelock:release',l.connect(C).release()); await record('faucet:next-day',f.claim());
  await snap('normal-operations-complete');
  await record('lab:unlimited-approval',t.approve(lab.target,MaxUint256)); await record('lab:malicious-drain',lab.connect(D).drain(a,E('100')));
  assert.equal(await t.allowance(a,lab.target),MaxUint256);
  await record('lab:revoke',t.approve(lab.target,0)); await rejected('lab:revoked-drain',()=>lab.connect(D).drain(a,1,{gasLimit:150000}));
  await record('lab:old-allowance',t.approve(lab.target,E('100'))); await record('lab:front-run-old',lab.connect(D).drain(a,E('100')));
  await record('lab:replacement-allowance',t.approve(lab.target,E('50'))); await record('lab:spend-new',lab.connect(D).drain(a,E('50')));
  await record('lab:exact-allowance',t.approve(lab.target,E('10'))); await record('lab:bounded-drain',lab.connect(D).drain(a,E('10')));
  await rejected('lab:exact-exhausted',()=>lab.connect(D).drain(a,1,{gasLimit:150000}));
  await snap('final');
  if(process.env.DEMO_WATCH==='1')console.table(snapshots.at(-1).wallets);
  assert.equal(await v.totalDeposits(),0n); assert.equal(await t.balanceOf(e.target),0n); assert.equal(await t.balanceOf(l.target),0n);
  assert.equal(await t.totalSupply(),E('5545'));
  assert.deepEqual(await Promise.all(addresses.map(x=>t.balanceOf(x))),['865','1050','1020','1410'].map(E));
  const state={purchased:await m.purchased(a,1),escrow:[Number((await e.deals(0)).state),Number((await e.deals(1)).state)],treasuryExecuted:(await q.payments(0)).executed,labAllowance:(await t.allowance(a,lab.target)).toString()};
  saveEvidence('evidence/local',{network:'Anvil',chainId:31337,generatedAt:new Date().toISOString(),wallets:Object.fromEntries(names.map((n,i)=>[n,addresses[i]])),contracts,snapshots,state,expectedFailures:failures});
  console.log(`PASS: ${records.length} successful transactions; ${failures.length} expected failures; four wallet balances verified. Evidence: evidence/local/`);
} finally { p.destroy(); child.kill('SIGTERM'); }
