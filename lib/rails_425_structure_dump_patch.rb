require "rails_425_structure_dump_patch/version"
require "active_record/tasks/postgresql_database_tasks"

# A monkey-patch to fix https://github.com/rails/rails/pull/22345 in Rails
# 4.2.5.
class ActiveRecord::Tasks::PostgreSQLDatabaseTasks
  def structure_dump(filename)
    set_psql_env

    search_path = case ActiveRecord::Base.dump_schemas
    when :schema_search_path
      configuration['schema_search_path']
    when :all
      nil
    when String
      ActiveRecord::Base.dump_schemas
    end

    args = ['-s', '-x', '-O', '-f', filename]
    unless search_path.blank?
      args += search_path.split(',').map do |part|
        "--schema=#{part.strip}"
      end
    end
    args << configuration['database']
    run_cmd('pg_dump', args, 'dumping')
    File.open(filename, "a") { |f| f << "SET search_path TO #{connection.schema_search_path};\n\n" }
  end
end
