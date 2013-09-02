require 'test_helper'
require 'pry'

class WalrusJob < Struct.new(:action)
  def perform
    "Nice try, but there's no way I'll #{action}.."
  end
end

class AngryWalrusJob < Struct.new(:angryness)
  def perform
    raise "I am this angry: #{angryness}"
  end
end

class LocaljobTest < MiniTest::Unit::TestCase
  def setup
    @localjob = Localjob.new
    @worker = Localjob::Worker.new(@localjob)

    @localjob.logger = Logger.new("/dev/null")
  end

  def teardown
    clear_queue
  end

  def test_push_should_put_a_job_in_queue
    @localjob << WalrusJob.new("move")
    assert_equal 1, @localjob.size
  end

  def test_pop_from_queue
    @localjob << WalrusJob.new("move")

    job = @localjob.shift
    assert_instance_of WalrusJob, job
    assert_equal "move", job.action
  end

  def test_pop_and_send_to_worker
    WalrusJob.any_instance.expects(:perform)

    @localjob << WalrusJob.new("move")

    job = @localjob.shift
    @worker.process(job)
  end

  def test_working_off_queue_in_child
    @localjob << WalrusJob.new("move")

    fork do
      job = @localjob.shift
      @worker.process(job)
    end

    Process.wait
    assert_equal 0, @localjob.size
  end

  def test_sigquit_terminates_the_worker
    @localjob << WalrusJob.new("move")

    assert_equal 1, @localjob.size

    pid = fork { @worker.work }

    Process.kill("QUIT", pid)
    Process.wait

    assert_equal 0, @localjob.size
  end

  def test_doesnt_stop_on_error
    @localjob << AngryWalrusJob.new(100)
    @localjob << WalrusJob.new("be happy")

    pid = fork { @worker.work }

    # Hack to account for race condition, 0.01s should be plenty
    sleep 0.01
    Process.kill("QUIT", pid)
    Process.wait

    assert_equal 0, @localjob.size
  end

  def test_throws_error_if_message_is_too_large
    assert_raises Errno::EMSGSIZE do
      @localjob << AngryWalrusJob.new("f" * @localjob.queue.msgsize)
    end
  end

  def test_handles_multiple_queues
    @localjob << WalrusJob.new("move")

    queue = Localjob.new(queue: "/other-queue")
    queue << WalrusJob.new("dance")

    assert_equal 1, @localjob.size
    assert_equal 1, queue.size

    queue.destroy
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
