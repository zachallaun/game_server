require 'socket'

#need to deal with end of game

class Client

  def initialize(host,port) # defaults??
    @connection = TCPSocket.new(host,port)
  end

  def run
    loop do
      message = @connection.gets.chomp
  
      if message == "GET"
        move = gets.chomp
        @connection.puts(move)
      else
        puts message
      end
      end
      
  end


end

client = Client.new('localhost', 4481)

client.run

