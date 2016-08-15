class AddJobTagToPrismeJobs < ActiveRecord::Migration
  def change
    add_column :prisme_jobs, :job_tag, :string, null: true # this column indicates the main grouping of linked jobs as a search string
    add_index(:prisme_jobs, :job_tag )
    add_index(:prisme_jobs, [ :job_name, :job_tag ])

    PrismeJob.where('job_name LIKE ?', '%Jenkins%').update_all(job_tag: PrismeConstants::JobTags::TERMINOLOGY_CONVERTER)
  end
end
