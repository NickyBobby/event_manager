require 'csv'
require 'sunlight/congress'
require 'erb'
require 'pry'
require 'date'

class EventManager
  attr_accessor :days_of_the_week, :hours_of_the_day

  def initialize
    @days_of_the_week = []
    @hours_of_the_day = []
  end

  Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5, "0")[0..4]
  end

  def clean_phone_number(phone_number)
    phone_number = phone_number.to_s.delete('-()-+ ')
    if phone_number.length < 10
      phone_number = "bad number"
    elsif phone_number.length == 10
      return phone_number
    elsif phone_number.length == 11
      if phone_number[0] == 1
        phone_number[0] = ''
      else
        phone_number = "bad number"
      end
    else
      phone_number = "bad number"
    end
  end

  def parse_for_hour(reg_date)
    raw_date = reg_date.split(" ")[0].split("/")
    raw_time = reg_date.split(" ")[1].split(":")
    time = DateTime.new(raw_date[2].to_i,raw_date[0].to_i,raw_date[1].to_i,raw_time[0].to_i,raw_time[1].to_i)
    hour = time.strftime("%H")
  end

  def parse_for_day(reg_date)
    raw_date = reg_date.split(" ")[0].split("/")
    date = DateTime.new(raw_date[2].to_i,raw_date[0].to_i,raw_date[1].to_i)
    day_of_week = date.strftime("%A")
  end

  def legislators_by_zipcode(zipcode)
    legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
  end

  def save_thank_you_letters(id, form_letter)
    Dir.mkdir("output") unless Dir.exists? "output"

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
      file.puts form_letter
    end
  end

  def   push_days_to_an_array(day_of_week)
    @days_of_the_week << day_of_week
  end

  def   push_hours_to_an_array(hour)
    @hours_of_the_day << hour
  end

  def most_common_value(array)
    array.group_by { |e| e}.values.max_by(&:size).first
  end

  def run_event_manager

    puts "EventManager Initialized!"

    contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

    template_letter = File.read 'form_letter.erb'
    erb_template = ERB.new template_letter

    contents.each do |row|
      id = row[0]
      name = row[:first_name]
      hour = parse_for_hour(row[:regdate])

      day_of_week = parse_for_day(row[:regdate])

      phone_number = clean_phone_number(row[:homephone])

      zipcode = clean_zipcode(row[:zipcode])

      legislators = legislators_by_zipcode(zipcode)

      form_letter = erb_template.result(binding)

      push_days_to_an_array(day_of_week)

      push_hours_to_an_array(hour)

      # save_thank_you_letters(id, form_letter)
      # puts form_letter
    end
  end

end

planner = EventManager.new

planner.run_event_manager

days_array = planner.days_of_the_week
hours_array = planner.hours_of_the_day

most_common_day = planner.most_common_value(days_array)

most_common_hour = planner.most_common_value(hours_array)

puts "#{most_common_day} is the most common day of the week."
puts "#{most_common_hour} is the most common hour of the day."
