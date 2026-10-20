const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs'); const vm=require('node:vm');
const code=fs.readFileSync('web/visitor_analytics.js','utf8');
function run(options={}) {
 const calls=[]; const store=options.store || new Map(); let next=0;
 const context={location:{hostname:'arivora.onrender.com'},navigator:options.navigator||{},document:{referrer:options.referrer||''},
  localStorage:{getItem:k=>store.get(k),setItem:(k,v)=>{if(options.blocked)throw Error();store.set(k,v)}},
  crypto:{randomUUID:()=>`00000000-0000-4000-8000-${String(++next).padStart(12,'0')}`},URL,Date,
  fetch:(url,args)=>{calls.push({url,args});return Promise.resolve({status:204})},setTimeout:()=>{}};
 vm.runInNewContext(code,context);return {calls,store};
}
test('one minimal event per opening and stable browser ID across reload',()=>{
 const first=run({referrer:'https://www.google.com/search?q=private+question'});
 const second=run({store:first.store});
 const a=JSON.parse(first.calls[0].args.body), b=JSON.parse(second.calls[0].args.body);
 assert.equal(a.visitor_id,b.visitor_id); assert.equal(a.source,'google');
 assert.deepEqual(Object.keys(a).sort(),['event_id','source','visitor_id']);
 assert.equal(first.calls[0].args.referrerPolicy,'no-referrer');
 assert.equal(first.calls.length,1);
});
test('privacy preferences and blocked storage suppress events',()=>{
 for(const options of [{navigator:{doNotTrack:'1'}},{navigator:{globalPrivacyControl:true}},{blocked:true}])assert.equal(run(options).calls.length,0);
});
test('referral source cannot contain a URL or private query',()=>{
 assert.equal(JSON.parse(run({referrer:'https://private.example.com/secret?token=abc'}).calls[0].args.body).source,'other');
 assert.equal(JSON.parse(run({referrer:'https://arivora.onrender.com/'}).calls[0].args.body).source,'direct');
});
