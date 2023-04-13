require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'
require 'time'
# zipcode to string. rsjust = puts '0' if the string is less than 5. [0..4] cut the length of string by 5
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(number)
  number.gsub!(/[^\d]/, '')
  if (number[0] == '1' && number.length == 11) || (number.length == 10)
  # puts "#{number}"
  end
end

def clean_time_targeting(regdate, array_time)
  regdate = Time.strptime(regdate, '%m/%d/%y %k:%M').strftime('%l %p')
  array_time.push(regdate)
  # puts "reg hour: #{regdate}"
  # puts "#{array}"
end

def day_of_the_week(regdate, array_date)
  regdate = Date.strptime(regdate, '%m/%d/%y %k:%M')
  week = regdate.strftime('%A')
  # week_num = regdate.wday
  array_date.push(week)
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

array_time = []
array_date = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_phone_number(row[:homephone])
  regdate = clean_time_targeting(row[:regdate], array_time)
  date_registered = day_of_the_week(row[:regdate], array_date)
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

# puts "#{array_date}"

def time_result(array_time)
  result = array_time.each_with_object(Hash.new(0)) do |plus, val|
    val[plus] += 1
  end
  result
  # puts "result: #{result.sort}"

  a = ''
  b = ''
  result.each do |k, v|
    next unless v == result.values.max

    a = a + k.to_s + ' and'
    b += v.to_s
    # puts "#{k} is the peak hour. There are #{v} people who registered at the same hour"
  end
  puts "#{a.chomp(' and')} is the time where most people registered. There are #{b.split('').uniq.to_s.gsub!(/[^\d]/,
                                                                                                             '')} who registered on that time"
end

def date_result(array_date)
  result = array_date.each_with_object(Hash.new(0)) do |plus, val|
    val[plus] += 1
  end
  result
  # puts "result: #{result.sort}"

  result.each do |k, v|
    if v == result.values.max
      puts "\nIn #{k} there are #{v} people who registered which is the largest number who registered on the same day of the week"
    end
  end
end

time_result(array_time)
date_result(array_date)
