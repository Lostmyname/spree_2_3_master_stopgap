module Spree
  Variant.class_eval do
    def price_modifier_amount_in(currency, options = {})
      return 0 unless options.present?

      options.keys.map { |key|
        m = "#{key}_price_modifier_amount_in".to_sym
        if self.respond_to? m
          self.send(m, currency, options[key])
        else
          0
        end
      }.sum
    end

    def price_modifier_amount(options = {})
      return 0 unless options.present?

      options.keys.map { |key|
        m = "#{options[key]}_price_modifier_amount".to_sym
        if self.respond_to? m
          self.send(m, options[key])
        else
          0
        end
      }.sum
    end
  end
end
