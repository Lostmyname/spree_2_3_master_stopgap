module Spree
  module Core
    module Importer
      Order.class_eval do
        def self.import(user, params)
          begin
            ensure_country_id_from_params params[:ship_address_attributes]
            ensure_state_id_from_params params[:ship_address_attributes]
            ensure_country_id_from_params params[:bill_address_attributes]
            ensure_state_id_from_params params[:bill_address_attributes]

            create_params = params.slice :currency
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
              raise "Order import line items: #{e.message} #{line_item}"
            end
          end
        end
      end
    end
  end
end
