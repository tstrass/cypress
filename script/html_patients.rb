require 'optparse'

args = {}

# get options (just the product, at the moment)
OptionParser.new do |opts|
  opts.banner = 'Usage: html_patients.rb [options]'

  opts.on('-pPRODUCT', '--product=PRODUCT', 'Product to get patients for') do |p|
    args['product'] = p
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

# We need a product ID to get the product
if args['product'].nil? || args['product'].empty?
  raise new ArgumentError, 'No product supplied'
end

product = Product.find(BSON::ObjectId.from_string(args['product']))
# Get the measure tests for the product
measure_tests = MeasureTest.where(product_id: product.id)
# Make a temporary file to write the zip to
file = Tempfile.new("all-patients-#{Time.now.to_i}")

# Put the zip for each measure into a big zip
Zip::ZipOutputStream.open(file.path) do |z|
  measure_tests.each do |m|
    z.put_next_entry("#{m.cms_id}_#{m.id}.html.zip".tr(' ', '_'))
    tfile = Tempfile.new("patients-#{Time.now.to_i}")
    Cypress::PatientZipper.zip(tfile, m.records, :html)
    z << tfile.read
  end
end

zipname = "html_patients_#{args['product']}_#{Time.now.to_i}.zip"

FileUtils.mv(file.path, Rails.root.join(zipname))

puts "Exported HTML patients as \"#{Rails.root.join(zipname)}\""
