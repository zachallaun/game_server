require 'colored'

class ConnectFour #should this be module?

  class Board
    attr_reader :turns

    def initialize
      @grid = Array.new(7) { [] }
      @turns = 0
    end

    def row(i)
      @grid.map { |col| col[i] }
    end

    def rows
      5.downto(0).map { |i| row(i) }
    end

    def col(i)
      @grid[i]
    end

    def cols
      @grid
    end

    def cell(col_i, row_i)
      column = col(col_i)
      column && column[row_i]
    end

    def diagonals_from(col_i, row_i)
      diag_left  = []
      diag_right = []

      (0..5).each do |row_offset|
        col1_i = (col_i + row_i) - row_offset
        col2_i = (col_i - row_i) + row_offset
        diag_left.push  cell(col1_i, row_offset) if col1_i >= 0 && col1_i <= 6
        diag_right.push cell(col2_i, row_offset) if col2_i >= 0 && col2_i <= 6
      end

      [diag_left, diag_right]
    end

    def display_row(row)
      s = row.map do |cell|
        if cell.nil?
          "   "
        elsif cell == "1"
          " @ ".red
        else
          " @ ".black
        end
      end
      "|".blue + s.join("|".blue) + "|".blue
    end

    def display
      row_sep = ("+---"*7+"+").blue
      rows_string = rows.map { |r| display_row(r) + "\n" }.join(row_sep + "\n")
      legend = "  1   2   3   4   5   6   7"
      row_sep + "\n" + rows_string + row_sep + "\n" + legend + "\n"
    end

    def make_move(move,mark)
      @grid[move-1] << mark
      @last_move = [move-1,mark]
      @turns +=1
    end

    def valid?(move)
      !(move < 1 || move > 7 || @grid[move-1].size >= 6)
    end

    def game_over?
      col_i, color = @last_move
      last_col = col(col_i)

      row_i = last_col.size - 1
      last_row = row(row_i)

      diag_left, diag_right = diagonals_from(col_i, row_i)

      [last_col, last_row, diag_left, diag_right].each do |line|
        return true if nils_to_spaces(line).join.match(color * 4)
      end

      if @turns == 42
        @turns +=1 and return true
      end
      false
    end

    def draw?
      @turns > 42
    end

    private

    def nils_to_spaces(arr)
      arr.map { |elem| elem || " " }
    end

  end # class Board

end
