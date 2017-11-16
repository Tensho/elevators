# WorkerPool
# https://hspazio.github.io/2017/worker-pool

require 'celluloid'

class Elevator
  include Celluloid

  attr_accessor :current_floor

  def initialize(id, floor)
    @id = id
    @current_floor = floor
    @busy = false
  end

  def delta(floor)
    (current_floor - floor).abs
  end

  # NOTE: Process #go exclusively, which means actor's mailbox will not fetch new message until the current one completes
  exclusive

  def go(floor)
    puts "-- Elevator #{@id} from #{@current_floor} to #{floor} --"
    enum = if @current_floor > floor
      @current_floor.downto(floor)
    else
      @current_floor.upto(floor)
    end

    enum.each do |floor|
      puts "#{@id}: #{floor}\n"
      sleep(1)
    end

    @current_floor = floor
  end
end

class Building
  include Celluloid

  def initialize(*elevators)
    @elevators = elevators
  end

  def give(floor)
    closest_elevator =  @elevators.min_by do |elevator|
      elevator.delta(floor)
    end

    closest_elevator.go(floor)
  end
end

e1 = Elevator.new(1, 1)
e2 = Elevator.new(2, 20)

############################
# t  # Thread 1 # Thread 2 #
#    #          #          #
#    #    e1    #    e2    #
############################
# 1  #    1          20    #
# 2  #    2          19    #
# 3  #    3          18    #
# 4  #    4          17    #
# 5  #    5          16    #
# 6  #    6          15    #
# 7  #    7                #
# 8  #    8                #
# 9  #    9                #
# 10 #    10               #
############################

b = Building.new(e1, e2)
# NOTE: Run all calls asynchronously to mimic simultaniouse elevators call from the different floors
b.async.give(3)
b.async.give(10)
b.async.give(15)

