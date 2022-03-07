# frozen_string_literal: true

module ActionView
  # = Action View Context
  #
  # Action View contexts are supplied to Action Controller to render a template.
  # The default Action View context is ActionView::Base.
  #
  # In order to work with Action Controller, a Context must just include this
  # module. The initialization of the variables used by the context
  # (@output_buffer, @view_flow, and @virtual_path) is responsibility of the
  # object that includes this module (although you can call _prepare_context
  # defined below).
  module Context
    attr_accessor :view_flow
    attr_reader :output_buffer

    # Prepares the context by setting the appropriate instance variables.
    def _prepare_context
      @view_flow     = OutputFlow.new
      @output_buffer = nil
      @virtual_path  = nil
    end

    # Encapsulates the interaction with the view flow so it
    # returns the correct buffer on +yield+. This is usually
    # overwritten by helpers to add more behavior.
    def _layout_for(name = nil)
      name ||= :layout
      view_flow.get(name).html_safe
    end

    def output_buffer=(other_buffer)
      if @output_buffer
        @output_buffer.replace(other_buffer)
      else
        @output_buffer = other_buffer
      end
    end
  end
end
