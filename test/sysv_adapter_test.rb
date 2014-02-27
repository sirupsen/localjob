require 'test_helper'

class SysvAdapterTest < LocaljobTestCase
  def setup
    @localjob = queue
    @localjob.queue = Localjob::SysvAdapter.new(0xDEADC0DE)
  end

  def teardown
    @localjob.destroy
  end

  def test_send_and_receive
    msg = "Hello World"
    @localjob << msg
    assert_equal msg, @localjob.shift
  end

  def test_size
    @localjob << "Hello World"
    assert_equal 1, @localjob.size
  end
end
