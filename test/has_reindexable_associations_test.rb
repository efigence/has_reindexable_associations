require 'test_helper'

class HasReindexableAssociationsTest < ActiveSupport::TestCase

  class HasReindexableAssociation < ActiveRecord::Base
    include HasReindexableAssociations
    belongs_to :belongs_to_association
    has_many :has_many_associations
    belongs_to :polymorphable, polymorphic: true
    searchkick
  end

  class BelongsToAssociation < ActiveRecord::Base
    include HasReindexableAssociations
    has_many :has_reindexable_associations
    searchkick
  end

  class HasManyAssociation < ActiveRecord::Base
    include HasReindexableAssociations
    belongs_to :has_reindexable_association
    searchkick
  end

  class BelongsToPolymorphicAssociation < ActiveRecord::Base
    include HasReindexableAssociations
    has_many :has_reindexable_associations, as: :polymorphable, dependent: :destroy
    searchkick
  end

  setup do
    connection_info = YAML.load_file("config/database.yml")["test"]
    ActiveRecord::Base.establish_connection(connection_info)

    ActiveRecord::Schema.define do
      self.verbose = false

      create_table :belongs_to_associations, :force => true do |t|
        t.string :text
      end

      create_table :belongs_to_polymorphic_associations, :force => true do |t|
        t.string :text
      end

      create_table :has_reindexable_associations, :force => true do |t|
        t.string :text
        t.belongs_to :belongs_to_association, null: false
        t.references :polymorphable, :polymorphic => true, null: false
        #low-cardinality index is rails quirk
        #t.references :polymorphable, :polymorphic => true, null: false, index: {name: 'idx_hra_on_pat_and_pbtpai'}
      end
      add_index :has_reindexable_associations, [:polymorphable_id, :polymorphable_type], name: :idx_hra_on_pai_and_pat
      #low-cardinality index is rails quirk
      #add_reference :has_reindexable_associations, :belongs_to_polymorphic_association, null: false, index: true, polymorphic: true, name: 'idx_hra_on_pat_andbtpai'

      add_index :has_reindexable_associations, :belongs_to_association_id, :name => 'index_hra_on_btai'
      add_foreign_key :has_reindexable_associations, :belongs_to_associations, name: :fk_hra_bta_i

      create_table :has_many_associations, :force => true do |t|
        t.string :text
        t.belongs_to :has_reindexable_association, null: false
      end

      add_index :has_many_associations, :has_reindexable_association_id
      add_foreign_key :has_many_associations, :has_reindexable_associations, name: :fk_hma_hrai_hra_i
    end

    @belongs_to_association = HasReindexableAssociationsTest::BelongsToAssociation.create
    @subject = HasReindexableAssociationsTest::HasReindexableAssociation.new
    @subject.belongs_to_association = @belongs_to_association
    belongs_to_polymorphable_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.create
    @subject.polymorphable = belongs_to_polymorphable_association
    @subject.save
    HasReindexableAssociationsTest::HasManyAssociation.create(has_reindexable_association_id: @subject.id)
  end

  def test_that_it_has_a_version_number
    refute_nil ::HasReindexableAssociations::VERSION
  end

  def test_has_reindexable_associations
    HasReindexableAssociationsTest::HasReindexableAssociation.has_reindexable_associations
    subject = HasReindexableAssociationsTest::HasReindexableAssociation.new
    args = [:belongs_to_association, :polymorphable, :has_many_associations]
    subject.class.has_reindexable_associations(*args)
    assert_equal args, subject.class.class_variable_get(:@@reindexable_associations)
  end

  def test_reindexable_associations
    HasReindexableAssociationsTest::HasReindexableAssociation.has_reindexable_associations

    subject = HasReindexableAssociationsTest::HasReindexableAssociation.new
    assert_instance_of Array, subject.class.reindexable_associations
    assert_empty subject.class.reindexable_associations
    subject.class.has_reindexable_associations :belongs_to_association, :polymorphable, :has_many_associations
    assert_equal [:belongs_to_association, :polymorphable, :has_many_associations], subject.class.reindexable_associations
  end

  def test_reindex_associations
    HasReindexableAssociationsTest::HasReindexableAssociation.has_reindexable_associations
    assert_empty @subject.class.reindexable_associations

    mock = MiniTest::Mock.new
    returned_value = []
    arguments_array = []
    mock.expect(:call, returned_value, arguments_array)
    @subject.class.stub(:reindexable_associations, mock) do
      result = @subject.send(:reindex_associations)
      assert_instance_of Array, result
      assert_empty result
    end
    mock.verify

    mock = MiniTest::Mock.new
    returned_value = [:belongs_to_association]
    arguments_array = []
    mock.expect(:call, returned_value, arguments_array)
    @subject.class.stub(:reindexable_associations, mock) do
      assert_not_empty @subject.send(:reindex_associations)
    end
    mock.verify
  end

  def test_reindex_associations_process
    mock = MiniTest::Mock.new
    returned_value = [:has_many_associations]
    arguments_array = [@subject.has_many_associations, returned_value.first]
    mock.expect(:call, returned_value, arguments_array)
    @subject.stub(:reindex_associations_process_records, mock) do
      @subject.send(:reindex_associations_process, returned_value.first)
    end
    mock.verify

    @subject.belongs_to_association = @belongs_to_association
    @subject.save

    mock = MiniTest::Mock.new
    returned_value = [:belongs_to_association]
    arguments_array = [@subject.belongs_to_association, returned_value.first]
    mock.expect(:call, returned_value, arguments_array)
    @subject.stub(:reindex_associations_process_record, mock) do
      @subject.send(:reindex_associations_process, returned_value.first)
    end
    mock.verify
  end

  def test_reindex_associations_scope
    @subject.belongs_to_association = @belongs_to_association
    @subject.save

    record_or_records  = @subject.belongs_to_association

    assert_raises NoMethodError do
      @subject.stub(:belongs_to_association, Proc.new { raise NoMethodError }) do
        result = @subject.send(:reindex_associations_scope, :belongs_to_association)
      end
    end

    result = @subject.send(:reindex_associations_scope, :belongs_to_association)
    assert_equal record_or_records, result
  end

  def test_reindex_associations_process_records
    records = @subject.has_many_associations
    reindexable_association = :has_many_associations

    @subject.class.reindexable_associations_skip = true
    assert_nil @subject.send(:reindex_associations_process_records, records, reindexable_association)

    @subject.class.reindexable_associations_skip = nil

    mock = MiniTest::Mock.new
    returned_value = nil
    arguments_array = [records.first, reindexable_association]
    mock.expect(:call, returned_value, arguments_array)
    @subject.stub(:reindex_associations_process_record, mock) do
      assert_equal [records.first], @subject.send(:reindex_associations_process_records, records, reindexable_association)
    end
    mock.verify
  end

  def test_reindex_associations_process_record
    records = @subject.has_many_associations
    reindexable_association = :has_many_associations

    mock = MiniTest::Mock.new
    returned_value = nil
    arguments_array = [records.first]
    mock.expect(:call, returned_value, arguments_array)
    @subject.stub(:reindex_association, mock) do
      @subject.send(:reindex_associations_process_record, records.first, reindexable_association)
    end
    mock.verify

    mock = MiniTest::Mock.new
    returned_value = nil
    arguments_array = [reindexable_association]
    mock.expect(:call, returned_value, arguments_array)
    @subject.stub(:reindex_associations_process_old_record, mock) do
      @subject.send(:reindex_associations_process_record, records.first, reindexable_association)
    end
    mock.verify
  end

  def test_reindex_association
    record = @subject.belongs_to_association
    reindexable_association = :belongs_to_association

    mock = MiniTest::Mock.new
    returned_value = nil
    arguments_array = []
    mock.expect(:call, returned_value, arguments_array)
    record.stub(:reindex_async, mock) do
      @subject.send(:reindex_association, record)
    end
    mock.verify
  end

  def test_reindex_associations_find_old_polymorphic_association
    reindexable_association = :belongs_to_association

    @subject.belongs_to_association = nil
    assert_nil @subject.send(:reindex_associations_find_old_polymorphic_association, reindexable_association)

    new_record = HasReindexableAssociationsTest::BelongsToAssociation.create
    @subject.belongs_to_association = new_record
    @subject.save
    assert_nil @subject.send(:reindex_associations_find_old_polymorphic_association, reindexable_association)
  end

  def test_reindex_associations_find_old_polymorphic_association_2
    record = @subject.polymorphable
    reindexable_association = :polymorphable

    assert_not_empty record.has_reindexable_associations

    new_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.new

    belongs_to_association = HasReindexableAssociationsTest::BelongsToAssociation.create
    subject = HasReindexableAssociationsTest::HasReindexableAssociation.new
    subject.belongs_to_association = belongs_to_association
    belongs_to_polymorphable_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.create
    subject.polymorphable = belongs_to_polymorphable_association
    subject.save

    new_association.has_reindexable_associations << subject

    assert_nil subject.send(:reindex_associations_find_old_polymorphic_association, reindexable_association).try(:polymorphable_id)

    new_association.save

    assert_nil subject.send(:reindex_associations_find_old_polymorphic_association, reindexable_association).try(:polymorphable_id)

    belongs_to_polymorphable_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.create
    subject.polymorphable = belongs_to_polymorphable_association
    subject.save
    assert_not_equal new_association.id, subject.send(:reindex_associations_find_old_polymorphic_association, reindexable_association).try(:polymorphable_id)
  end

  def test_reindex_associations_process_old_record
    reindexable_association = :belongs_to_association

    new_record = HasReindexableAssociationsTest::BelongsToAssociation.create
    @subject.belongs_to_association = new_record
    @subject.save

    record = @subject.belongs_to_association
    reindexable_association = :belongs_to_association

    mock = MiniTest::Mock.new
    returned_value = record
    arguments_array = [reindexable_association]
    mock.expect(:call, returned_value, arguments_array)

    mock2 = MiniTest::Mock.new
    returned_value = 'job was enqueued'
    arguments_array = [record]
    mock2.expect(:call, returned_value, arguments_array)

    @subject.stub(:reindex_associations_find_old_polymorphic_association, mock) do
      @subject.stub(:reindex_association, mock2) do
        assert_equal 'job was enqueued', @subject.send(:reindex_associations_process_old_record, reindexable_association)
      end
    end
    mock.verify
    mock2.verify
  end

  def test_reindex_associations_describe_polymorphic_association
    reindexable_association = :polymorphable
    key, type = ['polymorphable_id', 'polymorphable_type']
    assert_equal [key, type], @subject.send(:reindex_associations_describe_polymorphic_association, reindexable_association)
  end

  def test_reindex_associations_describe_old_polymorphic_association
    belongs_to_association = HasReindexableAssociationsTest::BelongsToAssociation.create
    subject = HasReindexableAssociationsTest::HasReindexableAssociation.new
    subject.belongs_to_association = belongs_to_association
    belongs_to_polymorphable_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.create
    subject.polymorphable = belongs_to_polymorphable_association
    subject.save!

    key, type = ['polymorphable_id', 'polymorphable_type']

    assert_nil subject.send(:reindex_associations_describe_old_polymorphic_association, key, type)
    assert_nil subject.send(:reindex_associations_describe_old_polymorphic_association, key, :non_existing_type)

    belongs_to_polymorphable_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.create
    subject.polymorphable = belongs_to_polymorphable_association
    subject.save!

    belongs_to_polymorphable_association = HasReindexableAssociationsTest::BelongsToPolymorphicAssociation.create
    subject.polymorphable = belongs_to_polymorphable_association

    assert_equal subject.polymorphable.class, subject.send(:reindex_associations_describe_old_polymorphic_association, key, type)
  end
end
