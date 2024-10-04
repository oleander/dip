# frozen_string_literal: true

require "dip/cli"

describe Dip::CLI do
  describe "#commands" do
    let(:cli) { described_class.new }

    context "when executing a simple command" do
      before do
        allow(Dip::Command).to receive(:exec_program)
        Dip.config.commands[:simple] = Dip::SimpleCommand.new("echo", "Hello World")
      end

      it "executes the simple command" do
        expect(Dip::Command).to receive(:exec_program).with("echo", "Hello World")
        cli.commands("simple")
      end
    end

    context "when executing a nested command" do
      before do
        allow(Dip::Command).to receive(:exec_program)
        Dip.config.commands[:nested] = Dip::NestedCommand.new("bundle", { "exec" => "rails db:migrate" })
      end

      it "executes the nested command" do
        expect(Dip::Command).to receive(:exec_program).with("bundle exec", "rails db:migrate")
        cli.commands("nested")
      end
    end

    context "when executing a sequence of commands" do
      before do
        allow(Dip::Command).to receive(:exec_program)
        Dip.config.commands[:sequence] = Dip::SequenceCommand.new(["echo Hello", { "bundle" => "install" }, ["echo World"]])
      end

      it "executes the sequence of commands" do
        expect(Dip::Command).to receive(:exec_program).with("echo", "Hello")
        expect(Dip::Command).to receive(:exec_program).with("bundle", "install")
        expect(Dip::Command).to receive(:exec_program).with("echo", "World")
        cli.commands("sequence")
      end
    end
  end

  describe ".start" do
    let(:cli) { described_class }

    context "when a command is found in the commands section" do
      before do
        allow(Dip::Command).to receive(:exec_program)
        Dip.config.commands[:simple] = Dip::SimpleCommand.new("echo", "Hello World")
      end

      it "executes the command" do
        expect(Dip::Command).to receive(:exec_program).with("echo", "Hello World")
        cli.start(["simple"])
      end
    end

    context "when a command is not found in the commands section" do
      it "calls the original start method" do
        expect(cli).to receive(:super).with(["unknown"])
        cli.start(["unknown"])
      end
    end
  end
end
