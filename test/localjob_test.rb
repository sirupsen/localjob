require 'test_helper'

class LocaljobTest < LocaljobTestCase
  def setup
    @localjob = queue
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

  def test_throws_error_if_message_is_too_large
    assert_raises Errno::EMSGSIZE do
      @localjob << AngryWalrusJob.new("f" * @localjob.queue.msgsize)
    end
  end

  def test_handles_multiple_queues
    @localjob << WalrusJob.new("move")

    other = queue("other-queue")
    other << WalrusJob.new("dance")

    assert_equal 1, @localjob.size
    assert_equal 1, other.size
  end
end
