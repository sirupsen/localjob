require 'test_helper'

class WorkerTest < LocaljobTestCase
  def setup
    @localjob = queue
    @worker   = worker(@localjob)
  end

  def teardown
    @localjob.destroy
  end

  def test_pop_and_send_to_worker
    WalrusJob.any_instance.expects(:perform)

    @localjob << WalrusJob.new("move")

    job = @localjob.shift
    @worker.process(job)
  end

  def test_working_off_queue_in_child
    @localjob << WalrusJob.new("move")

    a = Thread.start {
      job = @localjob.shift
      @worker.process(job)
    }

    a.join

    assert_equal 0, @localjob.size
  end


  def test_doesnt_stop_on_error
    @localjob << AngryWalrusJob.new(100)
    @localjob << WalrusJob.new("be happy")

    @worker.work(thread: true)

    sleep 0.1
    @worker.kill

    assert_equal 0, @localjob.size
  end

  def test_worker_doesnt_die_on_bad_serialization
    @localjob << "--- !ruby/object:Whatever {}\n"

    @worker.work(thread: true)
    sleep 0.1
    @worker.kill
  end

  def test_sigquit_terminates_the_worker
    @localjob << WalrusJob.new("move")

    assert_equal 1, @localjob.size

    pid = fork { @worker.work }
    sleep 0.1

    Process.kill("QUIT", pid)
    sleep 0.1

    assert_equal 0, @localjob.size
  end

  def test_sigint_terminates_the_worker
    @localjob << WalrusJob.new("move")

    pid = fork { @worker.work }
    sleep 0.1

    Process.kill("INT", pid)
    sleep 0.1

    assert_equal 0, @localjob.size
  end

  def test_thread_worker
    @localjob << WalrusJob.new("move")

    assert_equal 1, @localjob.size

    @worker.work(thread: true)
    sleep 0.1
    @worker.kill

    assert_equal 0, @localjob.size
  end

  def test_kill_terminates_forked_worker
    @localjob << WalrusJob.new("move")

    assert_equal 1, @localjob.size

    fork { @worker.work }
    # Can do this immediately after, since it pushes a termination message to
    # the queue.
    @worker.kill
    sleep 0.1

    assert_equal 0, @localjob.size
  end

  def test_sending_termination_message_calls_shutdown!
    @localjob << Localjob::Worker::TERMINATION_MESSAGE
    @worker.expects(:exit!)
    @worker.work
  end
end
