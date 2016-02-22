require "has_reindexable_associations/version"
require 'rails/all'
require 'searchkick'

# To avoid full model reindex, one can't just call reindex on a scope.
# One must call reindex_async on each associated record.
# Usage:
# MyClass < ActiveRecord::Base
# include HasReindexableAssociations
# belongs_to :some_association
# has_many :some_associations
# has_reindexable_associations :some_association, :some_associations
module HasReindexableAssociations
  extend ActiveSupport::Concern

  class_methods do
    cattr_writer :reindexable_associations

    # Set this to `true` before any seeds or imports to reindex associations later on your own like this:
    # MyClass.reindexable_associations_skip = true
    # MyClass.import(...)
    # MyClass.reindex
    # MyClass.reindexable_associations_skip = false
    # MyClass.reindexable_associations.each { |association| MyClass.send(association).model.reindex }
    cattr_accessor :reindexable_associations_skip

    def has_reindexable_associations(*args)
      # @@ is shared between classes via concern, not what we want
      # @@reindexable_associations = args
      self.class_variable_set :@@reindexable_associations, args
    end

    def reindexable_associations
      # @@reindexable_associations || []
      self.class_variable_get :@@reindexable_associations
    rescue NameError
      []
    end
  end

  included do
    after_commit :reindex_associations

    private

    def reindex_associations
      self.class.reindexable_associations.each do |reindexable_association|
        reindex_associations_process(reindexable_association)
      end
    end

    def reindex_associations_process(reindexable_association)
      record_or_records = reindex_associations_scope(reindexable_association)
      if record_or_records.respond_to?(:to_a)
        reindex_associations_process_records(record_or_records, reindexable_association)
      else
        reindex_associations_process_record(record_or_records, reindexable_association)
      end
    end

    def reindex_associations_scope(reindexable_association)
      begin
        record_or_records = self.send(reindexable_association)
      rescue NoMethodError
        fail NoMethodError.new("foreign key '#{reindexable_association}' is not defined, verify has_reindexable_associations options")
      end
    end

    def reindex_associations_process_records(records, reindexable_association)
      unless self.class.reindexable_associations_skip
        records.to_a.each do |record|
          reindex_associations_process_record(record, reindexable_association)
        end
      end
    end

    def reindex_associations_process_record(record, reindexable_association)
      reindex_association(record)
      reindex_associations_process_old_record(reindexable_association)
    end

    def reindex_association(record)
      record.reindex_async
    end

    def reindex_associations_find_old_polymorphic_association(reindexable_association)
      key, type = reindex_associations_describe_polymorphic_association(reindexable_association)
      old_klass = reindex_associations_describe_old_polymorphic_association(key, type)
      return unless old_klass && previous_changes[key] && previous_changes[key].first
      old_record = old_klass.where(id: previous_changes[key].first).first
    end

    def reindex_associations_process_old_record(reindexable_association)
      old_record = reindex_associations_find_old_polymorphic_association(reindexable_association)
      reindex_association(old_record) if old_record
    end

    def reindex_associations_describe_polymorphic_association(reindexable_association)
      key = self.class.reflect_on_association(reindexable_association).try(:foreign_key)
      type = self.class.reflect_on_association(reindexable_association).try(:foreign_type)
      [key, type]
    end

    def reindex_associations_describe_old_polymorphic_association(key, type)
      if (previous_changes[key] && previous_changes[key].first) || (previous_changes[type] && previous_changes[type].first)
        old_klass = previous_changes[type].first rescue NameError
        old_klass = self.send(type).constantize if old_klass == NameError
      end
    rescue NameError
    end
  end
end

