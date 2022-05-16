class ImportProductsJob < ApplicationJob
  queue_as :default

  def perform(product_import)
    user = product_import.user
    begin
      SolidusImportProducts::Downloader.call(product_import: product_import)
      product_import.reload

      SolidusImportProducts::Import.call(product_import: product_import)
      Spree::UserMailer.product_import_results(user).deliver_later
    rescue StandardError => exception
      Rails.logger.error("[ActiveJob] [ImportProductsJob] [#{job_id}] ID: #{product_import} #{exception}")
      Spree::UserMailer.product_import_results(user, "#{exception.message}  #{exception.backtrace.join('\n')}").deliver_later
    end
  end
end
