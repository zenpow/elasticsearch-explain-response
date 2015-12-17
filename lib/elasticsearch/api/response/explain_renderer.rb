require "elasticsearch/api/response/color_helper"

module Elasticsearch
  module API
    module Response
      class ExplainRenderer
        include ColorHelper

        def initialize(options = {})
          disable_colorization if options[:colorize] == false
          @max = options[:max] || 3
          @plain_score = options[:plain_score] == true
          @show_values = options[:show_values] == true
        end

        def render(tree)
          @buffer = []
          recursive_render(tree)
          @buffer.join("\n")
        end

        def render_in_line(tree)
          [render_score(tree.score), "=", recursive_render_details(tree)].flatten.join(" ")
        end

        def recursive_render(node)
          return if node.level > @max
          # binding.pry if node.score > 0.9 && node.score < 1.0
          render_result(node) if node.details.any?
          node.children.each do |child|
            recursive_render(child)
          end
        end

        private

        def render_result(node)
          @buffer << " " * node.level * 2 + [render_score(node.score), "=", render_details(node)].flatten.join(" ")
        end

        def render_score(score)
          value = if !@plain_score && score > 1_000
            sprintf("%1.2g", score.round(2))
          else
            score.round(2).to_s
          end
          ansi(value, :magenta, :bright)
        end

        def render_details(node)
          if node.has_children?
            node.children.map(&method(:render_node)).compact.join(" #{node.operator} ")
          else
            render_node(node)
          end
        end

        def recursive_render_details(node)
          details = node.children.map do |child|
            if child.children.any? && child.level <= @max
              recursive_render_details(child)
            else
              if !child.match_all?
                render_node(child)
              end
            end
          end.compact

          if details.size > 1
            wrap_paren(details.join(" #{node.operator} "))
          else
            details[0]
          end
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
