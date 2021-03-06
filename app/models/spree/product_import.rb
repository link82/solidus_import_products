require 'open-uri'

# This model is the master routine for uploading products
# Requires Paperclip and CSV to upload the CSV file and read it nicely.

# Original Author:: Josh McArthur
# License:: MIT
module Spree
  class ProductImport < ActiveRecord::Base
    ENCODINGS = %w[UTF-8 iso-8859-1].freeze

    has_one_attached :data_file, service: ENV['STORAGE_SERVICE']
                      # path: '/product_data/data-files/:basename_:timestamp.:extension',
                      # url: '/product_data/data-files/:basename_:timestamp.:extension'

    belongs_to :user, class_name: 'Spree::User', foreign_key: 'created_by', inverse_of: :product_imports

    validates_presence_of :bundle_file_url,
                          allow_blank: false,
                          length: { maximum: 255 }

    #validates_attachment_presence :data_file
    validates :data_file,
              presence: true, attached: true,
              content_type: { content_type: ['text/csv', 'text/plain', 'text/comma-separated-values', 'application/octet-stream', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/csv'] }

    # Content type of csv vary in different browsers.
    # validates_attachment :data_file, presence: true, content_type: { content_type: ['text/csv', 'text/plain', 'text/comma-separated-values', 'application/octet-stream', 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/csv'] }

    after_destroy :destroy_products

    serialize :product_ids, Array
    cattr_accessor :settings

    state_machine initial: :created do
      event :start do
        transition to: :started, from: :created
      end
      event :download do
        transition to: :downloaded, from: :started
      end
      event :process do
        transition to: :processing, from: %i[started downloaded]
      end
      event :complete do
        transition to: :completed, from: %i[started downloaded processing]
      end
      event :failure do
        transition to: :failed, from: %i[created started processing]
      end

      before_transition to: [:failed] do |import|
        import.product_ids = []
        import.failed_at = Time.current
        import.completed_at = nil
      end

      before_transition to: [:completed] do |import|
        import.failed_at = nil
        import.completed_at = Time.current
      end
    end

    def get_data_file
      uri = data_file.url
      unless (uri =~ /http/).nil?
        file = Tempfile.new(encoding: 'ascii-8bit')
        file.write(Net::HTTP.get(URI.parse(uri)))
        file.path
      else
        uri
      end
    end

    def parse
      @_parse ||= SolidusImportProducts::Parser.parse(:csv, get_data_file, { encoding_csv: encoding_csv, separator_char: separatorChar })
    end

    def products
      Product.where(id: product_ids)
    end

    def add_product(product)
      product_ids << product.id unless product?(product)
    end

    def product?(product)
      product.id && product_ids.include?(product.id)
    end

    def products_count
      parse.product_count
    end

    def destroy_products
      products.destroy_all
    end

    def state_datetime
      if failed?
        failed_at
      elsif completed?
        completed_at
      else
        updated_at
      end
    end
  end
end
