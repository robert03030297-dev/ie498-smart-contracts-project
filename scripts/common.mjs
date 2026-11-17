import fs from 'node:fs';
import {ContractFactory} from 'ethers';
export const names=['Alice','Bob','Charlie','Dana'];
export const records=[];
export async function record(label, pending) {
  const tx=await pending; const r=await tx.wait();
  records.push({label,hash:r.hash,from:r.from,to:r.to,block:r.blockNumber,status:r.status,gasUsed:r.gasUsed.toString(),gasPrice:r.gasPrice.toString(),feeWei:r.fee.toString(),logs:r.logs.map(l=>({address:l.address,topics:l.topics,data:l.data}))});
  if(process.env.DEMO_WATCH === "1") {
    console.log(`✓ ${label} | status=${r.status} | gas=${r.gasUsed} | block=${r.blockNumber}\n  ${r.hash}`);
    await new Promise(resolve=>setTimeout(resolve,700));
  }
  return r;
}
export async function deploy(name,signer,args=[]) {
  const a=JSON.parse(fs.readFileSync(`out/Project.sol/${name}.json`));
  const c=await new ContractFactory(a.abi,a.bytecode.object,signer).deploy(...args);
  await record(`deploy:${name}`,c.deploymentTransaction()); return c;
}
export async function suite(signers) {
  const addresses=await Promise.all(signers.map(s=>s.getAddress()));
  const t=await deploy('IlliniToken',signers[0],[addresses[0]]);
  const f=await deploy('TokenFaucet',signers[0],[t.target]);
  const v=await deploy('TokenVault',signers[0],[t.target]);
  const s=await deploy('TokenSpender',signers[0],[t.target,addresses[1]]);
  const m=await deploy('TokenMarketplace',signers[0],[t.target,addresses[1]]);
  const e=await deploy('TokenEscrow',signers[0],[t.target]);
  const now=(await signers[0].provider.getBlock('latest')).timestamp;
  const l=await deploy('TokenTimelock',signers[0],[t.target,addresses[3],now+86400]);
  const q=await deploy('MultisigTreasury',signers[0],[t.target,addresses.slice(0,3)]);
  const lab=await deploy('ApprovalSecurityLab',signers[0],[t.target]);
  return {t,f,v,s,m,e,l,q,lab};
}
export function saveEvidence(dir,data) {
  fs.mkdirSync(dir,{recursive:true});
  fs.writeFileSync(`${dir}/run.json`,JSON.stringify({...data,transactions:records},null,2));
  if(data.expectedFailures){
    const keys=['label','kind','status','hash','gasUsed','feeWei'];
    fs.writeFileSync(`${dir}/failed-transactions.csv`,keys.join(',')+'\n'+data.expectedFailures.map(r=>keys.map(k=>r[k]??'').join(',')).join('\n')+'\n');
  }
  const cols=['label','hash','from','to','block','status','gasUsed','gasPrice','feeWei'];
  fs.writeFileSync(`${dir}/transactions.csv`,cols.join(',')+'\n'+records.map(r=>cols.map(k=>r[k]??'').join(',')).join('\n')+'\n');
}
