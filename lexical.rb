require 'automata'
require 'awesome_print'
require 'json'
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
COMMENT_START_POS_LINE = 126
COMMENT_START_POS_MULTIPLE = 127
VALUE_POS = 0
IS_FINAL_POS = 1
TRANSITION_POS = 2
TRANSITION_ERROR = 254
DUMMY_NODE_VALUE = 255
static_states = {
  keyword: %w(29 56),
  operator: %w(15 16 17 18 19 20 21 22 23),
  separator: ['125'],
  constant: %w(4 8 9 10 12 14)
}


  automata_data = YAML.load(File.read("automata_data.yml"))
  automata = Automata::DFA.new

  automata.alphabet = automata_data.flatten.select {|e| e.is_a? String}.uniq
  automata.states = automata_data.collect(&:first).map(&:to_s)
  automata.accept = automata_data.collect {|e| e[0] unless e[1]==0}.compact.map(&:to_s)
  automata.transitions = {}
  automata.static_states = static_states
  automata.start = '0'
  automata.tokens = []
  automata_data.each do |input_line|
    state = input_line[0].to_s
    res = {}
    transitions = {}
    input_line[2..-1].each_slice(2) {|key,resulting_state| transitions.merge!(key => resulting_state.to_s)}
    automata.transitions.merge!({ state => transitions })
  end

ARGV.each do |file|
  automata.feed(File.read(file))
  ap automata.tokens
  File.open("#{file}_results.json",'w') do |f|
    f << JSON.pretty_generate(automata.tokens)
  end
end