module Spree
  CheckoutController.class_eval do
    def update
      if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
        @order.temporary_address = !params[:save_user_address]

        unless @order.next
          flash[:error] = @order.errors.full_messages.join("\n")
          redirect_to checkout_state_path(@order.state) and return
        end

        handle_post_update_redirect
      else
        render :edit
      end
    end

    private

    def handle_post_update_redirect
      if @order.completed?
        @current_order = nil
        flash.notice = Spree.t(:order_processed_successfully)
        flash['order_completed'] = true
        redirect_to completion_route
      else
        redirect_to checkout_state_path(@order.state)
      end
    end

    def ensure_valid_state
        unless skip_state_validation?
          if @order.total.to_f == 0 && @order.payment?
            @order.next
            handle_post_update_redirect
          else
            if (params[:state] && !@order.has_checkout_step?(params[:state])) ||
               (!params[:state] && !@order.has_checkout_step?(@order.state))
              @order.state = 'cart'
              redirect_to checkout_state_path(@order.checkout_steps.first)
            end
          end
        end

        # Fix for #4117
        # If confirmation of payment fails, redirect back to payment screen
        if params[:state] == "confirm" && @order.payment_required? && @order.payments.valid.empty?
          flash.keep
          redirect_to checkout_state_path("payment")
        end
      end
  end
end
