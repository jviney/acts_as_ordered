module ActiveRecord
  module Acts
    module Ordered
      def self.included(base)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      def acts_as_ordered(options = {})
        options.assert_valid_keys :order, :wrap, :condition
        
        options[:order]     = options[:order] ? "#{options[:order]}, \#{self.class.primary_key}" : "\#{self.class.primary_key}"
        options[:condition] = options[:condition].to_proc rescue nil
        
        class_eval <<-END
          def adjacent_id(number)
            ids = connection.select_values("select \#{self.class.primary_key} from \#{self.class.table_name} order by #{options[:order]}").map { |id| id.to_i }
            ids.reverse! if number < 0
            index = ids.index(self.id)
            #{options[:wrap] ? 'ids[(index + number.abs) % ids.size]' : 'ids[index + number.abs] || ids.last'}
          end
          
          def next_id(number = 1)
            adjacent_id(number)
          end
          
          def previous_id(number = 1)
            adjacent_id(-number)
          end
        END
        
        if options[:condition]
          class_eval do
            cattr_accessor :_adjacent_condition
            
            def next(number = 1)
              record = self
              loop do
                next_record = self.class.find(record.next_id(number))
                matches = self.class._adjacent_condition.call(next_record)
                
                return self if (!matches and ![record, next_record].include?(self)) or next_record == self
                return next_record if matches
                
                record = next_record
                number = 1
              end
            end
            
            def previous(number = 1)
              record = self
              loop do
                previous_record = self.class.find(record.previous_id(number))
                matches = self.class._adjacent_condition.call(previous_record)
                
                return self if (!matches and ![record, previous_record].include?(self)) or previous_record == self
                return previous_record if matches
                
                record = previous_record
                number = 1
              end
            end
          end
          self._adjacent_condition = options[:condition]
        else
          class_eval do
            def next(number = 1)
              self.class.find(next_id(number))
            end
            
            def previous(number = 1)
              self.class.find(previous_id(number))
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send(:include, ActiveRecord::Acts::Ordered)
