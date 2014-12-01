module Spree
  module Admin
    OrdersController.class_eval do

      def state_changes
        @order = Spree::Order.find_by_number!(params[:id])
        authorize! action, @order
        @items = @order.state_changes.includes(:user)
      end

    end
  end
end
