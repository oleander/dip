# frozen_string_literal: true

require "dip/command"

describe Dip::Command do
  describe Dip::SimpleCommand do
    let(:command) { described_class.new("echo", "Hello World") }

    it "executes the simple command" do
      expect(Dip::Command).to receive(:exec_program).with("echo", "Hello World")
      command.execute
    end
  end

  describe Dip::NestedCommand do
    let(:command) { described_class.new("bundle", { "exec" => "rails db:migrate" }) }

    it "executes the nested command" do
      expect(Dip::Command).to receive(:exec_program).with("bundle exec", "rails db:migrate")
      command.execute
    end

    context "with subcommands" do
      let(:command) { described_class.new("bundle", { "exec" => { "rails" => "db:migrate" } }) }

      it "executes the nested subcommands" do
        expect(Dip::Command).to receive(:exec_program).with("bundle exec rails", "db:migrate")
        command.execute
      end
    end
  end

  describe Dip::SequenceCommand do
    let(:command) { described_class.new(["echo Hello", { "bundle" => "install" }, ["echo World"]]) }

    it "executes the sequence of commands" do
      expect(Dip::Command).to receive(:exec_program).with("echo", "Hello")
      expect(Dip::Command).to receive(:exec_program).with("bundle", "install")
      expect(Dip::Command).to receive(:exec_program).with("echo", "World")
      command.execute
    end
  end
end
