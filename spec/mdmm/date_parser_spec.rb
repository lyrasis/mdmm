RSpec.describe Mdmm::DateParser do
  let(:d1) { DateParser.new('1', '1997-1998') }
  let(:d2) { DateParser.new('1', 'circa 1997') }
  let(:d3) { DateParser.new('1', 'December 18, 1997') }

  describe '.parsed' do
    context 'when input = YYYY-MM-DD' do
      it "returns [YYYY-MM-DD]" do
        expect(DateParser.new('1', '1981-12-18').parsed).to eq(['1981-12-18'])
      end
    end
    context 'when input = YYYY-MM' do
      it "returns [YYYY-MM]" do
        expect(DateParser.new('1', '2019-03').parsed).to eq(['2019-03'])
      end
    end
    context 'when input = YYYY' do
      it "returns [YYYY]" do
        expect(DateParser.new('1', '2019').parsed).to eq(['2019'])
      end
    end
    context 'when input = M-D-YYYY' do
      it "returns [YYYY-MM-DD]" do
        expect(DateParser.new('1', '2-5-1992').parsed).to eq(['1992-02-05'])
      end
    end
    context 'when input = YYYY Month D' do
      it "returns [YYYY-MM-DD]" do
        expect(DateParser.new('1', '2000 May 5').parsed).to eq(['2000-05-05'])
      end
    end
    context 'when input = YYYY Mon' do
      it "returns [YYYY-MM]" do
        expect(DateParser.new('1', '1999 Mar').parsed).to eq(['1999-03'])
      end
    end
    context 'when input = Mon YYYY' do
      it "returns [YYYY-MM]" do
        expect(DateParser.new('1', 'Mar 1999').parsed).to eq(['1999-03'])
      end
    end
    context 'when input = M/D/YYYY' do
      it "returns [YYYY-MM-DD]" do
        expect(DateParser.new('1', '3/5/1999').parsed).to eq(['1999-03-05'])
      end
    end
    context 'when input = Month DD, YYYY' do
      it "returns [YYYY-MM-DD]" do
        expect(d3.parsed).to eq(['1997-12-18'])
      end
    end
    context 'when input = YYY2-YYY8' do
      it "returns [YYY2, YYY8]" do
        expect(d1.parsed).to eq(['1997', '1998'])
      end
    end
    context 'when input = YYYY/nn (WARNING: this is ambiguous and is treated wrong here if nn represents a month!)' do
      it "returns [YYYY, YYnn]" do
        expect(DateParser.new('1', '1947/48').parsed).to eq(['1947', '1948'])
      end
    end
    context 'when input = YYY1-M1-D1, YYY2-M2-D2, YYY3-M3-D3, YYY4-M4-D4' do
      it "returns [YYY1-M1-D1, YYY4-M4-D4]" do
        expect(DateParser.new('1', '2000-01-01, 2001-01-01, 2002-02-02, 2003-03-03').parsed).to eq(['2000-01-01', '2003-03-03'])
      end
    end
    context 'when input = YYYY-MM-D1 or YYYY-MM-D2' do
      it "returns [YYYY-MM-D1, YYYY-MM-D2]" do
        expect(DateParser.new('1', '2000-01-01 or 2000-01-12').parsed).to eq(['2000-01-01', '2000-01-12'])
      end
    end
    context 'when input = YYY1-M1, YYY2-M2, YYY3-M3, YYY4-M4' do
      it "returns [YYY1-M1, YYY4-M4]" do
        expect(DateParser.new('1', '2000-01, 2001-01, 2002-02, 2003-03').parsed).to eq(['2000-01', '2003-03'])
      end
    end
    context 'when input = YYYYs' do
      it "returns [YYY0, YYY9] (with qualifier = approximate)" do
        expect(DateParser.new('1', '1990s').parsed).to eq(['1990', '1999'])
      end
    end
    context 'when input = YY80s or YY90s' do
      it "returns [YY80, YY99] (with qualifier = approximate)" do
        expect(DateParser.new('1', '1980s or 1990s').parsed).to eq(['1980', '1999'])
      end
    end
    context 'when input = Mid YYYYs' do
      it "returns [YYY5] (with qualifier = approximate)" do
        expect(DateParser.new('1', 'Mid 1980s').parsed).to eq(['1985'])
      end
    end
    context 'when input = Early YYYYs' do
      it "returns [YYY0, YYY4] (with qualifier = approximate)" do
        expect(DateParser.new('1', 'Early 1980s').parsed).to eq(['1980', '1984'])
      end
    end
    context 'when input = Late YYYYs' do
      it "returns [YYY6, YYY9] (with qualifier = approximate)" do
        expect(DateParser.new('1', 'Late 1980s').parsed).to eq(['1986', '1989'])
      end
    end
    context 'when input = Spring YYYY' do
      it "returns [YYYY-03-01, YYYY-05-31]" do
        expect(DateParser.new('1', 'Spring 1980').parsed).to eq(['1980-03-01', '1980-05-31'])
      end
    end
    context 'when input = Fall (or Autumn) YYYY' do
      it "returns [YYYY-09-01, YYYY-11-30]" do
        expect(DateParser.new('1', 'Autumn 1980').parsed).to eq(['1980-09-01', '1980-11-30'])
      end
    end
    context 'when input = Winter YYY4' do
      it "returns [YYY3-12-01, YYY4-02-28]" do
        expect(DateParser.new('1', 'Winter 1980').parsed).to eq(['1979-12-01', '1980-02-28'])
      end
    end
    context 'when input = Spring YYYY' do
      it "returns [YYYY-03-01, YYYY-05-31]" do
        expect(DateParser.new('1', 'Spring 1980').parsed).to eq(['1980-03-01', '1980-05-31'])
      end
    end
    context 'when input = YYYY Month D-D2' do
      it "returns [YYYY-MM-DD, YYYY-MM-D2]" do
        expect(DateParser.new('1', '2000 June 3-15').parsed).to eq(['2000-06-03', '2000-06-15'])
      end
    end
    context 'when input = YYYY Month1 D1-Month2 D2' do
      it "returns [YYYY-M1-D1, YYYY-M2-D2]" do
        expect(DateParser.new('1', '2000 June 1-July 4').parsed).to eq(['2000-06-01', '2000-07-04'])
      end
    end
    context 'when input = YYYY Month D, D2' do
      it "returns [YYYY-MM-DD, YYYY-MM-D2]" do
        expect(DateParser.new('1', '2000 June 3, 15').parsed).to eq(['2000-06-03', '2000-06-15'])
      end
    end
    context 'when input = Month D-D2, YYYY' do
      it "returns [YYYY-MM-DD, YYYY-MM-D2]" do
        expect(DateParser.new('1', 'June 1 -3, 2000').parsed).to eq(['2000-06-01', '2000-06-03'])
      end
    end
    context 'when input = Month1 D1-Month2 D2, YYYY' do
      it "returns [YYYY-M1-D1, YYYY-M2-D2]" do
        expect(DateParser.new('1', 'May 5- July 7, 2000').parsed).to eq(['2000-05-05', '2000-07-07'])
      end
    end
    context 'when input = YYYY Month1 D1, Month2 D2, D3-D7' do
      it "returns [YYYY-M1-D1, YYYY-M2-D7]" do
        expect(DateParser.new('1', '2000 May 5, June 2, 9-23').parsed).to eq(['2000-05-05', '2000-06-23'])
      end
    end
    context 'when input = YYYY Month1-Month2' do
      it "returns [YYYY-M1, YYYY-M2]" do
        expect(DateParser.new('1', '2000 May -June').parsed).to eq(['2000-05', '2000-06'])
      end
    end
    context 'when input = Month1 - Month2 YYYY' do
      it "returns [YYYY-M1, YYYY-M2]" do
        expect(DateParser.new('1', 'June - July 2000').parsed).to eq(['2000-06', '2000-07'])
      end
    end
    context 'when input = YYY1 Month1 D1- YYY2 Month2 D2' do
      it "returns [YYY1-M1-D1, YYY2-M2-D2]" do
        expect(DateParser.new('1', '2000 June 3- 2001 Jan 20').parsed).to eq(['2000-06-03', '2001-01-20'])
      end
    end
    context 'when input = YYYY Month D1, D2-D5, D8, D9' do
      it "returns [YYYY-MM-D1, YYYY-MM-D9]" do
        expect(DateParser.new('1', '2000 June 1, 2-5, 8, 9').parsed).to eq(['2000-06-01', '2000-06-09'])
      end
    end
    context 'when input = YYYY Month D1, D2-D5, D8, and D9' do
      it "returns [YYYY-MM-D1, YYYY-MM-D9]" do
        expect(DateParser.new('1', '2000 June 1, 2-5, 8, and 9').parsed).to eq(['2000-06-01', '2000-06-09'])
      end
    end
    context 'when input = YYY1-M1-00-YYY2-M2-00' do
      it "returns [YYY1-M1, YYY2-M2]" do
        expect(DateParser.new('1', '2000-01-00-2001-03-00').parsed).to eq(['2000-01', '2001-03'])
      end
    end
    context 'when input = YYY1-M1-00 - YYY2-M2-00' do
      it "returns [YYY1-M1, YYY2-M2]" do
        expect(DateParser.new('1', '2000-01-00 - 2001-03-00').parsed).to eq(['2000-01', '2001-03'])
      end
    end
    context 'when input = circa YYYY' do
      it "returns [YYYY]" do
        expect(d2.parsed).to eq(['1997'])
      end
    end
  end # describe ".parsed" do

  describe '.qualifier' do
    context 'when input = circa 1997' do
      it "returns approximate" do
        expect(d2.qualifier).to eq('approximate')
      end
    end
  end # describe ".parsed" do

  describe '.result' do
    context 'WHEN .parsed.length == 1...' do
      context 'AND no qualifier' do
      it "returns parsed date as keyDate" do
        expect(d3.result).to eq(['1997-12-18&&&encoding=w3cdtf&&&keyDate=yes'])
      end
      end
      context 'AND qualifier' do
        it "returns original value with qualifier first..." do
          expect(d2.result[0]).to eq('circa 1997&&&qualifier=approximate')
        end
        it "...followed by first parsed value as keyDate with qualifier" do
          expect(d2.result[1]).to eq('1997&&&encoding=w3cdtf&&&keyDate=yes&&&qualifier=approximate')
        end
      end

    end
    context 'when .parsed.length == 2' do
      let(:d1r) { d1.result }
      it "returns original value first..." do
        expect(d1.result[0]).to eq('1997-1998')
      end
      it "...followed by first parsed value as keyDate and start..." do
        expect(d1.result[1]).to eq('1997&&&encoding=w3cdtf&&&keyDate=yes&&&point=start')
      end
      it "...followed by second parsed value as end..." do
        expect(d1.result[2]).to eq('1998&&&encoding=w3cdtf&&&point=end')
      end
    end
  end # describe ".result" do

end # RSpec.describe Mdmm::DateCleaner do
