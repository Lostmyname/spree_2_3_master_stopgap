module Spree
  Order.class_eval do
    class_attribute :line_item_comparison_hooks
    self.line_item_comparison_hooks = Set.new

    # Use this method in other gems that wish to register their own custom logic
    # that should be called when determining if two line items are equal.
    def self.register_line_item_comparison_hook(hook)
      self.line_item_comparison_hooks.add(hook)
    end

    def contains?(variant, options = {})
      find_line_item_by_variant(variant, options).present?
    end

    def quantity_of(variant, options = {})
      line_item = find_line_item_by_variant(variant, options)
      line_item ? line_item.quantity : 0
    end

    def find_line_item_by_variant(variant, options = {})
      line_items.detect { |line_item|
        line_item.variant_id == variant.id &&
        line_item_options_match(line_item, options)
      }
    end

    # This method enables extensions to participate in the
    # "Are these line items equal" decision.
    #
    # When adding to cart, an extension would send something like:
    # params[:product_customizations]={...}
    #
    # and would provide:
    #
    # def product_customizations_match
    def line_item_options_match(line_item, options)
      return true unless options

      options.keys.all? do |key|
        self.respond_to?("#{key}_match".to_sym) ||
        self.send("#{key}_match".to_sym, line_item, options[key])
      end
    end

    def merge!(order, user = nil)
      order.line_items.each do |other_order_line_item|
        next unless other_order_line_item.currency == currency

        # Compare the line items of the other order with mine.
        # Make sure you allow any extensions to chime in on whether or
        # not the extension-specific parts of the line item match
        current_line_item = self.line_items.detect { |my_li|
                      my_li.variant == other_order_line_item.variant &&
                      self.line_item_comparison_hooks.all? { |hook|
                        self.send(hook, my_li, other_order_line_item)
                      }
                    }
        if current_line_item
          current_line_item.quantity += other_order_line_item.quantity
          current_line_item.save
        else
          other_order_line_item.order_id = self.id
          other_order_line_item.save
        end
      end

      self.associate_user!(user) if !self.user && !user.blank?

      updater.update_item_count
      updater.update_item_total
      updater.persist_totals

      # So that the destroy doesn't take out line items which may have been re-assigned
      order.line_items.reload
      order.destroy
    end
  end
end
