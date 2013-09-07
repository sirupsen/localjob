require 'test_helper'

class WorkerTest < LocaljobTestCase
  def setup
    @localjob = queue
    @worker   = worker
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

    a = Thread.start { @worker.work }

    # Hack to account for race condition, 0.01s should be plenty
    sleep 0.01
    a.kill

    assert_equal 0, @localjob.size
  end

  def test_worker_doesnt_die_on_bad_serialization
    @localjob.queue.send "--- !ruby/object:Whatever {}\n"

    a = Thread.start { @worker.work }

    sleep 0.01
    a.kill
  end

  on_platform 'linux' do
    def test_sigquit_terminates_the_worker
      @localjob << WalrusJob.new("move")

      assert_equal 1, @localjob.size

      pid = fork { @worker.work }

      # Hack to account for race condition, 0.01s should be plenty
      sleep 0.1

      Process.kill("QUIT", pid)
      Process.wait

      assert_equal 0, @localjob.size
    end

    def test_workers_listen_on_multiple_queues
      @localjob << WalrusJob.new("move")

      other = queue("other-queue")
      other << WalrusJob.new("dance")

      @worker.channel << 'other-queue'

      a = Thread.start { @worker.work }

      sleep 0.01
      a.kill

      assert_equal 0, @localjob.size
      assert_equal 0, other.size
    end
  end
end
