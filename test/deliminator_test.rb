require File.expand_path('../test_helper', __FILE__)

# Deliminator.class_eval { instance_methods.each { |m| public(m) } }

class DeliminatorTest < Test::Unit::TestCase
  include Deliminator

  def setup
    $curwin = Mocks::Window.new
    @prev_char = @next_char = nil
  end

  # cursor row is zero-based, but column is one-based
  def move_to(*cursor)
    $curwin.cursor = cursor
  end

  # CLOSE?

  test "closes an opening parenthesis: preceded by word-char, followed by nothing" do
    # happens all the time when typing at the end of the line
    buffer << 'abc'
    move_to 1, 3
    assert_equal '', next_char
    assert close?('(')
  end

  test "closes an opening parenthesis: preceded by word-char, followed by word-char" do
    # maybe this is not right ...
    buffer << 'abcdef'
    move_to 1, 3
    assert_equal 'd', next_char
    assert close?('(')
  end

  test "closes an opening parenthesis: preceded by word-char, followed by closing parenthesis" do
    # as in: Array(Foo.new|) wanting to add arguments to new()
    buffer << 'abc)'
    move_to 1, 3
    assert_equal ')', next_char
    assert close?('(')
  end

  test "closes an opening parenthesis: preceded by opening parenthesis, followed by closing parenthesis" do
    # when would we type this? maybe for something like ((a || b) (c || d))
    buffer << 'ab()'
    move_to 1, 3
    assert_equal ')', next_char
    assert close?('(')
  end

  test "closes an opening quote" do
    # typing a " at: foo("bar", |, "baz") results in: foo("bar", "|", "baz")
    buffer << 'foo("bar", , "baz")'
    move_to 1, 11
    assert_equal ',', next_char
    assert close?('"')
  end

  test "does not close a closing quote" do
    # typing a " at: foo("bar|, "baz") results in: foo("bar"|, "baz")
    buffer << 'foo("bar, "baz")'
    move_to 1, 8
    assert_equal ',', next_char
    assert !close?('"')
  end

  # STEP_OVER?

  test "typing ( steps over a succeeding (" do
    # not sure where this is useful
    buffer << 'abc('
    move_to 1, 3
    assert_equal '(', next_char
    assert !step_over?('(')
  end

  test "typing ) steps over a succeeding )" do
    # typing " at: abc|) results in: abc")
    buffer << 'abc)'
    move_to 1, 3
    assert_equal ')', next_char
    assert step_over?(')')
  end

  test 'typing " steps over a succeeding "' do
    # typing " at: abc|" results in: abc"|
    buffer << 'abc"'
    move_to 1, 3
    assert_equal '"', next_char
    assert step_over?('"')
  end

  # DELETE_NEXT?

  test 'backspacing a ( removes a succeeding ) as well' do
    # typing <bs> at: abc(|) results in: abc
    buffer << 'abc()'
    move_to 1, 4
    assert_equal '(', prev_char
    assert delete_next?
  end

  test 'backspacing a space removes a succeeding space as well when inside a blank parenthesis pair' do
    # typing <bs> at: abc( | ) results in: abc(||)
    buffer << 'abc(  )'
    move_to 1, 5
    assert_equal ' ', prev_char
    assert delete_next?
  end

  test 'backspacing a " removes a succeeding " as well' do
    # typing <bs> at: abc "|" results in: abc |
    buffer << 'abc ""'
    move_to 1, 5
    assert_equal '"', prev_char
    assert delete_next?
  end

  test 'backspacing a space removes a succeeding space as well when inside a blank quotes pair' do
    # typing <bs> at: abc " | " results in: abc "|"
    buffer << 'abc "  "'
    move_to 1, 6
    assert_equal ' ', prev_char
    assert_equal ' ', next_char
    assert delete_next?
  end

  test 'backspacing a space bug' do
    # typing <bs> at: " |" results in: abc "| ... which is wrong
    buffer << '" "'
    move_to 1, 2
    assert_equal ' ', prev_char
    assert_equal '"', next_char
    assert delete_next?
  end

  # BALANCE_SPACE?

  test 'typing a space inside an empty pair of brackets inserts another space after the cursor' do
    # typing <space> at: abc(|) results in: abc( | )
    buffer << 'abc()'
    move_to 1, 4
    assert_equal '(', prev_char
    assert balance_space?
  end

  # HELPERS

  test 'prev_char' do
    buffer << '()'
    move_to 1, 1
    assert_equal '(', prev_char
  end

  test 'prev_char skipping whitespace' do
    buffer << '(  )'
    move_to 1, 3
    assert_equal '(', prev_char(:ignore_space =>true)
  end

  test 'next_char' do
    buffer << '()'
    move_to 1, 1
    assert_equal ')', next_char
  end

  test 'next_char skipping whitespace' do
    buffer << '(  )'
    move_to 1, 1
    assert_equal ')', next_char(:ignore_space =>true)
  end

  test 'content_before' do
    buffer[1] = 'abcdef'
    buffer[2] = 'ghijkl'
    move_to 2, 3
    assert_equal "abcdef\nghi", content_before
  end

  test 'content_before w/ a single line' do
    buffer[1] = 'abcdef'
    move_to 1, 3
    assert_equal "abc", content_before
  end

  test 'content_after' do
    buffer[1] = 'abcdef'
    buffer[2] = 'ghijkl'
    move_to 1, 3
    assert_equal "def\nghijkl", content_after
  end

  test 'content_after w/ a single line' do
    buffer[1] = 'abcdef'
    move_to 1, 3
    assert_equal "def", content_after
  end
end
