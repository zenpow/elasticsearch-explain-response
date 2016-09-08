require "elasticsearch/api/response/helpers/color_helper"

module Elasticsearch
  module API
    module Response
      module Renderers
        class BaseRenderer
          include Helpers::ColorHelper

          def initialize(options = {})
            disable_colorization if options[:colorize] == false
            @max = options[:max] || 3
            @plain_score = options[:plain_score] == true
            @show_values = options[:show_values] == true
          end

          private

            def render_score(score)
              value = if !@plain_score && score > 1_000
                        sprintf("%1.2g", score.round(2))
                      elsif score > 0.1
                        score.round(2).to_s
                      else
                        sprintf("%.3g", score)
                      end
              ansi(value, :magenta, :bright)
            end

            def render_node(node)
              text = render_score(node.score)
              desc = render_description(node.description)
              text = "#{text}(#{desc})" unless desc.empty?
              text
            end

            def render_description(description)
              text = ''
              text = description.operation if description.operation
              if description.field && description.value
                if @show_values
                  text += "(#{field(description.field)}:#{value(description.value)})"
                else
                  text += "(#{field(description.field)})"
                end
              elsif description.field
                text += "(#{field(description.field)})"
              end
              text
            end

            def field(str)
              ansi(str, :blue ,:bright)
            end

            def value(str)
              ansi(str, :green)
            end

            def wrap_paren(string)
              if string.start_with?("(") && string.end_with?(")")
                string
              else
                "(" + string + ")"
              end
            end
        end
      end
    end
  end
end
