module Spree
  module Core
    module Importer
      Order.class_eval do
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
              puts e
              puts e.backtrace
              raise "Order import line items: #{e.message} #{line_item}"
            end
          end
        end
      end
    end
  end
end
