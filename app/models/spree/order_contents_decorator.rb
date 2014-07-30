module Spree
  OrderContents.class_eval do
    def add(variant, quantity = 1, currency = nil, shipment = nil, options = {})
      line_item = add_to_line_item(variant, quantity, currency, shipment, options)
      reload_totals
      PromotionHandler::Cart.new(order, line_item).activate
      ItemAdjustments.new(line_item).update
      reload_totals
      line_item
    end

    def remove(variant, quantity = 1, shipment = nil, options = {})
      line_item = remove_from_line_item(variant, quantity, shipment, options)
      reload_totals
      PromotionHandler::Cart.new(order, line_item).activate
      ItemAdjustments.new(line_item).update
      reload_totals
      line_item
    end

    private

    def add_to_line_item(variant, quantity, currency=nil, shipment=nil, options = {})
      line_item = grab_line_item_by_variant(variant, false, options)

      if line_item
        line_item.target_shipment = shipment
        line_item.quantity += quantity.to_i
        line_item.currency = currency unless currency.nil?
      else
        line_item = order.line_items.new(quantity: quantity, variant: variant)
        line_item.target_shipment = shipment
        if currency
          line_item.currency = currency
          line_item.price    = variant.price_in(currency).amount +
                              variant.price_modifier_amount_in(currency, options)
        else
          line_item.price    = variant.price +
                               variant.price_modifier_amount(options)
        end

        line_item.build_options(options) if options
      end

      line_item.save
      line_item
    end

    def remove_from_line_item(variant, quantity, shipment=nil, options = {})
      line_item = grab_line_item_by_variant(variant, true, options)
      line_item.quantity += -quantity
      line_item.target_shipment= shipment

      if line_item.quantity == 0
        line_item.destroy
      else
        line_item.save!
      end

      line_item
    end

    def grab_line_item_by_variant(variant, raise_error = false, options = nil)
      line_item = order.find_line_item_by_variant(variant, options)

      if !line_item.present? && raise_error
        raise ActiveRecord::RecordNotFound, "Line item not found for variant #{variant.sku}"
      end

      line_item
    end
  end
end
