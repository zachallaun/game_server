require 'colored'

class ConnectFour #should this be module?

  class Board
    attr_reader :turns

    def initialize
      @grid = Array.new(7) { [] }
      @turns = 0
    end

    def display
      display_string= ("+---"*7+"+\n").blue
      5.downto(0) do |h|
        @grid.each do |col|
          display_string << "|".blue
          if col.size < h + 1
            display_string<< "   "
          elsif col[h] == "1"
            display_string<< " @ ".red
          else
            display_string<< " @ ".black
          end
        end
        display_string<< ("|\n"+"+---"*7+"+\n").blue
      end
      display_string<< "  1   2   3   4   5   6   7\n"
    end

    def make_move(move,mark)
      @grid[move-1] << mark
      @last_move = [move-1,mark]
      @turns +=1
    end

    def valid?(move)
      return false if move < 1 || move > 7 || @grid[move-1].size >=6
      true
    end

    def game_over?
      return false if @turns < 7
      col = @last_move.first
      color = @last_move.last
      row = @grid[col].size-1

      col_string = @grid[col].join
      return true if col_string.match(color*4)

      row_string = @grid.inject(""){|memo,c| memo.concat(c[row] || " ")}
      return true if row_string.match(color*4)

      diag1_string = ""
      diag2_string = ""
      (0..5).each do |r|
        col1 = r + (col-row)
        col2 = r + (col + row)
        diag1_string.concat(@grid[col1][r] || " ") if col1 >= 0 && col1 <=6
        diag2_string.concat(@grid[col2][r] || " ") if col2 >= 0 && col2 <=6
      end
      return true if diag1_string.match(color*4) || diag2_string.match(color*4)

      if @turns == 42
        @turns +=1
        return true
      end
      false
    end

    def draw?
      @turns > 42
    end

  end # class Board

end
