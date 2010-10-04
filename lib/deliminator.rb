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
          reset
          Vim.let('l:result', method.bind(self).call(*args))
        end
      end
    end
  end

  BRACKETS   = { '(' => ')', '[' => ']', '{' => '}', '<' => '>' }
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
    inside_empty_bracket? ? '  <Left>' : ' '
  end

  def backspace
    inside_empty_pair? ? '<BS><Del>' : '<BS>'
  end

  vim_action :delimiter, :space, :backspace

  protected

    def opening?(char)
      DELIMITERS.keys.include?(char)
    end

    def close?(char)
      close_quote?(char) || close_bracket?(char)
    end

    def close_quote?(char)
      !closing_quote?(char) && !quote?(next_char)
    end

    def close_bracket?(char)
      bracket?(char) and !followed_by_closing_pair?(char) || inside_empty_pair?
    end

    def step_over?(char)
      char == next_char
    end

    def closing_quote?(char)
      # quote?(char) and content_before.count(char) == content_after.count(char) + 1
      quote?(char) and prev_char =~ /\w/
    end

    def followed_by_closing_pair?(char)
      next_char == closing_pair(char)
    end

    def inside_empty_brackets?
      bracket?(prev_char) && inside_empty_pair?
    end

    def inside_empty_pair?
      prev_char && closing_pair(prev_char) == next_char
    end

    def bracket?(char)
      BRACKETS.keys.include?(char)
    end

    def quote?(char)
      QUOTES.keys.include?(char)
    end

    def closing_pair(char)
      DELIMITERS[char]
    end

    def reset
      instance_variables.each { |name| instance_variable_set(name, nil) }
    end

    def prev_char
      @prev_char ||= begin
        char_at(column)
      end
    end

    def next_char
      @next_char ||= begin
        char_at(column + 1)
      end
    end

    def content_before
      lines[0..line_number - 2].join + line_before
    end

    def content_after
      line_after + lines[line_number..-1].join
    end

    def line_before
      line[0..column - 2].to_s
    end

    def line_after
      line[column - 1..-1].to_s
    end

    def char_at(column)
      line[column - 1, 1]
    end

    def lines
      (1..buffer.length.to_i).map { |ix| buffer[ix.to_i] }.flatten
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
