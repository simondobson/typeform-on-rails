require 'bundler'
Bundler.require

require_relative 'typeform_request.rb'

@model_name = ''
@attribute_array = []

def assume_rails_type(block)
  case block[:type].to_sym
  when :yes_no, :legal
    :boolean
  when :short_text, :email, :multiple_choice, :picture_choice, :dropdown, :file_upload, :website
    :string
  when :long_text
    :text
  when :number, :opinion_scale, :rating
    :integer
  when :date
    :date
  end
end

def throw_request_error(request)
  if request.not_found?
    raise StandardError.new("That form doesn't exist!")
  else
    raise StandardError.new("Sorry! Retrieving the form failed")
  end
end

def get_model_info(form_id)
  unless form_id.length == 6
    raise ArgumentError.new("You must pass a form id to 'script.rb' and a form id is 6 characters long")
    exit
  end
  retrieve_form_request = TypeformRequest.new(form_id)
  throw_request_error(retrieve_form_request) unless retrieve_form_request.success?
  blocks = retrieve_form_request.blocks

  rails_types = [:binary, :boolean, :date, :datetime, :decimal, :float, :integer, :primary_key, :string, :text, :time, :timestamp]
  blocks.reject! { |block| block[:type].to_sym == :statement }
  payment_deleted = blocks.reject! { |block| block[:type].to_sym == :payment }
  puts "Sorry! Payment field is not supported yet in this Rails integration".red if !payment_deleted.nil?
  blocks.each do |block|
    attribute = Hash.new
    title = block[:title].green
    blue_x = 'x'.blue
    puts "For this block, '#{title}', how would you like the Rails attribute named?"
    puts "Enter #{blue_x} if you don't want to save this answer in your Rails project"
    puts ''
    attribute_name = STDIN.gets.chomp.downcase
    next if attribute_name == 'x'
    attribute[:attribute_name] = attribute_name
    attribute[:attribute_id] = block[:id]

    assumed_type = assume_rails_type(block).to_s
    puts "And is #{assumed_type.red} - the correct Rails type for this attribute?"
    puts '(y/n)'.blue
    puts ''
    answer = STDIN.gets.chomp.downcase
    correct_type = answer == 'y'

    if correct_type
      attribute[:typeform_type] = block[:type]
      attribute[:rails_type] = assumed_type
      @attribute_array << attribute
      next
    end

    type_found = false
    puts 'What type would you like it to be?'
    while(!type_found)
      rails_type = STDIN.gets.chomp.downcase
      if rails_types.include?(rails_type.to_sym)
        attribute[:typeform_type] = block[:type]
        attribute[:rails_type] = assumed_type
        @attribute_array << attribute
        type_found = true
      else
        puts 'Thats not a Rails type! Available types are below'
        puts rails_types.inspect
        puts
      end
    end
  end
  red_model = 'model'.red
  puts "Finally - how would you like your Rails #{red_model} named?"
  puts ''
  @model_name = STDIN.gets.chomp.capitalize
end

def generate_attribute_case_section(attribute)
  attribute_case_string = "              when '#{attribute[:attribute_id]}'"
  case attribute[:typeform_type].to_sym
    when :yes_no, :legal
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:boolean]"
    when :multiple_choice, :picture_choice, :dropdown
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:choice][:label]"
    when :file_upload
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:file_url]"
    when :email
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:email]"
    when :website
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:url]"
    when :short_text, :email, :website, :long_text
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:text]"
    when :number, :opinion_scale, :rating
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:number]"
    when :date
      attribute_case_string << "\n                #{attribute[:attribute_name]} = answer[:date]"
  end
  attribute_case_string << "\n"
  return attribute_case_string
end

def generate_model_attributes
  attributes_string = ''
  @attribute_array.each do |attribute|
    attributes_string << "#{attribute[:attribute_name].to_s}:#{attribute[:rails_type].to_s} "
  end
  return attributes_string
end

def generate_controller_code
  attributes_initializing = ''
  @attribute_array.each do |attribute|
    attributes_initializing << "#{attribute[:attribute_name].to_s}, "
  end
  attributes_initializing.chomp!(', ')
  attributes_initializing << ' = nil'

  attributes_case_statement = "case answer[:field][:id]\n"
  @attribute_array.each do |attribute|
    attributes_case_statement << generate_attribute_case_section(attribute)
  end
  attributes_case_statement << "            end"

  model_initializing = "@#{@model_name.downcase} = #{@model_name.capitalize}.new("
  @attribute_array.each do |attribute|
    model_initializing << "#{attribute[:attribute_name]}: #{attribute[:attribute_name]}, "
  end
  model_initializing.chomp!(', ')
  model_initializing << ")"

  return "
    class #{@model_name}sController < ApplicationController
      def new
        #Controller action for GET /#{@model_name.downcase}s/new
      end

      def index
        #Controller action for GET /#{@model_name.downcase}s/
      end

      def edit
        #Controller action for GET /#{@model_name.downcase}s/:id/edit
      end

      def show
        #Controller action for GET /#{@model_name.downcase}s/:id
      end

      def update
        #Controller action for PUT /#{@model_name.downcase}s/:id
        #Controller action for PATCH /#{@model_name.downcase}s/:id
      end

      def destroy
        #Controller action for DELETE /#{@model_name.downcase}s/:id
      end

      def create
        #Controller action for POST /#{@model_name.downcase}s/

        if params[:event_type] == 'form_response'
          #{attributes_initializing}

          answers = params[:form_response][:answers]
          answers.each do |answer|
            #{attributes_case_statement}
          end

          #{model_initializing}
          @#{@model_name.downcase}.save
        end

      end
    end"
end

def print_output
  puts "==========================================================================================================================".red
  puts ""
  puts "Set your typeform's webhooks to go to this address".green
  puts ""
  puts "https://{YOUR_RAILS_DOMAIN_HERE}/#{@model_name.downcase}s"
  puts ""
  puts "Enter this line in your 'config/routes.rb' file".green
  puts ""
  puts "resources :#{@model_name.downcase}s"
  puts ""
  puts "Execute these lines in your Rails repository".green
  puts ""
  puts "bin/rails generate model #{@model_name} #{generate_model_attributes}"
  puts "bin/rails generate controller #{@model_name}s"
  puts "bin/rails db:migrate"
  puts ""
  puts "Put this code in your '#{@model_name}sController.rb' file".green
  puts "#{generate_controller_code}"
  puts ""
end

form_id = ARGV[0]

get_model_info(form_id)

print_output
