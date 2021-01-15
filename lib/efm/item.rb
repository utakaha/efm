require 'curses'

module Efm
  class Item
    def self.all
      Dir
        .glob('*')
        .map { |name| new(name: name, dir: Dir.exist?(name)) }
        .partition(&:dir?)
        .flat_map { |items| items.sort_by(&:name) }
    end

    def initialize(name:, dir: false)
      @name = name
      @width = Curses.cols
      @dir = dir
      @color = dir ? Curses.color_pair(Curses::COLOR_GREEN) : Curses.color_pair(Curses::COLOR_WHITE)
    end

    attr_reader :name, :width, :color

    def dir?
      @dir
    end
  end
end
