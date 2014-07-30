module Spree
  LineItem.class_eval do
    def build_options(options)
      options.keys.each do |key|
        self.send("build_#{key}",options[key])
      end
    end
  end
end
