module SolidusImportProducts
  class SaveProduct
    attr_accessor :product, :product_information, :logger

    include SolidusImportProducts::ImportHelper

    def self.call(options = {})
      new.call(options)
    end

    def call(args = { product: nil, product_information: nil })
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = args[:product_information]
      self.product = args[:product]

      logger.log("SAVE PRODUCT: #{product.inspect}", :debug)

      if !product.valid? && ([:"prices.sale_prices", :"master.prices.sale_prices", :prices] & product.errors.keys).any?
        product.save(validate: false)
        product.reload
      end

      unless product.valid?
        msg = "A product could not be imported - here is the information we have:\n" \
        "#{product_information}, #{product.inspect} #{product.errors.full_messages.join(', ')}"
        logger.log(msg, :error)
        raise SolidusImportProducts::Exception::ProductError, msg
      end
      product.save
      product.reload

      # Associate our new product with any taxonomies that we need to worry about
      if product_information[:attributes].key?(:taxonomies) && product_information[:attributes][:taxonomies]

        taxons = !product_information[:attributes][:taxonomies].is_a?(Array) ?
        [product_information[:attributes][:taxonomies]] :
        product_information[:attributes][:taxonomies]

        taxons.each do |taxon|
          associate_product_with_taxon(product, taxon, true)
        end
      end

      setup_product_sales(product, product_information[:attributes]) if !product_information[:attributes][:sale_price].blank? && product_information[:attributes][:sale_price].to_f > 0.0

      # Finally, attach any images that have been specified
      product_information[:images].each do |filename|
        find_and_attach_image_to(product, filename)
      end

      logger.log("#{product.name} successfully imported.\n")
      true
    end

    protected

    def setup_product_sales(product, product_data)
      return if product.price.nil? || product_data[:sale_price].blank?

      sale_price = product_data[:sale_price].to_f
      starts_at = product_data[:sale_price_start_at].blank? ? DateTime.now : product_data[:sale_price_start_at].to_date.beginning_of_day
      ends_at = product_data[:sale_price_ends_at].blank? ? nil : product_data[:sale_price_ends_at].to_datetime.end_of_day
      begin
        product.put_on_sale(sale_price, {all_variants: true, start_at: starts_at, end_at: ends_at, enabled: true })
      rescue => e
        logger.log("Error setting product sale price: #{e}")
        puts e
      end
    end
  end
end
