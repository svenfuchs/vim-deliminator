require File.expand_path('../test_helper', __FILE__)

class DeliminatorTest < Test::Unit::TestCase
  def setup
    $curwin = Mocks::Window.new
    $curwin.buffer[1] = 'abc (def'
    $curwin.buffer[2] = 'ghi(jkl)'
    $curwin.buffer[3] = 'mno) pqr'
    $curwin.cursor = [2, 4]
  end

  test "line" do
    assert_equal 'ghi(jkl)', Deliminator.send(:line)
  end

  test 'prev_char' do
    assert_equal '(', Deliminator.send(:prev_char)
  end

  test 'next_char' do
    assert_equal 'j', Deliminator.send(:next_char)
  end

  test 'content_before' do
    assert_equal "abc (defghi", Deliminator.send(:content_before)
  end

  test 'content_after' do
    assert_equal "(jkl)mno) pqr", Deliminator.send(:content_after)
  end
end
