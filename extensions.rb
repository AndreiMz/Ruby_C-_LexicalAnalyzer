require 'automata'

#add helper methods to String class
class String 
  def letter?
    self =~ /[[:alpha:]]/ ? true : false
  end

  def number?
    self =~ /[[:digit:]]/ ? true : false
  end
end


#modify DFA library to extend functionality for current project

module Automata
  class StateDiagram
    #add token list with token types
    attr_accessor :static_states, :tokens
    #returns state type if it exists 
    def state_type(state)
      begin
        self.static_states.find{|type| type[1].include? state}[0].to_s.capitalize
      rescue Exception => e
        return 'Identifier'
      end
    end
  end


  class DFA < StateDiagram

    def checkSym(sym)
      return 'W' if sym.letter? || sym =='_'
      return 'N' if sym.number?
      '$' #wildcard
    end

    def transition(curr_state,key)
      target = @transitions[curr_state]
      return target[key] if target.has_key? key 
      return target[checkSym(key)] if target.has_key? checkSym(key)
      return target['$'] if target.has_key? '$'
      return 'TERR'
    end

    def feed(input)
      @tokens = []
      token_idx_start = 0
      #eliminate whitespace in beggining
      head = @start.to_s
      comment = false
      input.gsub!(/^[ \t]+/,'')
      tkn = ''
      input.split("\n").each do |line|
        next if line[0] == '#'
        #head = comment ? COMMENT_START_POS_LINE : @start.to_s
        line.each_char.with_index do |symbol,idx|

          tr = transition(head,symbol)
          #ap [symbol,head,tr]
          if tr == COMMENT_START_POS_LINE then tkn='';break end
          if tr == COMMENT_START_POS_MULTIPLE || tr == COMMENT_START_POS_MULTIPLE+1
            head = transition(head,symbol)
            comment = true
            next
          elsif tr == "0"
            head = "0"
            comment = false
            tkn = ''
            next
          end
          if tr == "TERR"
            ap tkn
            @tokens << [tkn, state_type(head)]
            head = "0"
            tkn = ''
            next
          end
          tkn = tkn + symbol
         # ap tkn
          head = transition(head,symbol)
        end
      end
      accept = is_accept_state? head
      resp = {
        input: input,
        accept: accept,
        head: head 
      }
      resp
    end
  end
end