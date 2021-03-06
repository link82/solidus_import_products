module SolidusImportProducts
  class ProcessRow
    attr_accessor :parser, :product_imports, :logger, :row, :col, :product_information, :master_field, :skus_of_products_before_import

    MASTER_FIELD_NAME = :master_sku

    def initialize(args = { parser: nil, product_imports: nil, row: nil, col: nil, skus_of_products_before_import: nil })
      self.parser = args[:parser]
      self.product_imports = args[:product_imports]
      self.row = args[:row]
      self.col = args[:col]
      self.master_field = MASTER_FIELD_NAME
      self.skus_of_products_before_import = args[:skus_of_products_before_import]
      self.logger = SolidusImportProducts::Logger.instance
      self.product_information = { variant_options: {}, images: [], variant_images: [], product_properties: {}, attributes: {} }
    end

    def self.call(options = {})
      new(options).call
    end

    def call
      extract_product_information
      # extract_categories
      product_information_default_values
      extract_product_images

      # extract_variant_images
      # logger.log(product_information.to_s, :debug)

      variant_column = col[master_field]
      product = Spree::Product.find_by(master_field.to_s => row[variant_column])

      unless product
        if skus_of_products_before_import.include?(product_information[:attributes][:sku])
          raise SolidusImportProducts::Exception::ProductError, "SKU #{product_information[:attributes][:sku]} exists, but #{variant_field}: #{row[variant_column]} not exists!! "
        end
        product = Spree::Product.new
      end

      unless product_imports.product?(product)
        create_or_update_product(product)
        product_imports.add_product(product)
      end

      SolidusImportProducts::CreateVariant.call(product: product, product_information: product_information)
    end

    private

    def create_or_update_product(product)
      properties_hash = SolidusImportProducts::UpdateProduct.call(product: product, product_information: product_information)
      SolidusImportProducts::SaveProduct.call(product: product, product_information: product_information)
      SolidusImportProducts::SaveProperties.call(product: product, properties_hash: properties_hash)
    end

    def extract_categories
      if !product_information[:attributes][:taxonomies] && product_information[:attributes][:category]
        if product_information[:attributes][:subcategories]
          product_information[:attributes][:taxonomies] = product_information[:attributes][:subcategories].split(',').map {|subcat| "#{product_information[:attributes][:category]} > #{subcat}"}
        else
          product_information[:attributes][:taxonomies] = product_information[:attributes][:category]
        end
      end
    end

    def extract_product_images
      return if product_information[:images].any?

      images_path = SolidusImportProducts::configuration.options[:product_image_path] + "/#{product_imports.id}/images/#{product_information[:attributes][:sku]}/**/*"
      Dir[images_path].keep_if {|k| !File.directory?(k) }.each do |path|
        product_information[:images].push(path.gsub(SolidusImportProducts::configuration.options[:product_image_path], ''))
      end
    end

    def extract_variant_images
      return if product_information[:variant_images].any?

      images_path = SolidusImportProducts::configuration.options[:product_image_path] + "/#{product_imports.id}/images/#{product_information[:attributes][:sku]}/**/*"
      Dir[images_path].keep_if {|k| !File.directory?(k) }.each do |path|
        product_information[:variant_images].push(path.gsub(SolidusImportProducts::configuration.options[:product_image_path], ''))
      end
    end

    def extract_product_information
      col.each do |key, value|
        row[value].try :strip!
        if parser.variant_option_field?(key)
          product_information[:variant_options][key] = row[value]
        elsif parser.property_field?(key)
          product_information[:product_properties][key] = row[value]
        elsif parser.image_field?(key)
          product_information[:images].push(row[value])
        elsif parser.variant_image_field?(key)
          product_information[:variant_images].push(row[value])
        else
          product_information[:attributes][key] = key.to_s.eql?('price') ? convert_to_price(row[value]) : row[value]
        end
      end
    end

    def product_information_default_values
      product_information[:attributes][:available_on] = Time.zone.today - 1.day if product_information[:attributes][:available_on].nil?

      if product_information[:attributes][:shipping_category_id].nil?
        sc = Spree::ShippingCategory.first
        product_information[:attributes][:shipping_category_id] = sc.id if sc
      end

      product_information[:attributes][:retail_only] = 0 if product_information[:attributes][:retail_only].nil?
    end

    # Special process of prices because of locales and different decimal separator characters.
    # We want to get a format with dot as decimal separator and without thousand separator
    def convert_to_price(price_str)
      raise SolidusImportProducts::Exception::InvalidPrice unless price_str
      punt = price_str.index('.')
      coma = price_str.index(',')
      if !coma.nil? && !punt.nil?
        price_str.gsub!(punt < coma ? '.' : ',', '')
      end
      price_str.tr(',', '.').to_f
    end
  end
end
