class AddStateToSales < ActiveRecord::Migration[5.1]
  def change
    add_column :sales, :state, :string
    add_column :sales, :strip_id, :string
    add_column :sales, :stripe_token, :string
    add_column :sales, :error, :text
  end
end
