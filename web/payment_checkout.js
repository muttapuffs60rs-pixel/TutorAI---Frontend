// Razorpay Standard Checkout for Flutter web; verification stays on the server.
window.arivoraCheckout = (() => {
  let active;
  let cancel;
  return {
    open(options) {
      return new Promise((resolve, reject) => {
        if (active) return reject(new Error('Checkout is already open.'));
        if (!window.Razorpay) {
          return reject(new Error('Payment service could not load. Refresh and try again.'));
        }
        let finished = false;
        const finish = (error, result) => {
          if (finished) return;
          finished = true;
          active = null;
          cancel = null;
          error ? reject(error) : resolve(result);
        };
        cancel = () => finish(new Error('Checkout cancelled.'));
        try {
          active = new window.Razorpay({
            ...options,
            handler: result => finish(null, result),
            modal: { ondismiss: () => finish(new Error('Checkout cancelled.')) },
          });
          // Failed attempts can be retried within Checkout. Only settle on success
          // or dismissal, so a retry cannot lose its verification callback.
          active.open();
        } catch (error) {
          finish(error);
        }
      });
    },
    close() {
      const dismiss = cancel;
      active?.close();
      dismiss?.();
    },
  };
})();
