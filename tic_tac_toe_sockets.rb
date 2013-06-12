class TicTacToe # should this be a module?

  class Board
    attr_reader :turns

    def initialize()
      @grid = [[1,2,3],[4,5,6],[7,8,9]]
      @turns = 0
    end

    def display
      display_string = ""
      @grid.each do |row|
        display_string << "+---"*3+"+\n|"
        row.each do |cell|
          display_string << " #{cell} |"
        end
        display_string << "\n"
      end
      display_string << "+---"*3+"+\n"
    end

    def make_move(move,mark)
      row = ((move/3.0).ceil)-1  # ensures floating point division
      row = -1 if row == 2
      col = (move % 3) - 1
      mark == "1" ? sign = "X" : sign = "O"
      @grid[row][col] = sign
      @last_move = [row, col, sign]
      @turns +=1
    end

    def valid?(move)
      return false if move < 1 || move > 9
      row = ((move/3.0).ceil)-1
      col = (move % 3) - 1
      return false unless @grid[row][col].is_a?(Integer)
      true
    end

    def game_over?
      return false if @turns < 5
      row = @last_move[0]
      col = @last_move[1]
      mark = @last_move[2]

      row_string = @grid[row].join
      return true if row_string.match(mark*3)

      col_string = @grid.inject(""){|memo,r| memo.concat(r[col])}
      return true if col_string.match(mark*3)

      return true if (row == col) && (mark == @grid[row+1][col+1]) && (mark == @grid[row-1][col-1]) #check diag down to right
      return true if ((row == 1 && col ==1) || (row + col == -1)) && (mark == @grid[row-1][col+1]) && (mark == @grid[row+1][col-1]) #check diag up to right

      if @turns == 9
        @turns +=1
        return true
      end
      false
    end

    def draw?
      @turns > 9
    end
  end #class Board

end
