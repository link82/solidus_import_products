require 'open-uri'
require 'aws-sdk-core'
require 'aws-sdk-s3'

module SolidusImportProducts
  class Downloader
    attr_accessor :product_import, :logger

    def initialize(args = { product_import: nil })
      self.product_import = args[:product_import]
      self.logger = SolidusImportProducts::Logger.instance
    end

    def self.call(options = {})
      new(options).call
    end

    def call
      begin
        raise StandardError.new('Missing archive file') if product_import.bundle_file_url.blank?

        product_import.start
        output_uri = SolidusImportProducts::configuration.options[:product_image_path]
        FileUtils.mkdir_p(output_uri)

        output_file = output_uri + "/#{product_import.id}.zip"
        File.delete(output_file) if File.exist?(output_file)

        file_path = product_import.bundle_file_url.split('/')[1..-1].keep_if(&:present?)[1..-1].join('/')

        creds = Aws::Credentials.new(SolidusImportProducts::configuration.options[:s3_access_key_id], SolidusImportProducts::configuration.options[:s3_secret_access_key])
        s3 = Aws::S3::Client.new(region: SolidusImportProducts::configuration.options[:s3_region], credentials: creds)

        bytes = 0

        open output_file, 'wb' do |io|
          s3.get_object(bucket: SolidusImportProducts::configuration.options[:s3_bucket_name], key: file_path)do |chunk|
            bytes += chunk.size
            logger.log("[Downloader] (#{file_path}) Downloaded #{bytes / 1024} Kb")
            puts("[Downloader] (#{file_path}) Downloaded #{bytes / 1024} Kb")
            io.write(chunk)
          end
        end

        system "cd #{output_uri} && mkdir -p #{product_import.id} && unzip -o #{output_file} -d #{product_import.id}"
        logger.log("[Downloader] (#{file_path}) Extracting file...")
        puts("[Downloader] (#{file_path}) Extracting file...")

        product_import.download

      rescue SolidusImportProducts::Exception::Base => e
        product_import.failure!
        raise e
      end

    end
  end
end
