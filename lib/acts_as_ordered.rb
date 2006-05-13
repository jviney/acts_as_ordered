module ActiveRecord
  module Acts
    module Ordered
      def self.included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def acts_as_ordered(options = {})
        options.assert_valid_keys :order, :wrap, :condition, :scope
        
        options[:order]     = options[:order] ? "#{options[:order]}, #{primary_key}" : primary_key
        options[:condition] = options[:condition].to_proc if options[:condition].is_a?(Symbol)
        options[:scope]     = "#{options[:scope]}_id".to_sym if options[:scope].is_a?(Symbol) && options[:scope].to_s !~ /_id$/
        options[:scope]   ||= '1 = 1'
        
        scope_condition_method = if options[:scope].is_a?(Symbol)
          %(
            def ordered_scope_condition
              if #{options[:scope].to_s}.nil?
                "#{options[:scope].to_s} IS NULL"
              else
                "#{options[:scope].to_s} = \#{#{options[:scope].to_s}}"
              end
            end
          )
        else
          "def ordered_scope_condition() \"#{options[:scope]}\" end"
        end
        
        class_eval <<-END
          #{scope_condition_method}
        
          def ordered_ids
            connection.select_values("SELECT #{primary_key} FROM #{table_name} WHERE \#{ordered_scope_condition} ORDER BY #{options[:order]}").collect(&:to_i)
          end
          
          def current_index
            index = ordered_ids.index(self.id)
          end
          
          def adjacent_id(number)
            ids = ordered_ids
            ids.reverse! if number < 0
            index = ids.index(self.id)
            #{options[:wrap] ? 'ids[(index + number.abs) % ids.size]' : 'ids[index + number.abs] || ids.last'}
          end
          
          def first_id
            ordered_ids.first
          end
          
          def last_id
            ordered_ids.last
          end
          
          def first
            self.class.find(first_id)
          end
          
          def last
            self.class.find(last_id)
          end
          
          def first?
            id == first_id
          end
          
          def last?
            id == last_id
          end
        END
        
        class_eval do
          cattr_accessor :_adjacent_condition
          
          def adjacent_record(number)
            record = self
            loop do
              adjacent_record = self.class.find(record.adjacent_id(number))
              matches = self.class._adjacent_condition ? self.class._adjacent_condition.call(adjacent_record) : true
              
              return self if (!matches and ![record, adjacent_record].include?(self)) or adjacent_record == self
              return adjacent_record if matches
              
              record = adjacent_record
              number = 1
            end
          end
          
          def next(number = 1)
            adjacent_record(number)
          end
          
          def previous(number = 1)
            adjacent_record(-number)
          end
        end
        self._adjacent_condition = options[:condition]
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Ordered)
