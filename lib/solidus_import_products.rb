require 'solidus_core'
require 'solidus_support'
require 'solidus_auth_devise'
require 'deface'
require 'solidus_import_products/exception'
require 'solidus_import_products/logger'
require 'solidus_import_products/import_helper'
require 'solidus_import_products/engine'
require 'solidus_import_products/configuration'

module SolidusImportProducts
  class << self
    # Returns the current configuration object.
    #
    # @return [Configuration]
    def configuration
      @configuration ||= Configuration.new
    end

    # Yields the configuration object.
    #
    # @yield [configuration] passes the configuration to the block
    #
    # @yieldparam [Configuration] configuration the configuration object
    def configure
      yield configuration
    end
  end
end