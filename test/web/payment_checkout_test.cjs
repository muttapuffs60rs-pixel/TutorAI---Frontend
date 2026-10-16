const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const script = fs.readFileSync(path.join(__dirname, '../../web/payment_checkout.js'), 'utf8');
function setup(available = true) {
  let checkout;
  const window = {};
  if (available) window.Razorpay = class {
    constructor(options) { this.options = options; checkout = this; }
    open() {}
    close() { this.options.modal.ondismiss(); }
  };
  vm.runInNewContext(script, { window });
  return { api: window.arivoraCheckout, checkout: () => checkout };
}
test('passes server order options and returns signed response once', async () => {
  const {api, checkout} = setup();
  const pending = api.open({order_id:'order_1',amount:99900,key:'rzp_test_public'});
  assert.equal(checkout().options.amount,99900);
  assert.equal(checkout().options.order_id,'order_1');
  const response = {razorpay_payment_id:'pay_1',razorpay_order_id:'order_1',razorpay_signature:'signed'};
  checkout().options.handler(response);
  checkout().options.modal.ondismiss();
  assert.deepEqual(await pending,response);
});
test('dismissal releases checkout so another purchase can start', async () => {
  const {api,checkout} = setup();
  const pending = api.open({});
  checkout().options.modal.ondismiss();
  await assert.rejects(pending,/cancelled/);
  const next = api.open({});
  checkout().options.handler({ok:true});
  assert.equal((await next).ok,true);
});
test('missing SDK reports an error', async () => {
  await assert.rejects(setup(false).api.open({}),/could not load/);
});
test('duplicate launch is rejected and disposal cancels pending checkout', async () => {
  const {api} = setup();
  const pending = api.open({});
  await assert.rejects(api.open({}),/already open/);
  api.close();
  await assert.rejects(pending,/cancelled/);
});
