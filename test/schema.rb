ActiveRecord::Schema.define :version => 0 do
  create_table :cartoons, :force => true do |t|
    t.column :first_name, :string
    t.column :last_name,  :string
  end
end
