require 'fileutils'
require 'uri'
require 'rest-client'
module JasperserverRails
  class Jasperserver

    self.class_eval do
      [:report, :format, :params].each do |method|
        define_method method do |arg|
          arg = arg.collect { |key, value| [key, value] } if method == :params
          instance_variable_set "@#{method}".to_sym, arg
        end

        define_method "get_#{method}" do
          instance_variable_get "@#{method}".to_sym
        end
      end
    end

    def initialize(&block)
      instance_eval(&block) if block_given?
      login
    end

    def run_report(filename, &block)
      instance_eval(&block) if block_given?
      login
      # Run report
      config = YAML.load File.read(Rails.root.join('config/jasperserver.yml'))
      response2 = RestClient.get(
        URI.join(config[Rails.env]['url']+'/', "rest_v2/reports/reports/#{self.get_report}.#{self.get_format}?#{URI.encode_www_form(self.get_params)}").to_s,
        {:cookies => @cookie }
      )

      response2.body
    end
    
    private

    def login
      # login
      if @cookie.nil?
        config = YAML.load File.read(Rails.root.join('config/jasperserver.yml'))
        response = RestClient.post(
        URI.join(config[Rails.env]['url']+'/', 'rest/login').to_s,
          {
            j_username: config[Rails.env]['username'],
            j_password: config[Rails.env]['password']
          }
        )
        @cookie = response.cookies
      end
    end
  end
end
