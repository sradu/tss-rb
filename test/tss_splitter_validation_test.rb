require 'test_helper'

describe TSS::Splitter do
  before do
    @s = TSS::Splitter.new(secret: 'my secret')
  end

  describe 'secret' do
    it 'must raise an error if nil' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: nil).split }
    end

    it 'must raise an error if not a string' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 123).split }
    end

    it 'must raise an error if size < 1' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: '').split }
    end

    it 'must raise an error if size > TSS::MAX_UNPADDED_SECRET_SIZE' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a' * (TSS::MAX_UNPADDED_SECRET_SIZE + 1)).split }
    end

    it 'must raise an error if String encoding is not UTF-8' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a'.force_encoding('ISO-8859-1')).split }
    end

    it 'must return an Array of default shares with US-ASCII encoded secret' do
      s = TSS::Splitter.new(secret: 'a'.force_encoding('US-ASCII')).split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      assert_kind_of String, s.first
    end

    it 'must return an Array of default shares with a min size secret' do
      s = TSS::Splitter.new(secret: 'a').split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      assert_kind_of String, s.first
    end

    it 'must return an Array of default shares with a max size secret' do
      s = TSS::Splitter.new(secret: 'a' * TSS::MAX_UNPADDED_SECRET_SIZE).split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      assert_kind_of String, s.first
    end
  end

  describe 'threshold' do
    it 'must raise an error if size < 1' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', threshold: 0).split }
    end

    it 'must raise an error if size > 255' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', threshold: 256).split }
    end

    it 'must return an Array of default shares with a min size threshold' do
      s = TSS::Splitter.new(secret: 'a', threshold: 1).split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      secret = TSS::Combiner.new(shares: s.sample(1)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 1
    end

    it 'must return an Array of default threshold (3) shares with no threshold' do
      s = TSS::Splitter.new(secret: 'a').split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      secret = TSS::Combiner.new(shares: s.sample(3)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 3
    end

    it 'must return an Array of default shares with a max size threshold' do
      s = TSS::Splitter.new(secret: 'a', threshold: 255, num_shares: 255).split
      assert_kind_of Array, s
      assert s.size.must_equal 255
      secret = TSS::Combiner.new(shares: s.sample(255)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 255
    end
  end

  describe 'num_shares' do
    it 'must raise an error if size < 1' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', num_shares: 0).split }
    end

    it 'must raise an error if size > 255' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', num_shares: 256).split }
    end

    it 'must raise an error if num_shares < threshold' do
      assert_raises(TSS::ArgumentError) { TSS::Splitter.new(secret: 'a', threshold: 3, num_shares: 2).split }
    end

    it 'must return an Array of shares with a min size' do
      s = TSS::Splitter.new(secret: 'a', threshold: 1, num_shares: 1).split
      assert_kind_of Array, s
      assert s.size.must_equal 1
      secret = TSS::Combiner.new(shares: s.sample(1)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 1
    end

    it 'must return an Array of threshold (5) shares with no num_shares' do
      s = TSS::Splitter.new(secret: 'a').split
      assert_kind_of Array, s
      assert s.size.must_equal 5
      secret = TSS::Combiner.new(shares: s).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 3
    end

    it 'must return an Array of shares with a max size' do
      s = TSS::Splitter.new(secret: 'a', threshold: 255, num_shares: 255).split
      assert_kind_of Array, s
      assert s.size.must_equal 255
      secret = TSS::Combiner.new(shares: s.sample(255)).combine
      assert_kind_of String, secret[:secret]
      secret[:threshold].must_equal 255
    end
  end

  describe 'identifier' do
    it 'must raise an error if size > 16' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', identifier: 'a'*17).split }
    end

    it 'must raise an error if non-whitelisted characters' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', identifier: '&').split }
    end

    it 'must raise an error if passed an empty string' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', identifier: '').split }
    end

    it 'must accept a String with all whitelisted characters' do
      id = 'abc-ABC_0.9'
      s = TSS::Splitter.new(secret: 'a', identifier: id).split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:identifier].must_equal id
    end

    it 'must accept a 16 Byte String' do
      id = SecureRandom.hex(8)
      s = TSS::Splitter.new(secret: 'a', identifier: id).split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:identifier].must_equal id
    end
  end

  describe 'hash_alg' do
    it 'must raise an error if empty' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', hash_alg: '').split }
    end

    it 'must raise an error if value is not in the Enum' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', hash_alg: 'foo').split }
    end

    it 'must accept an NONE String' do
      s = TSS::Splitter.new(secret: 'a', hash_alg: 'NONE').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:hash_alg].must_equal 'NONE'
    end

    it 'must accept an SHA1 String' do
      s = TSS::Splitter.new(secret: 'a', hash_alg: 'SHA1').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:hash_alg].must_equal 'SHA1'
    end

    it 'must accept an SHA256 String' do
      s = TSS::Splitter.new(secret: 'a', hash_alg: 'SHA256').split
      secret = TSS::Combiner.new(shares: s).combine
      secret[:hash_alg].must_equal 'SHA256'
    end
  end

  describe 'format' do
    it 'must raise an error if a an invalid value is passed' do
      assert_raises(ParamContractError) { TSS::Splitter.new(secret: 'a', format: 'alien').split }
    end

    it 'must default to HUMAN format output when no param is passed' do
      s = TSS::Splitter.new(secret: 'a').split
      s.first.must_match(/^tss~/)
    end

    it 'must default to HUMAN format output when nil is passed' do
      s = TSS::Splitter.new(secret: 'a', format: nil).split
      s.first.must_match(/^tss~/)
    end

    it 'must accept a HUMAN option' do
      s = TSS::Splitter.new(secret: 'a', format: 'HUMAN').split
      s.first.encoding.to_s.must_equal 'UTF-8'
      s.first.must_match(/^tss~/)
      secret = TSS::Combiner.new(shares: s).combine
      secret[:secret].must_equal 'a'
    end

    it 'must accept a BINARY option' do
      s = TSS::Splitter.new(secret: 'a', format: 'BINARY').split
      s.first.encoding.to_s.must_equal 'ASCII-8BIT'
      secret = TSS::Combiner.new(shares: s).combine
      secret[:secret].must_equal 'a'
    end
  end
end
