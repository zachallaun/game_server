require 'socket'
require 'thread'
require_relative 'connect_four_sockets'
require_relative 'tic_tac_toe_sockets'

# Server to allow multiple games of Connect Four and TicTacToe
# Currently 2 player only.  Play against computer to be implemented
# run 'connect_four_client.rb' to connect
# need to deal with end of game - play again or disconnect




class Player
  attr_reader :conn, :name, :mark

  def initialize(conn, name, mark)
    @conn = conn
    @name = name
    @mark = mark
  end
end

class Game
  attr_reader :game_board, :name, :active_player, :inactive_player, :inplay

  def initialize(game_type, player1, player2 = nil)
    if game_type == "C"
      @game_board = ConnectFour::Board.new
      @name = "Connect Four"
    else
      @game_board = TicTacToe::Board.new
      @name = "Tic Tac Toe"
    end
    @inplay = !player2.nil?
    if inplay
      if rand(2) == 0
        @active_player = player1
        @inactive_player = player2
      else
        @active_player = player1
        @inactive_player = player2
      end
    else
      @active_player = player1
    end
  end

  def add_player(player2)
    if rand(2) == 0
      @inactive_player = player2
    else
      @inactive_player = @active_player
      @active_player = player2
    end
    @inplay = true
  end

  def convert(mark)
    if @name == "Connect Four"
      mark == 1 ? result = "red" : result = "black"
    else
      mark == 1 ? result =  "X" : result = "O"
    end
    result
  end

  def starting_state
    "#{@active_player.name} will be #{convert(@active_player.mark)} and #{@inactive_player.name} will be #{convert(@inactive_player.mark)}.\n
     #{@active_player.name} will go first"
  end

  def tell_both(string)
    @active_player.conn.puts(string)
    @inactive_player.conn.puts(string)
  end

  def get_move
    @inactive_player.conn.puts("Waiting for #{@active_player.name} to make a move.")
    begin
      @active_player.conn.puts("#{@active_player.name}, it's your turn.  Make a move.")
      @active_player.conn.puts("GET")
      move = @active_player.conn.gets.chomp.to_i
      @active_player.conn.puts("Not a valid move.") if !valid?(move)
    end until valid?(move)
    @game_board.make_move(move,@active_player.mark.to_s)
  end

  def valid?(move)
    @game_board.valid?(move)
  end

  def switch_players
    temp = @active_player
    @active_player = @inactive_player
    @inactive_player = temp
  end

  def display
    @game_board.display
  end

  def game_over?
    @game_board.game_over?
  end

  def endgame
    tell_both("Game Over.")
    if @game_board.draw?
      tell_both("It's a draw.")
    else
      @inactive_player.conn.puts("#{inactive_player.name}, you win!")
      @active_player.conn.puts("Sorry, #{active_player.name}, you lost.")
    end
    @inplay = false
  end
end



class Server

  def initialize(port = 21)
    @control_socket = TCPServer.new(port)
    puts "Server initialized on port #{port}"
    @games = []
    @thread_list = []
    @game_lock = Mutex.new
  end

  def start_new_game(conn, name)
    new_player = Player.new(conn,name,1)

    begin
      conn.puts("Would you like to play Connect Four (C) or TicTacToe (T)? (C/T)")
      conn.puts("GET")
      game_choice = conn.gets.chomp.upcase
    end until game_choice == "C" || game_choice == "T"

    begin
      conn.puts("Do you want to play against the computer (C) or wait for someone to join (W)? (C/W)") #computer options don't exist yet
      conn.puts("GET")
      player_choice = conn.gets.chomp.capitalize
      player_choice = "W" #computer player not yet implemented
    end until player_choice == "C" || player_choice == "W"

    if player_choice == "C"
      #conn.puts("Do you want an easy(1), medium(2), or hard(3) game?")
      #conn.puts("GET")
      #level = conn.gets.chomp.to_i
      new_game = Game.new(game_choice,new_player) #initialize game with computer player, too
      @games << new_game
      game_in_play(new_game)

    else #wait for second player
      new_game = Game.new(game_choice,new_player) #initialize game with computer player, too
      @games << Game.new(game_choice,new_player)
      conn.puts("Please wait for a second player to join")
    end
  end

  def game_in_play(current_game)
    @thread_list << Thread.new do
      current_game.tell_both(current_game.starting_state)
      current_game.tell_both(current_game.display)
      begin
        current_game.get_move
        current_game.tell_both(current_game.display)
        current_game.switch_players
      end until current_game.game_over?
      current_game.endgame
    end
  end


  def select_game(conn, name)
    conn.puts("Your choices are: ")
    choices = @games.find_all {|g| !g.inplay }
    choices.each_with_index do |game, i|
      conn.puts("#{i+1})  #{game.active_player.name} is waiting to play #{game.name}")
    end
    conn.puts("#{choices.size+1}) Play your own game.")
    conn.puts("Choose an option: 1 - #{choices.size+1}")
    conn.puts("GET")
    game_choice = conn.gets.to_i
    if game_choice > choices.size
      start_new_game(conn, name)
    else
      #@game_lock.synchronize do# need to somehow lock the choices, currently 2 people can join the same game -- kicks original player out
      current_game = choices[game_choice-1]
      if current_game.inplay
        conn.puts "Sorry, that game was just taken."
        select_game(conn,name)
      else
        new_player = Player.new(conn,name,2)
        current_game.active_player.conn.puts("#{new_player.name} will be joining you.")
        current_game.add_player(new_player)
      end
      #end # end synchronize / Mutex doesn't work (? because it never gets to end of if/else & unlocks ?)
      game_in_play(current_game)
    end
  end

  def run
    @thread_list << Thread.new do
      Socket.accept_loop(@control_socket) do |conn|
        @thread_list << Thread.new do
          conn.puts("Welcome.")
          conn.puts("What is your name?")
          conn.puts("GET")
          name = conn.gets.chomp.capitalize
          if @games == [] || @games.all? {|g| g.inplay}
            start_new_game(conn,name)
          else
            select_game(conn,name)
          end
        end
      end
    end
    @thread_list.each {|thr| thr.join}
  end #run
end #server class



server = Server.new(4481)
p server
server.run
