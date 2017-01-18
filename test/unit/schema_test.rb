require 'test_helper'

class CassandraObject::SchemaTest < CassandraObject::TestCase

  test 'create_keyspace' do
    CassandraObject::Schema.create_keyspace 'Blah'
    begin
      existing_keyspace = false
      CassandraObject::Schema.create_keyspace 'Blah'
    rescue Exception => e
      assert_equal e.message, 'Cannot add existing keyspace "blah"'
      existing_keyspace = true
    ensure
      CassandraObject::Schema.drop_keyspace 'Blah'
    end

    assert existing_keyspace
  end

  test 'create_table' do
    CassandraObject::Schema.create_table 'TestRecords', 'compression_parameters:sstable_compression' => 'SnappyCompressor'

    begin
      CassandraObject::Schema.create_table 'TestRecords'
      assert false, 'TestRecords should already exist'
    rescue Exception => e
      assert_equal e.message, 'Cannot add already existing column family "testrecords" to keyspace "cassandra_object_test"'
    end
  end

  test 'drop_table' do
    CassandraObject::Schema.create_table 'TestCFToDrop'

    CassandraObject::Schema.drop_table 'TestCFToDrop'

    begin
      CassandraObject::Schema.drop_table 'TestCFToDrop'
      assert false, 'TestCFToDrop should not exist'
    rescue Exception => e
      assert_equal e.message, 'unconfigured columnfamily testcftodrop'
    end
  end

  test 'create_index' do
    CassandraObject::Schema.create_column_family 'TestIndexed'

    CassandraObject::Schema.alter_column_family 'TestIndexed', 'ADD id_value varchar'

    CassandraObject::Schema.add_index 'TestIndexed', 'id_value'
  end

  test 'drop_index' do
    CassandraObject::Schema.create_column_family 'TestDropIndexes'

    CassandraObject::Schema.alter_column_family 'TestDropIndexes', 'ADD id_value1 varchar'
    CassandraObject::Schema.alter_column_family 'TestDropIndexes', 'ADD id_value2 varchar'

    CassandraObject::Schema.add_index 'TestDropIndexes', 'id_value1'
    CassandraObject::Schema.add_index 'TestDropIndexes', 'id_value2', 'special_name'

    CassandraObject::Schema.drop_index 'TestDropIndexes_id_value1_idx'
    CassandraObject::Schema.drop_index 'special_name'
  end

end
