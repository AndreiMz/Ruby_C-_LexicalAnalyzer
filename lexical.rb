require 'automata'
require 'awesome_print'
require 'json'
load 'extensions.rb'

COMMENT_START_POS_LINE = 126
COMMENT_START_POS_MULTIPLE = 127
VALUE_POS = 0
IS_FINAL_POS = 1
TRANSITION_POS = 2
TRANSITION_ERROR = 254
DUMMY_NODE_VALUE = 255


def init
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
  automata
end

def exec(automata)
  ARGV.each do |file|
    automata.feed(File.read(file))
    ap automata.tokens
    File.open("#{file.split('.').first}_results.json",'w') do |f|
      f << JSON.pretty_generate(automata.tokens)
    end
  end
end


exec(init)