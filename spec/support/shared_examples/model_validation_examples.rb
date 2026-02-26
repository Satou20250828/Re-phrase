RSpec.shared_examples "validates presence of attribute" do |factory_name, attribute, trait = :invalid|
  it "is invalid when #{attribute} is blank" do
    record = build(factory_name, trait)
    expect(record).to be_invalid
  end

  it "adds blank error for #{attribute}" do
    record = build(factory_name, trait)
    record.validate
    expect(record.errors[attribute]).to include("can't be blank")
  end
end

RSpec.shared_examples "validates max length of attribute" do |factory_name, attribute, trait = :too_long|
  it "is invalid when #{attribute} exceeds max length" do
    record = build(factory_name, trait)
    expect(record).to be_invalid
  end

  it "adds max length error for #{attribute}" do
    record = build(factory_name, trait)
    record.validate
    expect(record.errors[attribute]).to include("is too long (maximum is 300 characters)")
  end
end
