require 'aws-sdk-core'
require 'aws-sdk-s3'

module SolidusImportProducts
  class UploadPresigner
    def self.presign(prefix, filename, limit=nil)

      extname = File.extname(filename)
      filename = "#{SecureRandom.uuid}#{extname}"
      upload_key = Pathname.new(prefix).join(filename).to_s

      creds = Aws::Credentials.new(SolidusImportProducts::configuration.options[:s3_access_key_id], SolidusImportProducts::configuration.options[:s3_secret_access_key])
      s3 = Aws::S3::Resource.new(region: SolidusImportProducts::configuration.options[:s3_region], credentials: creds)

      obj = s3.bucket(SolidusImportProducts::configuration.options[:s3_bucket_name]).object(upload_key)

      params =  {} # { acl: 'public-read' }
      params[:content_length] = limit if limit

      {
        presigned_url: obj.presigned_url(:put, params),
        public_url: obj.public_url
      }
    end
  end
end