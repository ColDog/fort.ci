class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :provider,     null: false
      t.string :provider_id,  null: false, index: true
      t.string :email
      t.string :username
      t.string :token
      t.string :refresh_token

      t.timestamps
    end
  end
end
