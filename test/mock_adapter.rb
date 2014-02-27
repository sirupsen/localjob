require 'test_helper'
require 'localjob/mock_adapter'

class MockAdapterTest < LocaljobTestCase
  def setup
    @localjob = queue
    @localjob.queue = Localjob::MockAdapter.new("localjob")
  end

  def test_push_to_queue
    @localjob << "hello world"
    assert_equal 1, @localjob.size
  end

  def test_push_and_pop_from_queue
    @localjob << "hello world"
    assert_equal "hello world", @localjob.shift
  end

  def test_destroy_queue
    @localjob << "hello world"
  end
end
