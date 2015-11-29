require 'bundler/setup'
require 'sinatra'

require 'haml'
require 'sass'
require 'coffee-script'
require 'tsubaki'

get '/' do
  @my_numbers = 10.times.map { Tsubaki::MyNumber.rand }
  @corp_numbers = 10.times.map { Tsubaki::CorporateNumber.rand }
  haml :index
end
