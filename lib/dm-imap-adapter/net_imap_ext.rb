require 'net/imap'

class Net::IMAP::ResponseParser
  def resp_text_code
    @lex_state = EXPR_BEG
    match(T_LBRA)
    token = match(T_ATOM)
    name = token.value.upcase
    case name
    when /\A(?:ALERT|PARSE|READ-ONLY|READ-WRITE|TRYCREATE|NOMODSEQ|CLOSED)\z/n
      result = Net::IMAP::ResponseCode.new(name, nil)
    when /\A(?:PERMANENTFLAGS)\z/n
      match(T_SPACE)
      result = Net::IMAP::ResponseCode.new(name, flag_list)
    when /\A(?:UIDVALIDITY|UIDNEXT|UNSEEN)\z/n
      match(T_SPACE)
      result = Net::IMAP::ResponseCode.new(name, number)
    else
      # match(T_SPACE)
      ### start new
      if match(T_SPACE, T_RBRA).symbol == T_RBRA
        @lex_state = EXPR_RTEXT
        return Net::IMAP::ResponseCode.new(name, nil)
      end
      ### end new
      @lex_state = EXPR_CTEXT
      token = match(T_TEXT)
      @lex_state = EXPR_BEG
      result = Net::IMAP::ResponseCode.new(name, token.value)
    end
    match(T_RBRA)
    @lex_state = EXPR_RTEXT
    return result
  end
end

class Net::IMAP::Address
  def email
    "#{mailbox}@#{host}"
  end
  
  def to_s
    "#{name} <#{email}>".strip
  end
end