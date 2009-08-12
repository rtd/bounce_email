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
      @full_code = parse(:from) || parse(:subject)
    end

    #################################################################

    def is_bounce?( full_parse = false)
      return full_code if full_parse
      @full_code #don't parse body, only on demand
    end

    def reason
      BounceEmail::Parse.explain(full_code)
    end

    def type
      full_code[0]
    end

    def code_nr
      full_code[1]
    end

    def code
      "#{full_code[0]}.#{full_code[1][0]}.#{full_code[1][1]}"
    end

    def matched
      full_code.last
    end

    #################################################################

    def was_send_to
      original_mail.to
    rescue
      nil
    end

    def original_mail
      @original_mail ||= get_original_mail(@mail)
    end

    def method_missing(method_name, *params)
      return type.to_s == $1 if method_name.to_s =~ /is_([a-z]+)\?/
      super
    end

    #################################################################

    private
    def all_bodies
      @mail.body + @mail.parts.map { |m| m.body }.join #&:body doesn't work here
    end

    #################################################################

    def full_code
      @full_code ||=  parse(:code, all_bodies) || parse(:body, all_bodies) || []
    end

    def parse(key, data = nil)
      BounceEmail::Parse.process(key, data || @mail.send(key))
    end

   # def parse_code(data = nil)
   #   BounceEmail::Parse.process(:code, data || @mail.send(key))
   # end

  end

  class Parse

    @@rules = { :subject => {}, :from => {}, :body => {}, :code => {} }
    @@raw_rules = YAML.load_file( File.dirname(__FILE__) + '/data.yml')

    def self.process(key, data)
      rules[key].each do |criteria, error|
        return error << $1 if data =~ /#{criteria}/
      end
      nil
    end

    def self.explain(key, raw_rules = @@raw_rules)
      key = Array(key)
      return raw_rules['desc'] if raw_rules['desc']
      raw_rules = raw_rules[key.shift]
      explain(key, raw_rules)
    rescue #there could accur some errors so best to catch them all
      nil
    end

    private
    def self.build_rules( parent_rule, parent_key = [] )
      parent_rule.each do |key,rule|
        next @@rules[key.to_sym][prepare_rule(rule)] = parent_key if @@rules.keys.include?(key.to_sym)
        next build_rules(rule, parent_key.clone << key ) if rule.is_a?(Hash)
      end
    end

    def self.prepare_rule(rules)
      rules.split("\n").map do |rule|
        "(#{rule.gsub(" ", ".?")})"
      end.join('|')
    end

    def self.rules
      build_rules( @@raw_rules ) if @@rules.values.first.blank?
     @@rules
    end

  end

end


TYPE_HARD_FAIL = 'Permanent Failure'
TYPE_SOFT_FAIL = 'Persistent Transient Failure'
TYPE_SUCCESS   = 'Success'


#       def get_code(mail)
#         code   = get_status_by_parsing(mail.body || mail.parts[1])
#         code ||= get_status_from_text(mail.body)
#         code
#       end
#
#       def get_status_by_parsing(body)
#         codes = || []
#         codes[2]
#       end
#
#       def get_status_from_text(email)
#       end
#
#       def get_reason_from_status_code(code)
#         array = {}
#         #custom codes
#         code = code.gsub(/\./,'')[1..2]
#         array[code] || "unknown"
#       end
#
#       def get_type_from_status_code(code)
#         pre_code = code[0].chr.to_i
#         array = {}
#         array[5] = TYPE_HARD_FAIL
#         array[4] = TYPE_SOFT_FAIL
#         array[2] = TYPE_SUCCESS
#         return array[pre_code]
#         "Error"
#       end
#
#       def check_if_bounce(mail)
#         false
#       end
#
#       def get_original_mail(mail) #worked alright for me, for sure this as to be extended
#         parts = mail.body.gsub("\r", "").split("--- Below this line is a copy of the message.")
#         return TMail::Mail.parse(parts.last) if parts.size > 1
#         begin
#           if mail.parts
#             return TMail::Mail.parse(mail.parts[2].body)
#           end
#         rescue => e
#         end
#         nil
#       end
#