class MidiServer < Sinatra::Base
  OPTS = { device: 1, channel: 2, octave: 3, notes_per_min: 120 }.freeze
  
  begin
    output = UniMIDI::Output[OPTS[:device] - 1] # -1 to turn :device into a 0-based index
  rescue NoMethodError
    puts "Couldn't find MIDI device"
    exit!
  end
  
  post '/play' do
    tune = params["Body"] # content of the SMS message
    
    MIDI.using(output) do
      octave OPTS[:octave]
      
      tune.split(" ").each do |x|
        note x, channel: OPTS[:channel] unless x == "_" # underscores skip a beat
        sleep 60.0 / OPTS[:notes_per_min]
        off
      end
      
    end
  end
end