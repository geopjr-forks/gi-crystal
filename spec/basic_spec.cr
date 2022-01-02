require "./spec_helper"

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
      subject.string.should eq("hello")
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

  describe "flags" do
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
  end

  describe "structs" do
    it "can be returned by transfer full (boxed structs)" do
      boxed = Test::BoxedStruct.return_boxed_struct("hell yeah!")
      boxed.data.should eq("hell yeah!")
    end

    it "are always copyed, even on transfer none" do
      boxed = Test::BoxedStruct.return_boxed_struct("boxed")

      ret = boxed.return_transfer_none
      ret.data.should eq("boxed")
      ret.to_unsafe.should_not eq(boxed.to_unsafe)
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

  describe "raw C arrays" do
    it "works with nil" do
      subject = Test::Subject.new
      subject.concat_strings(nil).should eq("")
    end

    it "can be received in arguments as Array" do
      subject = Test::Subject.new
      subject.concat_strings(%w(lets go)).should eq("letsgo")
    end

    it "can be received in arguments as Tuple" do
      subject = Test::Subject.new
      subject.concat_strings({"hey", "ho"}).should eq("heyho")
    end

    it "can be zero-terminated and returned as value" do
      subject = Test::Subject.new
      subject.return_null_terminated_array_transfer_none.should eq(%w(Hello World))
      subject.return_null_terminated_array_transfer_full.should eq(%w(Hello World))
    end

    describe "of filenames" do
      it "can be received in arguments as Array(String)" do
        Test::Subject.new.concat_filenames(%w(lets go)).should eq(Path.new("letsgo"))
      end

      it "have a overload using a tuple" do
        Test::Subject.new.concat_filenames("hey", "ho", "lets", "go").should eq(Path.new("heyholetsgo"))
      end

      it "can be received in arguments as Tuple(String)" do
        Test::Subject.new.concat_filenames({"hey", "ho"}).should eq(Path.new("heyho"))
      end

      pending "can be received as argument as Array(Path)"
      pending "can be received as argument as Tuple(Path)"
    end

    describe "of primitive types" do
      it "works" do
        subject = Test::Subject.new
        subject.sum(1, 2, 3).should eq(6)
        subject.sum({1, 2, 3}).should eq(6)
        subject.sum([1, 2, 3]).should eq(6)
      end

      it "can be nullable" do
        subject = Test::Subject.new
        subject.sum_nullable(nil).should eq(0)
        subject.sum_nullable(1, 2, 3).should eq(6)
        subject.sum_nullable({1, 2, 3}).should eq(6)
        subject.sum_nullable([1, 2, 3]).should eq(6)
      end
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
