module Spree
  Order.class_eval do
    def contains?(variant, options = nil)
      find_line_item_by_variant(variant, options).present?
    end

    def quantity_of(variant, options = nil)
      line_item = find_line_item_by_variant(variant, options)
      line_item ? line_item.quantity : 0
    end

    def find_line_item_by_variant(variant, options = nil)
      line_items.detect { |line_item|
        line_item.variant_id == variant.id &&
        line_item_options_match(line_item, options)
      }
    end

    # an extension would send params[:options][:product_customizations]={...}
    # and provide:
    # def product_customizations_match
    def line_item_options_match(line_item, options)
      return true unless options

      options.keys.all? do |key|
        self.send("#{options[key]}_match".to_sym, line_item, options[key])
      end
    end
  end
end
