module Spree
  module Api
    ShipmentsController.class_eval do
      def create
        @order = Spree::Order.find_by!(number: params[:shipment][:order_id])
        authorize! :read, @order
        authorize! :create, Shipment
        variant = Spree::Variant.find(params[:variant_id])
        quantity = params[:quantity].to_i
        @shipment = @order.shipments.create(stock_location_id: params[:stock_location_id])
        @order.contents.add(variant, quantity, {shipment: @shipment})

        @shipment.refresh_rates
        @shipment.save!

        respond_with(@shipment.reload, default_template: :show)
      end

      def add
        variant = Spree::Variant.find(params[:variant_id])
        quantity = params[:quantity].to_i

        @shipment.order.contents.add(variant, quantity, {shipment: @shipment})

        respond_with(@shipment, default_template: :show)
      end
    end

    def remove
      variant = Spree::Variant.find(params[:variant_id])
      quantity = params[:quantity].to_i

      @shipment.order.contents.remove(variant, quantity, {shipment: @shipment})
      @shipment.reload if @shipment.persisted?
      respond_with(@shipment, default_template: :show)
    end
  end
end
