require 'fileutils'
require 'rest-client'
module JasperserverRails
  class Jasperserver

    self.class_eval do
      [:report, :format, :params].each do |method|
        define_method method do |arg|
          arg = arg.collect { |key, value| [key, value].join('=') }.join('&') if method == :params
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
      response2 = RestClient.get(
        [Rails.configuration.jasperserver[Rails.env.to_sym][:url], 'rest_v2/reports/reports/', "#{self.get_report}.#{self.get_format}?#{self.get_params}"].join(''),
        {:cookies => @cookie }
      )

      # Write file
      FileUtils.mkdir_p(File.expand_path(filename).split('/')[0..-2].join('/'))
      f = File.new(filename, 'wb')
      f.write(response2.body)
      f.close
    end
    
    private

    def login
      # login
      if @cookie.nil?
        response = RestClient.post(
        [Rails.configuration.jasperserver[Rails.env.to_sym][:url], 'rest/login'].join(''),
          {
            j_username: Rails.configuration.jasperserver[Rails.env.to_sym][:username],
            j_password: Rails.configuration.jasperserver[Rails.env.to_sym][:password]
          }
        )
        @cookie = response.cookies
      end
    end
  end
end
