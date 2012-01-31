module Devise
  module Orm
    module CouchrestModel
      module Schema
        include Devise::Schema
        # Tell how to apply schema methods.
        def apply_devise_schema(name, type, options={})
          return unless Devise.apply_schema
          property name, type, options
        end

        def find_for_authentication(conditions)
          conditions = filter_auth_params(conditions.dup)
          (case_insensitive_keys || []).each { |k| conditions[k].try(:downcase!) }
          (strip_whitespace_keys || []).each { |k| conditions[k].try(:strip!) }
          find(:conditions => conditions)
        end

        def find(*args)
          options = args.extract_options!

          if options.present?
            raise "You can't search with more than one condition yet =(" if options[:conditions].keys.size > 1
            find_by_key_and_value(options[:conditions].keys.first, options[:conditions].values.first)
          else
            id = args.flatten.compact.uniq.join
            find_by_key_and_value(:id, id)
          end
        end

        protected

        # Force keys to be string to avoid injection on mongoid related database.
        def filter_auth_params(conditions)
          conditions.each do |k, v|
            conditions[k] = v.to_s if auth_param_requires_string_conversion?(v)
          end if conditions.is_a?(Hash)
        end
        
        # Determine which values should be transformed to string or passed as-is to the query builder underneath
        def auth_param_requires_string_conversion?(value)
          true unless value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(Fixnum)
        end

        private
        
        def find_by_key_and_value(key, value)
          if key == :id
            get(value)
          else
            send("by_#{key}", {:key => value, :limit => 1}).first
          end
        end
      end
    end
  end
end
