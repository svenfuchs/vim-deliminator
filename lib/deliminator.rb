class String; alias blank? empty? end
class Object; alias blank? nil? end

module Vim
  def let(name, value)
    Vim.command("let #{name} = #{value.inspect}")
  end
end

module Deliminator
  class << self
    def vim_action(*names)
      names.each do |name|
        method = self.instance_method(name)
        define_method(name) do |*args|
          Vim.let('l:result', method.bind(self).call(*args))
        end
      end
    end
  end

  BRACKETS   = { '(' => ')', '[' => ']', '{' => '}' } # , '<' => '>', '|' => '|'
  QUOTES     = { '"' => '"', "'" => "'", '`' => '`' }
  DELIMITERS = BRACKETS.merge(QUOTES)

  def setup
    DELIMITERS.to_a.flatten.uniq.each { |char| map_delimiter(char) }
    map_space
    map_backspace
  end

  # MAIN ACTIONS

  def delimiter(char)
    if step_over?(char)
      '<Right>'
    elsif opening?(char) && auto_close?(char)
      [char, closing_pair(char), '<Left>'].join
    else
      char
    end
  end

  def space
    balance_space? ? '  <Left>' : ' '
  end

  def backspace
    delete_next? ? '<BS><Del>' : '<BS>'
  end

  vim_action :delimiter, :space, :backspace

  protected

    # MAIN CONDITIONS

    # do we need to step over the next char instead of inserting the given char?
    def step_over?(char)
      char == next_char && !backslash?(prev_char) && closing?(char)
    end

    # do we need to auto-close the given char?
    def auto_close?(char)
      quote?(char)   && auto_close_quote?(char) ||
      bracket?(char) && auto_close_bracket?(char)
    end

    # do we need to auto-close the given quote?
    def auto_close_quote?(char)
      # balanced?(content_before, char) && balanced?(content_after, char)
      !word_char?(prev_char) && !quote?(prev_char) && prev_char != '\\'
    end

    # do we need to close the given bracket?
    def auto_close_bracket?(char)
      true
    end

    # do we need to balance the space that was just typed?
    def balance_space?
      inside_empty_brackets?
    end

    # do we need to delete the next char? (after typing a <BS>)
    def delete_next?
      inside_blank_pair?
    end

    # SECONDARY CONDITIONS

    # is the given char balanced the buffer's content?
    def balanced?(content, char)
      content.count(char) % 2 == 0
    end

    # is the given char a bracket?
    def bracket?(char)
      BRACKETS.keys.include?(char) || BRACKETS.values.include?(char)
    end

    # is the given char a quote?
    def quote?(char)
      QUOTES.keys.include?(char)
    end

    # is the given char an opening character?
    def opening?(char)
      DELIMITERS.keys.include?(char)
    end

    # is the given char a closing character?
    def closing?(char)
      DELIMITERS.values.include?(char)
    end

    # is the given char a word character?
    def word_char?(char)
      char =~ /\w+/
    end

    # is the given char a backslash?
    def backslash?(char)
      char == '\\'
    end

    # is the cursor positioned inside empty brackets? (disregarding any whitespace)
    def inside_empty_brackets?
      bracket?(prev_char) && bracket?(next_char) && inside_blank_pair?
    end

    # is the cursor positioned inside an empty pair? (disregarding any whitespace)
    def inside_blank_pair?
      closing_pair(prev_char(:skip_space => true)) == next_char(:skip_space => true)
    end

    # HELPERS

    # returns the closing pair of the given opening char
    def closing_pair(char)
      DELIMITERS[char]
    end

    # returns the previous character (based on the current cursor position)
    def prev_char(options = {})
      ix = column - 1
      ix = skip_space(ix, :left) if options[:skip_space]
      char_at(ix) || ''
    end

    # returns the next character (based on the current cursor position)
    def next_char(options = {})
      ix = column
      ix = skip_space(ix, :right) if options[:skip_space]
      char_at(ix) || ''
    end

    # skips over whitespace in the current line, starting the given cursor x position,
    # in the given direction (:left or :right)
    def skip_space(ix, direction)
      diff = { :left => -1, :right => 1 }[direction]
      ix += diff until ix < 1 || char_at(ix) =~ /[^ \t]/ || char_at(ix).blank?
      ix
    end

    # returns the buffer's content before the current cursor position
    def content_before
      content = lines[0, line_number - 1] || []
      content << line_before
      content.compact.join("\n")
    end

    # returns the buffer's content after the current cursor position
    def content_after
      content = [line_after]
      content += lines[line_number..-1] || []
      content.compact.join("\n")
    end

    # returns the current line's content before the current cursor position
    def line_before
      line[0..column - 1].to_s
    end

    # returns the current line's content after the current cursor position
    def line_after
      line[column..-1].to_s
    end

    # returns the character at the given column, in the current line
    def char_at(column)
      line[column, 1]
    end

    # returns the lines in the current buffer
    def lines
      (1..buffer.length.to_i - 1).map { |ix| buffer[ix.to_i] }.flatten
    end

    # returns the current line
    def line
      buffer[line_number]
    end

    # returns the current line number
    def line_number
      $curwin.cursor.first
    end

    # returns the current column
    def column
      $curwin.cursor.last
    end

    # returns the current buffer
    def buffer
      $curwin.buffer
    end

    # maps typing a delimiter in input mode to Deliminator#delimiter
    def map_delimiter(char)
      char = "\\#{char}" if char == '|'
      Vim.command("imap #{char} <C-R>=DeliminatorDelimiter(#{char.inspect})<CR>")
    end

    # maps typing space in input mode to Deliminator#space
    def map_space
      Vim.command('imap <Space> <C-R>=DeliminatorSpace()<CR>')
    end

    # maps typing backspace in input mode to Deliminator#backspace
    def map_backspace
      Vim.command('imap <BS> <C-R>=DeliminatorBackspace()<CR>')
    end

    extend self
end
