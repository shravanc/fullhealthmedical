require 'rspec'
require_relative 'main'

describe Parser do
  context 'Test All the Constants/Config' do
    it 'Test Indicator String should be OBX' do
      expect(Parser::TEST_INDTR).to eq('OBX')
    end

    it 'Comment Indicator String should be NTE' do
      expect(Parser::CMNT_INDTR).to eq('NTE')
    end

    it 'Index Idicator in each result comes in 0th position' do
      expect(Parser::INDX_INDTR).to eq(0)
    end
    it 'Order of the test results is Expected to be in' do
      expect(Parser::TEST_INFO_ORDER).to eq(%w(type id code value))
    end

    it 'Order of the Comments results is Expected to be in' do
      expect(Parser::CMNT_INFO_ORDER).to eq(%w(type id text))
    end

    it 'Testing the Mapping of code and format' do
      expect(Parser::MAPPING).to eq('C100' => 'float',
                                    'C200' => 'float',
                                    'A250' => 'boolean',
                                    'B250' => 'nil_3plus')
    end
    it 'Testing Nil Mapping' do
      expect(Parser::NIL_MAPPING).to eq('NIL' => -1.0,
                                        '+' => -2.0,
                                        '++' => -2.0,
                                        '+++' => -3.0)
    end
  end

  context 'Functionality Check' do
    context 'Initialization test' do
      it 'Expect Input file for initialization' do
        expect { Parser.new }.to raise_error(ArgumentError)
      end

      let(:parser) { Parser.new('./input.txt') }

      it 'Check Initialization' do
        expect(parser.lines.size).to be > 0
      end

      it 'Check first and the last line' do
        expect(parser.lines[0]).to eq('OBX|1|C100|20.0|')
        expect(parser.lines[-1]).to eq('NTE|4|Comment 2 for ++ result|')
      end

      it 'Check for Total Test Count' do
        expect(parser.tests.size).to eq(4)
      end

      it 'Check for Total Comments Count' do
        expect(parser.comments.size).to eq(5)
      end
    end

    context 'Private Method Check' do
      let(:parser) { Parser.new('./input.txt') }
      it 'parse_tests and parse_comments are private method' do
        test_line_data = parser.lines[0].split('|')
        comment_line_data = parser.lines[1].split('|')
        expect { parser.parse_tests(test_line_data) }.to raise_error(NoMethodError)
        expect { parser.parse_comments(comment_line_data) }.to raise_error(NoMethodError)
      end
      it 'Check parse_tests' do
        test_line_data = parser.lines[0].split('|')
        expect(parser.send('parse_tests', test_line_data)).to eq(
          'type' => 'OBX', 'id' => '1', 'code' => 'C100', 'value' => '20.0'
        )
      end

      it 'Check parse_comments' do
        comment_line_data = parser.lines[1].split('|')
        expect(parser.send('parse_comments', comment_line_data)).to eq(
          'type' => 'NTE', 'id' => '1', 'text' => 'Comment for C100 result'
        )
      end
    end

    context 'MappingResult Method check' do
      let(:parser) { Parser.new('./input.txt') }

      it 'Total Parser Count' do
        parser.mapped_results
        expect(parser.results.size).to eq(4)
      end

      it '#fetch_format and # fetch_result' do
        parser.mapped_results
        format_order = %w(float float boolean nil_3plus)
        result_order = [20.0, 500.0, -1.0, -2.0]
        parser.tests.each_with_index do |t, i|
          expect(parser.send('fetch_format', t['code'])).to eq(format_order[i])
          expect(parser.send('fetch_result', t['code'], t['value'])).to eq(result_order[i])
        end
      end

      it '#fetch_comments' do
        parser.mapped_results
        expected_comments = ['Comment for C100 result', 'Comment for C200 result', 'Comment for NEGATIVE result', 'Comment 1 for ++ result\nComment 2 for ++ result']
        parser.tests.each_with_index do |t, i|
          expect(parser.send('fetch_comments', t['id'])).to eq(expected_comments[i])
        end
      end
    end
  end
end
