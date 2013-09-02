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
    Localjob.logger = Logger.new("/dev/null")
  end

  def teardown
    loop do
      begin
        Localjob.queue.timedreceive
      rescue POSIX::Mqueue::QueueEmpty
        break
      end
    end
  end

  def test_push_should_put_a_job_in_queue
    Localjob.enqueue(Walrus, :move)
    assert_equal 1, Localjob.size
    Localjob.pop
  end

  def test_pop_from_queue
    Localjob.enqueue(Walrus, "move", distance: 100)

    expected = {
      'class' => "Walrus",
      'args' => ['move', { 'distance' => 100 }]
    }

    assert_equal expected, Localjob.pop
  end

  def test_pop_and_send_to_worker
    Walrus.expects(:perform).with("move", "distance" => 100)

    Localjob.enqueue(Walrus, "move", distance: 100)
    job = Localjob.pop

    worker = Localjob::Worker.new
    worker.process(job)
  end

  def test_working_off_queue_in_child
    Localjob.enqueue(Walrus, "move", distance: 100)

    worker = Localjob::Worker.new
    fork { worker.pop_and_process }

    Process.wait
    assert_equal 0, Localjob.size
  end

  def test_sigquit_terminates_the_worker
    Localjob.enqueue(Walrus, "move", distance: 100)
    worker = Localjob::Worker.new

    assert_equal 1, Localjob.size

    pid = fork { worker.work }

    Process.kill("QUIT", pid)
    Process.wait

    assert_equal 0, Localjob.size
  end

  def test_logs_errors_to_stderr
    Localjob.logger.expects(:error).twice
    Localjob.enqueue(AngryWalrus, "be angry", angryness: 100)

    worker = Localjob::Worker.new
    worker.pop_and_process # run just one job
  end

  def test_doesnt_stop_on_error
    Localjob.enqueue(AngryWalrus, "be angry", angryness: 100)
    Localjob.enqueue(Walrus, "be happy", happiness: 100)

    worker = Localjob::Worker.new
    pid = fork { worker.work }

    Process.kill("QUIT", pid)
    Process.wait

    assert_equal 0, Localjob.size
  end

  def test_throws_error_if_message_is_too_large
    assert_raises Errno::EMSGSIZE do
      Localjob.enqueue(AngryWalrus, "f" * Localjob.queue.msgsize)
    end
  end
end
