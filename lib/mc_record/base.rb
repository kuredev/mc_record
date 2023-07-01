require "active_support"
require "microcms"
require "date"

module McRecord
  class ContentNotFound < StandardError
  end

  class Base
    extend ActiveSupport::Concern

    # @param [OpenStruct]
    def initialize(attributes)
      @attributes = attributes
    end

    def self.config(service_domain:, api_key:, end_point:)
      MicroCMS.service_domain = service_domain
      MicroCMS.api_key = api_key
      @@end_point = end_point
    end

    # return Array<OpenStruct>
    def self.all
      contents = fetch_contents
      contents.flatten!

      open_structs_to_instances(contents)
    rescue MicroCMS::APIError
      raise ContentNotFound
    end

    # @param [String]
    def self.find(id)
      raise ".find is only support String parameter." unless id.instance_of?(String)

      # OpenStruct
      api_result = MicroCMS.get(
                    @@end_point,
                    id
                  )

      attr_names = api_result.to_h.keys
      attr_names.each do |attr_name|
        define_method_attribute_if_needed(attr_name)
      end

      self.new(api_result)
    rescue MicroCMS::APIError
      raise ContentNotFound
    end

    # @param [Hash]
    def self.where(arg)
      param = build_filter_params(arg)

      raise "param not specified" if param == ""

      contents = fetch_contents(param)
      contents.flatten!

      open_structs_to_instances(contents)
    end

    # @param [Hash]
    def self.where_not(arg)
      param = build_not_filter_params(arg)

      raise "param not specified" if param == ""

      contents = fetch_contents(param)
      contents.flatten!

      open_structs_to_instances(contents)
    end

    class << self
      private

      def define_method_attribute_if_needed(attr_name)
        unless self.method_defined?(attr_name)
          class_eval %Q{
            def #{attr_name}
              read_attribute("#{attr_name}")
            end
          }
        end

        unless self.method_defined?("=#{attr_name}")
          class_eval %Q{
            def #{attr_name}=(value)
              write_attribute("#{attr_name}", value)
            end
          }
        end
      end

      # @param [Hash]
      # @return [String]
      def build_filter_params(arg)
        filters_value = ""
        arg.map do |k, v|
          if v.instance_of?(Range)
            begin_ = v.begin
            end_ = v.end

            result = ""
            unless begin_.nil?
              result += "#{k}[greater_than]#{begin_}"
            end

            unless end_.nil?
              result += unless result == ""
                          "[and]#{k}[less_than]#{end_}"
                        else
                          "#{k}[less_than]#{end_}"
                        end
            end

            result
          else
            "#{k}[equals]#{v}"
          end
        end.join("[and]")
      end

      # @param [Hash]
      # @return [String]
      def build_not_filter_params(arg)
        filters_value = ""
        arg.map do |k, v|
          if v.instance_of?(Range)
            rais "not support parameter"
          else
            "#{k}[not_equals]#{v}"
          end
        end.join("[and]")
      end

      # @param [Array<OpenStruct>]
      # @return [Array<Object>]
      def open_structs_to_instances(contents)
        contents.map do |content|
          attr_names = content.to_h.keys
          attr_names.each do |attr_name|
            define_method_attribute_if_needed(attr_name)
          end

          self.new(content)
        end
      end

      # @return [Array<OpenStruct>]
      def fetch_contents(param = nil)
        contents = []
        limit = 10
        offset_number = 0

        print "fetching contents ."
        loop do
          print "."
          api_result = MicroCMS.list(
                      @@end_point,
                      {
                        offset: offset_number,
                        limit: limit,
                        filters: param,
                      }
                    )

          total_count = api_result.total_count
          contents << api_result.contents

          if total_count >= offset_number + 1
            offset_number += limit
          else
            break
          end
        end

        contents
      end
    end

    private

    def read_attribute(attr_name)
      @attributes.to_h[attr_name.to_sym]
    end

    def write_attribute(attr_name, value)
      @attributes[attr_name] = value
    end
  end
end
