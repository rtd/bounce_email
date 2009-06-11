$:.unshift(File.dirname(__FILE__)) unless
$:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'yaml'
require 'tmail'

module BounceEmail
  VERSION = '0.1.0'
  #    I used quite much from http://www.phpclasses.org/browse/package/2691.html
  
  class Mail
    def initialize(mail) # You have to pass TMail object
      @mail = mail
      parse(:subject)
      parse(:from)      
    end
    
    def method_missing( name, params)
    #  if name =~ /is_([a-z]+)\?/
    end

    def was_send_to
      original_mail.to
    rescue
      nil
    end  

    def original_mail
      @original_mail ||= get_original_mail(@mail)
    end
    
    private
    def parse()
    end
    
  end
  
  class Parse
    
    @@data = { :subject => {}, :from => {}, :body => {} }
    @@raw_data = nil
        
    def self.data
      @@data 
    end
    
    def self.r_data
      @@raw_data ||= YAML.load_file('lib/data.yml') #build_data(  )
    end
    
    def self.explain(key, raw_data = r_data)
      key = Array(key)      
      return raw_data['desc'] if raw_data['desc']
      raw_data = raw_data[key.shift]
      explain(key, raw_data)
    rescue
      nil  
    end
    
    private
    def self.build_data( parent_data, parent_key = [] )
      parent_data.each do |key,data|        
        next @@data[key.to_sym][prepare_data(data)] = parent_key if @@data.keys.include?(key.to_sym)
        next build_data( data, parent_key.clone << key ) if data.is_a?(Hash)
      end
    end
    
    def self.prepare_data(data)
      data.gsub("\n", "|").gsub(" ", ".?")
    end
    
  end
    
end