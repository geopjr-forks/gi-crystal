require "./spec_helper"

class SubjectChildStore
  getter subject

  def initialize
    @subject = Test::SubjectChild.new_constructor("hello")
  end
end

describe "GObject Binding" do
  describe "reference counting" do
    it "accessible by ref_count method" do
      subject = Test::Subject.new(boolean: true)
      subject.ref_count.should eq(1)
      iface = subject.return_myself_as_interface
      iface.to_unsafe.should eq(subject.to_unsafe)
      subject.ref_count.should eq(2)
    end

    it "increase object reference when passing it to a transfer full method" do
      subject = Test::Subject.new(boolean: true)
      subject.ref_count.should eq(1)
      Test::Subject.transfer_full_param(subject)
      subject.ref_count.should eq(2)
    end

    it "hold a reference even on transfer none constructors" do
      subject = Test::Subject.new
      subject.ref_count.should eq(2)
    end
  end

  describe "binding configuration" do
    describe "method removal" do
      it "removes GLib.g_get_environ" do
        GLib.responds_to?(:host_name).should eq(false)
      end
    end
  end

  describe "constructors" do
    it "generate alternative constructors" do
      subject = Test::Subject.new_from_string("hello")
      subject.string.should eq("hello")
    end

    it "generate renamed constructors" do
      subject = Test::SubjectChild.new("hello")
      subject.class.should eq(Test::SubjectChild)
      subject.string.should eq("hello")
    end

    it "returns the right type instead of any base type" do
      store = SubjectChildStore.new
      typeof(store.subject).should eq(Test::SubjectChild)
      store.subject.string.should eq("hello")
    end

    it "may return nil" do
      subject = Test::SubjectChild.new_constructor_returning_null("hello")
      typeof(subject).should eq(Test::SubjectChild | Nil)
      subject.should eq(nil)
    end
  end

  describe "casts" do
    it "can downcast objects" do
      child = Test::SubjectChild.new(string: "hey")
      gobj = child.me_as_gobject
      gobj.ref_count.should eq(2)
      gobj.class.should eq(GObject::Object)
      cast = Test::Subject.cast(gobj)
      cast.ref_count.should eq(3)
      cast.string.should eq("hey")
    end

    it "thrown an exception on bad casts" do
      expect_raises(TypeCastError) { Test::SubjectChild.cast(Test::Subject.new) }
    end

    it "return new on bad casts using cast?" do
      Test::SubjectChild.cast?(Test::Subject.new).should eq(nil)
    end
  end

  describe "getters" do
    it "bind get_foo as foo if foo has no params" do
      subject = Test::Subject.new
      subject.getter_without_args.should eq("some string")
    end

    it "removes out params" do
      subject = Test::Subject.new
      ret = subject.out_param
      ret.in.should eq(1)
      ret.begin.should eq(2)
    end
  end

  describe "setters" do
    subject = Test::Subject.new
    subject.setter = "hello man!"
    subject.string.should eq("hello man!")
  end

  describe "enums" do
    it "works" do
      Test::RegularEnum::Value1.to_i.should eq(0)
      Test::RegularEnum::Value2.to_i.should eq(1)
      Test::RegularEnum::Value3.to_i.should eq(2)
    end
  end

  describe "GList" do
    it "works on transfer full" do
      subject = Test::Subject.new
      list = subject.return_list_of_strings_transfer_full
      list.size.should eq(2)
      list.first?.should eq("one")
      list.last?.should eq("two")
      list[0].should eq("one")
      list[1].should eq("two")
    end

    it "works on transfer none" do
      subject = Test::Subject.new
      list = subject.return_list_of_strings_transfer_container
      list.size.should eq(2)
      list.first?.should eq("one")
      list.last?.should eq("two")
    end

    it "can be converted to an array" do
      subject = Test::Subject.new
      list = subject.return_list_of_strings_transfer_container
      list.to_a.should eq(%w(one two))
    end

    it "has .each method" do
      subject = Test::Subject.new
      list = subject.return_list_of_strings_transfer_container
      res = [] of String
      list.each { |s| res << s }
      res.should eq(%w(one two))
    end
  end

  describe "GSList" do
    it "works on transfer full" do
      subject = Test::Subject.new
      list = subject.return_slist_of_strings_transfer_full
      list.size.should eq(2)
      list[0].should eq("one")
      list[1].should eq("two")
    end

    it "works on transfer none" do
      subject = Test::Subject.new
      list = subject.return_slist_of_strings_transfer_container
      list.size.should eq(2)
      list[0].should eq("one")
      list[1].should eq("two")
    end

    it "can be converted to an array" do
      subject = Test::Subject.new
      list = subject.return_slist_of_strings_transfer_container
      list.to_a.should eq(%w(one two))
    end

    it "has .each method" do
      subject = Test::Subject.new
      list = subject.return_list_of_strings_transfer_container
      res = [] of String
      list.each { |s| res << s }
      res.should eq(%w(one two))
    end
  end

  describe "constants" do
    it "can have a value annotation" do
      Test::CONSTANT_WITH_VALUE_ANNOTATION.should eq(100)
    end

    it "works" do
      Test::CONSTANT.should eq(123)
    end
  end

  describe "nullable parameters" do
    it "can receive nil" do
      subject = Test::Subject.new
      subject.receive_nullable_object(nil).should eq(1)
    end

    it "can receive nil" do
      subject = Test::Subject.new
      subject.receive_nullable_object(subject).should eq(0)
    end
  end

  describe "return values" do
    it "can be nullable" do
      subject = Test::Subject.new
      subject.may_return_null(true).should eq(nil)
      subject.may_return_null(false).not_nil!.to_unsafe.should eq(subject.to_unsafe)
    end
  end

  describe "optional parameters" do
    it "are removed" do
      Test::Subject.no_optional_param.should eq(0)
    end
  end

  describe "parameters named using Crystal keywords" do
    it "works on gobject parameters" do
      subject = Test::Subject.new
      subject.receive_arguments_named_as_crystal_keywords(1, 2, 3, 4, 5, 6, 7, 8, 9).should eq(45)
    end

    it "works on plain structs" do
      subject = Test::Struct.new(begin: 42)
      subject.begin.should eq(42)
    end
  end
end
