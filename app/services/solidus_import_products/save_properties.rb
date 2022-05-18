module SolidusImportProducts
  class SaveProperties
    attr_accessor :product, :properties_hash, :logger

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, properties_hash: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.properties_hash = args[:properties_hash]
      self.product = args[:product]

      properties_hash.each do |field, value|
        property = Spree::Property.where(name: field.to_s.parameterize).first_or_initialize(name: field.to_s.parameterize, presentation: field.to_s.humanize)
        next unless property.save

        product_property = Spree::ProductProperty.where(product_id: product.id, property_id: property.id).first_or_initialize
        product_property.value = value
        binding.pry unless product_property.valid?
        product_property.save!
      end
    end
  end
end
