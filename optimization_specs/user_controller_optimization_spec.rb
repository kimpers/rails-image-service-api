require 'rails_helper'
require 'assert-performance'

RSpec.describe UsersController, type: :request do
  it 'should profile memory for users' do
    class UsersController
      # Alias index method if this is the first time we're monkey patching
      if !self.method_defined?(:old_index)
        puts "Aliasing index"
        alias_method :old_index, :index
      end

      def index
        GC.enable_stats
        RubyProf.measure_mode = RubyProf::MEMORY
        RubyProf.start
        # Call the real index method to profile it
        self.old_index
        profiling_result = RubyProf.stop
        printer = RubyProf::CallTreePrinter.new(profiling_result)
        printer.print(File.open(Rails.root + 'benchmark/users_memory_profile.out.app', 'w+'))
      end
    end

    # Get users to obtain profile data
    get "/users", {offset: 0}, authorization: @token
    expect(response.status).to be 200
  end

  it 'should profile cpu for users' do
    class UsersController
      # Alias index method if this is the first time we're monkey patching
      if !self.method_defined?(:old_index)
        puts "Aliasing index"
        alias_method :old_index, :index
      end

      def index
        GC.disable
        RubyProf.measure_mode = RubyProf::CPU_TIME
        RubyProf.start
        # Call the real index method to profile it
        self.old_index
        profiling_result = RubyProf.stop
        GC.enable
        printer = RubyProf::CallTreePrinter.new(profiling_result)
        printer.print(File.open(Rails.root + 'benchmark/users_cpu_profile.out.app', 'w+'))
      end
    end

    # Get users to obtain profile data
    get "/users", {offset: 0}, authorization: @token
    expect(response.status).to be 200
  end

  it 'should benchmark performance for users' do
    pending
  end
end
