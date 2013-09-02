require 'test_helper'

class Walrus
  def self.perform(action, options = {})
    "nice try"
  end
end

class AngryWalrus
  def self.perform(action, options = {})
    raise "I am angry"
  end
end

class LocaljobTest < MiniTest::Unit::TestCase
  def setup
    @localjob = Localjob.new

    @localjob.logger = Logger.new("/dev/null")
  end

  def teardown
    clear_queue
  end

  def test_push_should_put_a_job_in_queue
    @localjob.enqueue(Walrus, :move)
    assert_equal 1, @localjob.size
    @localjob.pop
  end

  def test_pop_from_queue
    @localjob.enqueue(Walrus, "move", distance: 100)

    expected = {
      'class' => "Walrus",
      'args' => ['move', { 'distance' => 100 }]
    }

    assert_equal expected, @localjob.pop
  end

  def test_pop_and_send_to_worker
    Walrus.expects(:perform).with("move", "distance" => 100)

    @localjob.enqueue(Walrus, "move", distance: 100)
    job = @localjob.pop

    worker = Localjob::Worker.new(@localjob)
    worker.process(job)
  end

  def test_working_off_queue_in_child
    @localjob.enqueue(Walrus, "move", distance: 100)

    worker = Localjob::Worker.new(@localjob)
    fork { worker.pop_and_process }

    Process.wait
    assert_equal 0, @localjob.size
  end

  def test_sigquit_terminates_the_worker
    @localjob.enqueue(Walrus, "move", distance: 100)
    worker = Localjob::Worker.new(@localjob)

    assert_equal 1, @localjob.size

    pid = fork { worker.work }

    Process.kill("QUIT", pid)
    Process.wait

    assert_equal 0, @localjob.size
  end

  def test_logs_errors_to_stderr
    @localjob.logger.expects(:error).twice
    @localjob.enqueue(AngryWalrus, "be angry", angryness: 100)

    worker = Localjob::Worker.new(@localjob)
    worker.pop_and_process # run just one job
  end

  def test_doesnt_stop_on_error
    @localjob.enqueue(AngryWalrus, "be angry", angryness: 100)
    @localjob.enqueue(Walrus, "be happy", happiness: 100)

    worker = Localjob::Worker.new(@localjob)
    pid = fork { worker.work }

    Process.kill("QUIT", pid)
    Process.wait

    assert_equal 0, @localjob.size
  end

  def test_throws_error_if_message_is_too_large
    assert_raises Errno::EMSGSIZE do
      @localjob.enqueue(AngryWalrus, "f" * @localjob.queue.msgsize)
    end
  end

  private
  def clear_queue
    loop do
      begin
        @localjob.queue.timedreceive
      rescue POSIX::Mqueue::QueueEmpty
        break
      end
    end
  end
end
