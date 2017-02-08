require 'test_helper'

class CassandraObject::AttributeMethods::DirtyTest < CassandraObject::TestCase
  test 'save clears dirty' do
    record = temp_object do
      string :name
      self.schema_type = :schemaless
    end.new name: 'foo'

    assert record.changed?

    record.save!

    assert_equal [nil, 'foo'], record.previous_changes['name']
    assert !record.changed?
  end

  test 'reload clears dirty' do
    record = temp_object do
      string :name
      self.schema_type = :schemaless
    end.create! name: 'foo'

    record.name = 'bar'
    assert record.changed?

    record.reload

    assert !record.changed?
  end

  test 'typecast float before dirty check' do
    record = temp_object do
      float :price
      self.schema_type = :schemaless
    end.create(price: 5.01)

    record.price = '5.01'
    assert !record.changed?

    record.price = '7.12'
    assert record.changed?
  end

  test 'typecast boolean before dirty check' do
    record = temp_object do
      boolean :awesome
      self.schema_type = :schemaless
    end.create(awesome: false)

    record.awesome = false
    assert !record.changed?

    record.awesome = true
    assert record.changed?
  end

  test 'write_attribute' do
    object = temp_object do
      string :name
      self.schema_type = :schemaless
    end

    expected = {"name"=>[nil, "foo"]}

    object.new.tap do |record|
      record.name = 'foo'
      assert_equal expected, record.changes
    end

    object.new.tap do |record|
      record[:name] = 'foo'
      # record.write_attribute(:name, 'foo')
      assert_equal expected, record.changes
    end
  end
end
