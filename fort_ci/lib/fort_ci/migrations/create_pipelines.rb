class CreatePipelines < ActiveRecord::Migration[5.0]
  def change
    create_table :pipelines do |t|
      t.references :project, foreign_key: true, null: true
      t.string :definition
      t.text :variables
      t.string :stage
      t.string :status
      t.text :error
      t.text :event

      t.timestamps
    end
    change_column :jobs, :id, 'SERIAL'
  end
end
