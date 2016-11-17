class CreateJobs < ActiveRecord::Migration[5.0]
  def change
    create_table :jobs do |t|
      t.references :pipeline,   foreign_key: true, null: false, index: true
      t.string :pipeline_stage, index: true
      t.string :key,            null: false, index: true
      t.string :status,         null: false, default: 'QUEUED'
      t.string :commit
      t.string :branch
      t.string :worker
      t.text :spec

      t.timestamps
    end
    change_column :jobs, :id, 'SERIAL'
  end
end
