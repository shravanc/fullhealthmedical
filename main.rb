
class LaboratoryTestResult
  attr_accessor :code, :result, :format, :comment

  def initialize(metadata = {})
    metadata.each do |k, v|
      send("#{k}=", v)
    end
  end
end

class Parser
  TEST_INDTR = 'OBX'.freeze
  CMNT_INDTR = 'NTE'.freeze
  INDX_INDTR = 0

  TEST_INFO_ORDER = %w(type id code value).freeze
  CMNT_INFO_ORDER = %w(type id text).freeze

  MAPPING = {
    'C100' => 'float',
    'C200' => 'float',
    'A250' => 'boolean',
    'B250' => 'nil_3plus'
  }.freeze

  NIL_MAPPING = {
    'NIL' => -1.0,
    '+' => -2.0,
    '++' => -2.0,
    '+++' => -3.0
  }.freeze

  attr_accessor :lines, :tests, :comments, :test_comments, :results
  def initialize(input_path)
    @lines = []
    fetch_lines(input_path)

    @tests = []
    @comments = []
    @test_comments = {}
    parse_lines

    @results = []
  end

  def mapped_results
    @tests.each do |t|
      @results << LaboratoryTestResult.new(
        code: t['code'],
        result: fetch_result(t['code'], t['value']),
        format: fetch_format(t['code']),
        comment: fetch_comments(t['id'])
      )
    end
  end

  private

  def fetch_lines(input_path)
    File.open(input_path).each do |line|
      @lines << line.strip
    end
  end

  def parse_lines
    @lines.each do |line|
      data = line.split('|')
      if data[Parser::INDX_INDTR] == Parser::TEST_INDTR
        # p "PARSING TESTS"
        @tests << parse_tests(data)
      elsif data[Parser::INDX_INDTR] == Parser::CMNT_INDTR
        # p "PARSING COMMMENTS"
        @comments << parse_comments(data)
      end
    end
  end

  def parse_tests(data)
    test = {}
    Parser::TEST_INFO_ORDER.each_with_index do |info, i|
      test[info] = data[i]
    end
    test
  end

  def parse_comments(data)
    comment = {}

    Parser::CMNT_INFO_ORDER.each_with_index do |info, i|
      comment[info] = data[i]
    end
    if @test_comments.key?comment['id']
      @test_comments[comment['id']]['comments'] += ('\n' + comment['text'])
    else
      @test_comments[comment['id']] = {}
      @test_comments[comment['id']]['comments'] = comment['text']
    end
    comment
  end

  def fetch_format(code)
    Parser::MAPPING[code]
  end

  def fetch_result(code, value)
    case Parser::MAPPING[code]
    when 'float'
      return value.to_f
    when 'boolean'
      return value == 'NEGATIVE' ? -1.0 : -2.0
    when 'nil_3plus'
      return Parser::NIL_MAPPING[value]
    end
  end

  def fetch_comments(id)
    @test_comments[id]['comments']
  end
end

# path = './lab1.txt'
# parser = Parser.new(path)
# parser.mapped_results
# parser.results.each do |r|
#         p r
# end
