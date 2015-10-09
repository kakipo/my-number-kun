require 'bundler/setup'
require 'sinatra'

require 'haml'
require 'sass'
require 'coffee-script'

get '/' do
  @nums = 10.times.map { sample_my_number }
  haml :index
end

def sample_my_number
  digits = 11.times.reduce('') { |str, _n| str + (rand(9) + 1).to_s }
  "#{digits}#{calc_check_digits(digits)}"
end

def calc_check_digits(num)
  # 整数列化
  digits = num.to_s.chars.map(&:to_i)
  # 11桁しか認めない
  return nil unless digits.length == 11

  # 残った数字を小さい方から調べます
  digits.reverse!

  # 数列の和を11で割った余りを計算します
  remainder =  (1..11).inject(0) {|sum, i|
    p = digits[i-1]
    q = (i <= 6) ? i+1 : i-5
    sum + p*q
  } % 11

  remainder <= 1 ? 0 : (11 - remainder)
end