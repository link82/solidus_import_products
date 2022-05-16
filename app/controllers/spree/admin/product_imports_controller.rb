module Spree
  module Admin
    class ProductImportsController < BaseController

      def presign_upload
        # pass the limit option if you want to limit the file size
        render json: ::SolidusImportProducts::UploadPresigner.presign("", params[:filename], nil) # SolidusImportProducts::configuration.options[:bundle_upload_limit].to_i
      end

      def index
        @product_import = Spree::ProductImport.new
      end

      def show
        @product_import = Spree::ProductImport.find(params[:id])
        @products = @product_import.products
      end

      def create
        @product_import = spree_current_user.product_imports.new(product_import_params)
        if @product_import.save
          Rails.env.development? ? ImportProductsJob.perform_now(@product_import) : ImportProductsJob.perform_later(@product_import)
          flash[:notice] = t('product_import_processing')
          redirect_to admin_product_imports_path
        else
          render :index, notice: t('unable_to_save')
        end
      end

      def destroy
        @product_import = Spree::ProductImport.find(params[:id])
        if @product_import.destroy
          flash[:success] = t('delete_product_import_successful')
        end
        redirect_to admin_product_imports_path
      end

      private

      def product_import_params
        params.require(:product_import).permit!
      end
    end
  end
end
