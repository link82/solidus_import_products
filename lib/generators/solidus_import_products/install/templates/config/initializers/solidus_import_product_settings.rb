SolidusImportProducts.configure do |config|
  config.options = [
    num_prods_for_delayed: 20, # From this number of products, the process is executed in delayed_job. Under it is processed immediately.
  ]
end
