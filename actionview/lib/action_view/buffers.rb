# frozen_string_literal: true

require "active_support/core_ext/string/output_safety"

module ActionView
  class OutputBuffer
    delegate_missing_to :@current_buffer
    delegate :presence, :present?, :html_safe?, to: :@current_buffer

    attr_reader :buffer_stack

    def self.make_frame(*args)
      ActionView::OutputBufferFrame.new(*args)
    end

    def initialize(initial_buffer = nil)
      if initial_buffer.is_a?(self.class)
        @current_buffer = self.class.make_frame(initial_buffer.current)
        @buffer_stack = [*initial_buffer.buffer_stack[0..-2], @current_buffer]
      else
        @current_buffer = initial_buffer || self.class.make_frame
        @buffer_stack = [@current_buffer]
      end
    end

    def replace(buffer)
      return if object_id == buffer.object_id

      @current_buffer = buffer.current
      @buffer_stack = buffer.buffer_stack
    end

    def append=(arg)
      @current_buffer.append = arg
    end

    def safe_append=(arg)
      @current_buffer.safe_append = arg
    end

    def safe_concat(arg)
      # rubocop:disable Rails/OutputSafety
      @current_buffer.safe_concat(arg)
      # rubocop:enable Rails/OutputSafety
    end

    def length
      @current_buffer.length
    end

    def push(buffer = nil)
      buffer ||= self.class.make_frame
      @buffer_stack.push(buffer)
      @current_buffer = buffer
    end

    def pop
      @buffer_stack.pop.tap do
        @current_buffer = @buffer_stack.last
      end
    end

    def to_s
      @current_buffer
    end

    alias_method :current, :to_s

    def ==(other)
      to_s == other
    end
  end

  # Used as a buffer for views
  #
  # The main difference between this and ActiveSupport::SafeBuffer
  # is for the methods `<<` and `safe_expr_append=` the inputs are
  # checked for nil before they are assigned and `to_s` is called on
  # the input. For example:
  #
  #   obuf = ActionView::OutputBuffer.new "hello"
  #   obuf << 5
  #   puts obuf # => "hello5"
  #
  #   sbuf = ActiveSupport::SafeBuffer.new "hello"
  #   sbuf << 5
  #   puts sbuf # => "hello\u0005"
  #
  class OutputBufferFrame < ActiveSupport::SafeBuffer # :nodoc:
    def initialize(*)
      super
      encode!
    end

    def <<(value)
      return self if value.nil?
      super(value.to_s)
    end
    alias :append= :<<

    def safe_expr_append=(val)
      return self if val.nil?
      safe_concat val.to_s
    end

    alias :safe_append= :safe_concat
  end

  class StreamingBuffer # :nodoc:
    def initialize(block)
      @block = block
    end

    def <<(value)
      value = value.to_s
      value = ERB::Util.h(value) unless value.html_safe?
      @block.call(value)
    end
    alias :concat  :<<
    alias :append= :<<

    def safe_concat(value)
      @block.call(value.to_s)
    end
    alias :safe_append= :safe_concat

    def html_safe?
      true
    end

    def html_safe
      self
    end
  end
end
