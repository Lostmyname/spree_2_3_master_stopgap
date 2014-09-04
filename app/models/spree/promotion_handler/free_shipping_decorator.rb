module Spree
  module PromotionHandler
    FreeShipping.class_eval do
      private
      def promotions
        Spree::Promotion.active.where({
                      :id => Spree::Promotion::Actions::FreeShipping.pluck(:promotion_id)})
      end
    end
  end
end
