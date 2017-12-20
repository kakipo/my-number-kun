require 'bundler/setup'
require 'sinatra'
require 'sinatra/json'

require 'haml'
require 'sass'
require 'coffee-script'
require 'tsubaki'

get '/' do
  @my_numbers = 10.times.map { Tsubaki::MyNumber.rand }
  @corp_numbers = 10.times.map { Tsubaki::CorporateNumber.rand }
  haml :index
end

get '/my_numbers.json' do
  my_numbers = 10.times.map { Tsubaki::MyNumber.rand }
  json my_numbers
end

get '/corp_numbers.json' do
  corp_numbers = 10.times.map { Tsubaki::CorporateNumber.rand }
  json corp_numbers
end
