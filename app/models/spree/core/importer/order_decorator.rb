module Spree
  module Core
    module Importer
      Order.class_eval do
        def self.import(user, params, options={})
          begin
            ensure_country_id_from_params params[:ship_address_attributes]
            ensure_state_id_from_params params[:ship_address_attributes]
            ensure_country_id_from_params params[:bill_address_attributes]
            ensure_state_id_from_params params[:bill_address_attributes]

            # Use options[:create_params] to insert any attributes which need to be present before
            # creating line items, shipments, etc
            create_params = [:currency] + (options[:create_params] || [])
            create_params = params.slice(*create_params)

            order = Spree::Order.create! create_params
            order.associate_user!(user)

            create_line_items_from_params(params.delete(:line_items_attributes),order)
            create_shipments_from_params(params.delete(:shipments_attributes), order)
            create_adjustments_from_params(params.delete(:adjustments_attributes), order)
            create_payments_from_params(params.delete(:payments_attributes), order)

            if completed_at = params.delete(:completed_at)
              order.completed_at = completed_at
              order.state = 'complete'
            end

            order.update_attributes!(params)

            # Really ensure that the order totals & states are correct
            order.updater.update
            order.reload
          rescue Exception => e
            order.destroy if order && order.persisted?
            raise e.message
          end
        end

        def self.create_line_items_from_params(line_items_hash, order)
          return {} unless line_items_hash
          line_items_hash.each_key do |k|
            begin
              line_item = line_items_hash[k]
              ensure_variant_id_from_params(line_item)

              extra_params = line_item.except(:variant_id, :quantity, :options)
              line_item = order.contents.add(Spree::Variant.find(line_item[:variant_id]), line_item[:quantity], line_item[:options])
              line_item.update!(extra_params) unless extra_params.empty?
            rescue Exception => e
              raise "(csv line: #{k}) #{e.message}."
            end
          end
        end

        def self.create_shipments_from_params(shipments_hash, order)
          return [] unless shipments_hash

          line_items = order.line_items
          shipments_hash.each do |s|
            begin
              shipment = order.shipments.build
              shipment.tracking       = s[:tracking]
              shipment.stock_location = Spree::StockLocation.find_by_admin_name(s[:stock_location]) || Spree::StockLocation.find_by_name!(s[:stock_location])

              inventory_units = s[:inventory_units] || []
              inventory_units.each do |iu|
                ensure_variant_id_from_params(iu)

                unit = shipment.inventory_units.build
                unit.order = order

                # Spree expects a Inventory Unit to always reference a line
                # item and variant otherwise users might get exceptions when
                # trying to view these units. Note the Importer might not be
                # able to find the line item if line_item.variant_id |= iu.variant_id
                unit.variant_id = iu[:variant_id]
                unit.line_item_id = line_items.select do |l|
                  l.variant_id.to_i == iu[:variant_id].to_i
                end.first.try(:id)
              end

              # Creating inventory units if they don't exist
              if shipment.save! && shipment.inventory_units.empty?
                shipment.order.line_items.each do |line_item|
                  line_item.target_shipment = shipment
                  line_item.save
                end
              end

              # Mark shipped if it should be.
              if s[:shipped_at].present?
                shipment.shipped_at = s[:shipped_at]
                shipment.state      = 'shipped'
                shipment.inventory_units.each do |unit|
                  unit.state = 'shipped'
                end
              end

              shipment.save!

              shipping_method = Spree::ShippingMethod.find_by_name(s[:shipping_method]) || Spree::ShippingMethod.find_by_admin_name!(s[:shipping_method])
              rate = shipment.shipping_rates.create!(:shipping_method => shipping_method,
                                                     :cost => s[:cost])
              shipment.selected_shipping_rate_id = rate.id
              shipment.update_amounts

            rescue Exception => e
              raise "Order import shipments: #{e.message} #{s}"
            end
          end
        end
      end
    end
  end
end
