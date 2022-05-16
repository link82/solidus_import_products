# frozen_string_literal: true

module SolidusImportProducts
  # Configuration class for holding the gem's current configuration.
  class Configuration

    def options=(hash)
      @options = hash
    end
    # @return [Hash{Symbol => String}] a name-to-class mapping of data segments
    def options
      @options ||= {
        num_prods_for_delayed: 20, # From this number of products, the process is executed in delayed_job. Under it is processed immediately.
        create_missing_taxonomies: true,
        product_image_path: "#{Rails.root}/lib/etc/product_data/product-images/", # The location of images on disk
        log_to: File.join(Rails.root, '/log/', "import_products_#{Rails.env}.log"), # Where to log to
        destroy_original_products: false, # Disabled #Delete the products originally in the database after the import?
        create_variants: true, # Compares products and creates a variant if that product already exists.
        store_field: :store_code, # Which field of the column mappings contains either the store id or store code?
        transaction: true, # import product in a sql transaction so we can rollback when an exception is raised
        bundle_upload_limit: 1.gigabyte,
        root_taxonomy_name: 'catalog_root',
        s3_access_key_id: '',
        s3_secret_access_key: '',
        s3_bucket_name: '',
        s3_region: 'eu-central-1'
      }
    end

  end
end
