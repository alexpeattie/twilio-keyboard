Although [Twilio](https://www.twilio.com/) is well-known to developers, it has yet to make a mark in the world of music. This is a shame, because (with a little help) Twilio can lay down a funky solo that would make Billy Joel proud. We'll make an app which will let you **text a tune** to a Twilio number, and have it played on your keyboard almost instantly. It's sort of the 21st century equivalent of teaching a monkey to play the piano.

![Monkey on piano](https://raw.github.com/alexpeattie/twilio-keyboard/master/img/monkey.jpg)

## You'll need

- A Twilio account
- A MIDI keyboard hooked up to your dev machine (I'm using a [Casio LK-300TV](http://www.casio.com/products/archive/Digital_Pianos_%26_Keyboards/Lighted_Keys/LK-300TV/) connected via USB)
- Ruby 1.9+

## Making sweet music

First clone the repo and install the necessary gems:

    git clone https://github.com/alexpeattie/twilio-keyboard.git
    cd twilio-keyboard/
    bundle install

The app works its magic with a simple 30-line ruby file: `server.rb` - we're going to remake it from scratch, so rename the existing version `server_old.rb` and create a blank `server.rb` in your favourite text editor.

First we'll need to `require` the awesome **[micromidi](https://github.com/arirusso/micromidi)** gem, which we'll use to interact our with keyboard:

```ruby
require 'midi'
```

Next we need to load our MIDI device:

```ruby
output = UniMIDI::Output[0]
```

(If you have more than one device - you lucky thing - you might need to change `0` to the index of your desired output). micromidi uses a cool DSL with a wealth of commands, we'll only use two for now: `note` and `off`:

```ruby
MIDI.using(output) do
  note "G"
  sleep 0.5  # wait for half a second
  off  # end the note
end
```

Run your script with `ruby server.rb`. Hopefully you'll hear your keyboard play half a second of G! If not, you might have to use a different MIDI channel:

```ruby
note "G", channel: 5
```

One note does not a melody make, however, so let's add the ability to play a tune. We'll iterate through a simple string of notes like "C Ab E E G C#", playing each in turn:

```ruby
tune = "C Ab E E G C#"
MIDI.using(output) do

  tune.split(" ").each do |n|
    note n
    sleep 0.5
    off
  end

end
```

One final thing we're missing is the ability to add pauses - let's use an underscore to skip a beat:

```ruby
note n unless n == "_"
```

## Come fly with me

Now we've got control of our keyboard, we need a way to let it talk to Twilio. Let's make a simple web server using the appropriately-named **[Sinatra](http://www.sinatrarb.com/)**.

We'll also launch the server on top of [Rack](http://rack.github.com/), which means we can get rid of `require 'midi'` - Rack will load our gems automatically from our `Gemfile`. Let's  create a class to contain our app:

```ruby
class MidiServer < Sinatra::Base
  # ..existing code
end
```

Now, all that's left to do is wrap our code in a `get` block:

```ruby
class MidiServer < Sinatra::Base
  get '/play' do
    # ...existing code 
  end
end
```

That's it! Run `rackup` from your console, and go to www.local.host:4567/play - your keyboard should automatically play your ditty.

## Tunneling out

We're **almost** ready to add Twilio to the mix. But we want Twilio to be able to play an arbitrary tune, based on the body of the SMS message we send. Twilio's going to send the data by `POST` rather than `GET`, in a parameter called `"Body"`. So we want our code to look like:

```ruby
post "/play" do
  output = UniMIDI::Output[0]
  
  tune = params["Body"]
  MIDI.using(output) do
    # blah blah...
  end
end
```

Let's also move the `output = UniMIDI::Output[0]` outside of the `post` block, so we're only loading our MIDI device once (when the server starts).

The last problem is that localhost is only accessible on our dev machine - i.e. Twilio won't have access to it. Luckily the `localtunnel` gem solves that - see [the Twilio docs](http://www.twilio.com/docs/quickstart/python/localtunnel) for full instructions.

    localtunnel 4567
    Port 4567 is now publicly accessible from http://4jns.localtunnel.com ...
    
You can test everything's working using `curl`:

    curl --data "Body=C A G" http://4jns.localtunnel.com/play

## Twilio time!

You'll need to [buy a Twilio number](https://www.twilio.com/user/account/phone-numbers/available/local) if you don't already have one. Go to the settings for the number you want to use (via the [Numbers dashboard](https://www.twilio.com/user/account/phone-numbers/incoming)) - and set the **SMS Request URL** to your localtunnel URL (e.g. http:<span></span>//4jns.localtunnel.com/play).

**You're done!** Sit back, text a tune to your Twilio number and enjoy.

## Turning it up to eleven

So you've turned Twilio into a musical prodigy. Now what?

If you open up `server_old.rb` you can see I've added a couple of extra tweaks. There's a hash called `OPTS` which sets the device, MIDI channel, octave and tempo. I've also added some very basic exception handling when loading the MIDI device.

Twilio isn't limited to SMS - with some tweaking from an intrepid hacker, the app could let you call up and play a tune with the keypad...

And in the near-future, we might be able to accomplish this on the client-side with the newly-proposed Web MIDI API. See the W3C spec [here](http://webaudio.github.com/web-midi-api/).