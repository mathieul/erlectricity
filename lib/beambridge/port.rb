module Beambridge
  class Port
    attr_reader :input, :output
    attr_reader :skipped
    attr_reader :queue

    def initialize(input=STDIN, output=STDOUT)
      @input = input
      @output = output

      input.sync = true
      output.sync = true

      output.set_encoding("ASCII-8BIT")

      @encoder = Beambridge::Encoder.new(nil)
      @skipped = []
      @queue = []
    end

    def receive
      queue.empty? ? read_from_input : queue.shift
    end

    def send(term)
      @encoder.out = StringIO.new('', 'w')
      @encoder.write_any(term)
      data = @encoder.out.string
      output.write([data.length].pack("N"))
      output.write(data)
    end

    def restore_skipped
      @queue = self.skipped + self.queue
    end

    private

    def read_from_input
      raw = input.read(4)
      return nil unless raw

      packet_length = raw.unpack('N').first
      data = input.read(packet_length)
      Beambridge::Decoder.decode(data)
    end
  end
end
