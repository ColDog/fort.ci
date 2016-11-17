class AddReferencesToProjects < ActiveRecord::Migration[5.0]
  def change
    add_reference :projects, :team, foreign_key: true, null: true
    add_reference :projects, :user, foreign_key: true, null: true
  end
end
