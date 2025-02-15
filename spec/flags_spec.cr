require "./spec_helper"

describe "GObject flags" do
  it "can be passed as arguments and returned by value" do
    subject = Test::Subject.new
    ret = subject.return_or_on_flags(:option1, :option2)
    ret.option1?.should eq(true)
    ret.option2?.should eq(true)
    ret.should eq(Test::FlagFlags::All)
    ret.none?.should eq(false)
    ret = subject.return_or_on_flags(:none, :option2)
    ret.should eq(Test::FlagFlags::Option2)
  end

  it "are transformed into enums when they only have the None element" do
    Test::Subject.receive_empty_flags(:none).should eq(Test::EmptyFlags::None)
  end
end
