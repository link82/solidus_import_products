require 'csv'

module SolidusImportProducts
  module Parser
    class Csv < Base
      DEFAULT_CSV_ENCODING = 'utf-8'.freeze
      DEFAULT_CSV_SEPARATOR = ','.freeze

      attr_accessor :variant_option_fields, :mappings

      def initialize(data_file, options)
        self.data_file = data_file
        self.mappings = {}
        self.variant_option_fields = []
        self.image_fields = []
        self.variant_image_fields = []
        self.property_fields = []
        encoding_csv = (options[:encoding_csv] if options) || DEFAULT_CSV_ENCODING
        separator_char = (options[:separator_char] if options) || DEFAULT_CSV_SEPARATOR
        csv_string = open(data_file, "r:#{encoding_csv}").read.encode('utf-8')
        self.rows = CSV.parse(csv_string, col_sep: separator_char, quote_char: '"', force_quotes: true)
        extract_column_mappings
      end

      # column_mappings
      # This method attempts to automatically map headings in the CSV files
      # with fields in the product and variant models.
      # Rows[0] is an array of headings for columns - SKU, Master Price, etc.)
      # @return a hash of symbol heading => column index pairs
      def column_mappings
        mappings
      end

      # variant_option_field?
      # Class method that check if a field is a variant option field
      # @return true or false
      def variant_option_field?(field)
        variant_option_fields.include?(field.to_s)
      end

      # property_field?
      # Class method that check if a field is a product property field
      # @return true or false
      def property_field?(field)
        property_fields.include?(field.to_s)
      end

      # image_field?
      # Class method that check if a field is an image field
      # @return true or false
      def image_field?(field)
        image_fields.include?(field.to_s)
      end

      # variant_image_field?
      # Class method that check if a field is a variant image field
      # @return true or false
      def variant_image_field?(field)
        variant_image_fields.include?(field.to_s)
      end

      # data_rows
      # This method fetch the product rows.
      # @return a array of columns with product information
      def data_rows
        rows[1..-1]
      end

      # products_count
      # This method count the product rows.
      # @return a integer
      def products_count
        data_rows.count
      end

      protected

      def extract_column_mappings
        rows[0].each_with_index do |heading, index|
          break if heading.blank?
          field_name = heading.downcase.gsub(/\A\s*/, '').chomp.gsub(/\s/, '_')
          if field_name.include?('[opt]')
            field_name.gsub!('[opt]', '')
            variant_option_fields.push(field_name)
          elsif field_name.include?('[prop]')
            field_name.gsub!('[prop]', '')
            property_fields.push(field_name)
          elsif field_name.include?('image_product')
            image_fields.push(field_name)
          elsif field_name.include?('image_variant')
            variant_image_fields.push(field_name)
          end
          mappings[field_name.to_sym] = index
        end
      end
    end
  end
end
