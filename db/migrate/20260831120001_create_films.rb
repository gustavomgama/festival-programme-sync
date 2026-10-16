class CreateFilms < ActiveRecord::Migration[8.1]
  def change
    create_table :films do |t|
      t.string :external_id, null: false
      t.string :title, null: false
      t.text :synopsis
      t.integer :runtime
      t.integer :year

      t.timestamps
    end

    add_index :films, :external_id, unique: true
  end
end
