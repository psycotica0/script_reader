require "awesome_print"
require_relative "parser"

p = Parser.new(STDIN.read)
ap p.chunks
