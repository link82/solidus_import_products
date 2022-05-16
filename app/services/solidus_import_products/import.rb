module SolidusImportProducts
  class Import
    attr_accessor :product_import, :logger, :images_path

    def initialize(args = { product_import: nil })
      self.product_import = args[:product_import]
      self.logger = SolidusImportProducts::Logger.instance
    end

    def self.call(options = {})
      new(options).call
    end

    def call
      # preload products
      skus_of_products_before_import = Spree::Product.all.map(&:sku)
      parser = product_import.parse
      col = parser.column_mappings

      product_import.process!
      ActiveRecord::Base.transaction do
        parser.data_rows.each do |row|
          SolidusImportProducts::ProcessRow.call(
            parser: parser,
            product_imports: product_import,
            row: row,
            col: col,
            skus_of_products_before_import: skus_of_products_before_import
          )
        end
      end

      product_import.complete!
    rescue SolidusImportProducts::Exception::Base => e
      product_import.failure!
      raise e
    end
  end
end
