require "factory_girl"
require "faker"
require File.join(settings.root, 'spec', 'factories', 'zip_codes.rb')

FactoryGirl.create_list(:zip_code, 40)
