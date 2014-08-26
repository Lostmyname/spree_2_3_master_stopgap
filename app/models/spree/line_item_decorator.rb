module Spree
  LineItem.class_eval do
    def options=(options={})
      opts = options.dup # we will be deleting from the hash, so leave the caller's copy intact

      currency = opts.delete(:currency) || order.currency
      self.target_shipment = opts.delete(:shipment) if opts.has_key?(:shipment)

      if currency
        self.currency = currency
        self.price    = variant.price_in(currency).amount +
                        variant.price_modifier_amount_in(currency, opts)
      else
        self.price    = variant.price +
                        variant.price_modifier_amount(opts)
      end

      options.each { |key, value| self.send "#{key}=", value }
    end
  end
end
