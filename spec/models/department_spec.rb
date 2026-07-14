require 'rails_helper'

RSpec.describe Department, type: :model do
  it "has a valid factory" do
    expect(build(:department)).to be_valid
  end

  let(:department) { build(:department) }

  it { expect(department).to validate_presence_of(:name) }
  it { expect(department).to have_many(:specializations) }

  it "orders by name ascending by default" do
    dept_b = create(:department, name: 'Bravo')
    dept_a = create(:department, name: 'Alpha')
    expect(Department.all.first).to eq(dept_a)
    expect(Department.all.last).to eq(dept_b)
  end

  it "nullifies dependent specializations' department_id on destroy" do
    department = create(:department)
    specialization = create(:specialization, department: department)
    department.destroy
    expect(specialization.reload.department_id).to be_nil
  end
end
