require 'curses'
require_relative 'item'

module Efm
  class Manager
    FIRST_LINE = 0

    def self.init_screen
      Curses.init_screen
      Curses.noecho
      Curses.curs_set(0)
      Curses.start_color
      [Curses::COLOR_GREEN, Curses::COLOR_WHITE].each do |c|
        Curses.init_pair c, c, Curses::COLOR_BLACK
      end

      new
    end

    def initialize
      @header = Curses::Window.new(1, Curses.cols, 0, 0)
      @main = Curses::Window.new(Curses.lines - 2, Curses.cols, 1, 0)
      @footer = Curses::Window.new(1, Curses.cols, Curses.lines - 1, 0)
    end

    def run
      init_position
      cd('.')
      ls
      update_header
      display_footer

      begin
        loop do
          case c = @main.getch
          when Curses::KEY_CTRL_N
            down
          when Curses::KEY_CTRL_P
            up
          when Curses::KEY_CTRL_H, Curses::KEY_CTRL_B, 127
            left
            ls
          when Curses::KEY_CTRL_A
            cd
            ls
          when Curses::KEY_CTRL_F, 10, 13
            if @current_item.dir?
              cd(@current_item.name)
            else
              open
            end
            ls
          when 'q'
            break
          end

          update_header
        end
      ensure
        Curses.close_screen
      end
    end

    private

    def update_header
      @header.setpos(0, 0)
      @header.clrtoeol
      @header.attron(Curses.color_pair(Curses::COLOR_GREEN) | Curses::A_NORMAL) do
        @header.addstr(File.expand_path(@current_item.name))
      end
      @header.refresh
    end

    def display_footer
      @footer.setpos(0, 0)
      @footer.attron(Curses.color_pair(Curses::COLOR_WHITE) | Curses::A_NORMAL) do
        @footer.addstr('up: C-p, down: C-n, forward: C-f, backward: C-b')
      end
      @footer.refresh
    end

    def clear_screen
      @main.clear
    end

    def init_position
      @x = 0
      @y = 0

      @main.setpos(@y, @x)
    end

    def up
      if @y <= FIRST_LINE && 0 == @page
        @page = @items.count / (maxy + 1)
        ls
        init_prev_item
        @y = (@items.count - 1) % maxy
      elsif @y <= FIRST_LINE && 0 < @page
        @page = @page - 1
        ls
        init_prev_item
        @y = maxy - 1
      else
        init_prev_item
        @y = @y - 1
      end

      @current_item = @display_items[@y]
      @main.setpos(@y, @x)
      decorate_current_item
    end

    def down
      if @y >= @last_line && @page != @last_page
        @page = @page + 1
        ls
      elsif @y >= @last_line && @page == @last_page
        @page = 0
        ls
      else
        init_prev_item
        @y = @y + 1
      end

      @current_item = @display_items[@y]
      @main.setpos(@y, @x)
      decorate_current_item
    end

    def left
      cd('..')
    end

    def open
      editor = ENV['EDITOR'] || 'vi'
      system "#{editor} #{@current_item.name}"
    end

    def init_prev_item
      @main.setpos(@y, @x)
      display_line(@current_item)
    end

    def decorate_current_item
      @main.clrtoeol
      @main.attron(@current_item.color | Curses::A_STANDOUT) do
        @main.addstr(@current_item.name)
      end
    end

    def display_line(item)
      @main.attron(item.color | Curses::A_NORMAL) do
        @main.addstr(item.name)
      end
    end

    def maxy
      @main.maxy
    end

    def cd(dir = nil)
      dir ? Dir.chdir(dir) : Dir.chdir
      @items = Item.all
      @page = 0
      @last_page = @items.count / maxy
    end

    def ls
      clear_screen
      init_position

      @display_items = @items[@page * maxy, maxy]
      @current_item = @display_items.first

      @display_items.each do |item|
        @main.setpos(@y, @x)
        display_line(item)
        @y = @y + 1
      end

      init_position
      decorate_current_item
      @main.refresh

      @last_line = @display_items.count - 1
    end
  end
end
