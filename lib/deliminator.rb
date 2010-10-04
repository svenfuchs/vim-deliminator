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

  BRACKETS   = { '(' => ')', '[' => ']', '{' => '}' } # , '<' => '>'
  QUOTES     = { '"' => '"', "'" => "'", '`' => '`', '|' => '|' }
  DELIMITERS = BRACKETS.merge(QUOTES)

  def setup
    DELIMITERS.to_a.flatten.uniq.each { |char| map_delimiter(char) }
    map_space
    map_backspace
  end

  def delimiter(char)
    if opening?(char) && close?(char)
      [char, closing_pair(char), '<Left>'].join
    elsif step_over?(char)
      '<Right>'
    else
      char
    end
  end

  def space
    inside_empty_brackets? ? '  <Left>' : ' '
  end

  def backspace
    delete_next? ? '<BS><Del>' : '<BS>'
  end

  vim_action :delimiter, :space, :backspace

  protected

    def close?(char)
      quote?(char) && close_quote?(char) || bracket?(char) && close_bracket?(char)
    end

    def close_quote?(char)
      !word?(prev_char) && !quote?(next_char)
    end

    def close_bracket?(char)
      true
    end

    def step_over?(char)
      char == next_char and closing?(char)
    end

    def delete_next?
      inside_blank_pair?
    end

    def bracket?(char)
      BRACKETS.keys.include?(char)
    end

    def quote?(char)
      QUOTES.keys.include?(char)
    end

    def opening?(char)
      DELIMITERS.keys.include?(char)
    end

    def closing?(char)
      DELIMITERS.values.include?(char)
    end

    def word?(char)
      char =~ /\w+/
    end

    def inside_empty_brackets?
      bracket?(prev_char) && bracket?(next_char) && inside_empty_pair?
    end

    def inside_blank_pair?
      closing_pair(prev_char(:ignore_space => true)) == next_char(:ignore_space => true)
    end

    def closing_pair(char)
      DELIMITERS[char]
    end

    def prev_char(options = {})
      ix = column - 1
      ix = skip_space(ix, :left) if options[:ignore_space]
      char_at(ix)
    end

    def next_char(options = {})
      ix = column
      ix = skip_space(ix, :right) if options[:ignore_space]
      char_at(ix)
    end

    def skip_space(ix, direction)
      diff = { :left => -1, :right => 1 }[direction]
      ix += diff until char_at(ix) =~ /[^ \t]/ || char_at(ix).empty?
      ix
    end

    def content_before
      content = lines[0..line_number - 2]
      content << line_before
      content.compact.join("\n")
    end

    def content_after
      content = [line_after]
      content += lines[line_number..-1]
      content.compact.join("\n")
    end

    def line_before
      line[0..column - 1].to_s
    end

    def line_after
      line[column..-1].to_s
    end

    def char_at(column)
      line[column, 1]
    end

    def lines
      (1..buffer.length.to_i - 1).map { |ix| buffer[ix.to_i] }.flatten
    end

    def line
      buffer[line_number]
    end

    def line_number
      $curwin.cursor.first
    end

    def column
      $curwin.cursor.last
    end

    def buffer
      $curwin.buffer
    end

    def map_delimiter(char)
      char = "\\#{char}" if char == '|'
      Vim.command("imap #{char} <C-R>=DeliminatorDelimiter(#{char.inspect})<CR>")
    end

    def map_space
      Vim.command('imap <Space> <C-R>=DeliminatorSpace()<CR>')
    end

    def map_backspace
      Vim.command('imap <BS> <C-R>=DeliminatorBackspace()<CR>')
    end

    extend self
end
