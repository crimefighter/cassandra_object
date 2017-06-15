require 'cassandra_object/scope/finder_methods'
require 'cassandra_object/scope/query_methods'

module CassandraObject
  class Scope
    include FinderMethods, QueryMethods

    attr_accessor :klass
    attr_accessor :is_all, :limit_value, :select_values, :where_values, :id_values, :raw_response, :next_cursor

    def initialize(klass)
      @klass = klass

      @is_all = false
      @limit_value = nil
      @raw_response = nil
      @select_values = []
      @id_values = []
      @where_values = []
      @next_cursor = nil
    end

    private

    def scoping
      previous, klass.current_scope = klass.current_scope, self
      yield
    ensure
      klass.current_scope = previous
    end


    def method_missing(method_name, *args, &block)
      if klass.respond_to?(method_name)
        scoping { klass.send(method_name, *args, &block) }
      elsif Array.method_defined?(method_name)
        to_a.send(method_name, *args, &block)
      else
        super
      end
    end

    def select_records
      results = []
      records = {}
      new_next_cursor = nil

      if self.schema_type == :standard
        klass.adapter.select(self) do |key, attributes|
          records[key] = attributes
        end
      else
        if @is_all
          pre = klass.adapter.pre_select(self, @limit_value, @next_cursor)
          new_next_cursor = pre[:new_next_cursor]
          return {results: [], next_cursor: new_next_cursor} if pre[:ids].empty? # fix last query all if ids is empty
          self.id_values = pre[:ids]
        end

        resp = klass.adapter.select(self)
        primary_key_column = klass.adapter.primary_key_column
        resp.each do |cql_row|
          key = cql_row[primary_key_column]
          records[key] ||= {}
          records[key][cql_row.values[1]] = cql_row.values[2]
        end

      end
      # limit
      records = records.first(@limit_value) if @limit_value.present?
      records.each do |key, attributes|
        if self.raw_response || self.schema_type == :dynamic_attributes
          results << {key => attributes.values.compact.empty? ? attributes.keys : attributes}
        else
          results << klass.instantiate(key, attributes)
        end
      end
      results = results.reduce({}, :merge!) if self.schema_type == :dynamic_attributes
      if @is_all
        return {results: results, next_cursor: new_next_cursor}
      end
      return results
    end

  end
end
