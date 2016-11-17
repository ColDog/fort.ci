class CreateProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :projects do |t|
      t.string :name
      t.string :repo_provider
      t.string :repo_owner
      t.string :repo_name
      t.string :repo_id
      t.text :enabled_pipelines

      t.boolean :enabled

      t.timestamps
    end
  end
end
