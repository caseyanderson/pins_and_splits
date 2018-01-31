/*

pins and splits, Mark Trayle, 2014
code by Casey Anderson


density range = 0.01..1.0
trayle duration range = 1.0..10.0
bitpanic duration range = 5.0..25.0

*/

s.boot;

(
// setup database of IPs

~ips = Dictionary.newFrom(
	List[
		"partner", "10.4.18.72",
		"me", "10.4.25.141"
	]
);

~names = ~ips.keys;

~listofnames = ~names.as(List);

~states = ~listofnames.collect { |name|
[name, Color.white, Color.grey]
};

~addresses = ~listofnames.collect { |name|
NetAddr(~ips[name], 57120)
};


// control bus

~density = Bus.control(s, 1).set(0.25);
~duration = Bus.control(s, 1).set(5.0);
~backAmp = Bus.control(s, 1).set(0.0);
~foreAmp = Bus.control(s, 1).set(0.0);

)

///////// SYNTHS /////////

(

/*background sound
(this is too boring for use in this piece
but enough to demonstrate the structure)
*/

SynthDef( \background, {| amp = 0.0, out = 0, trig = 0 |
	var env, sig;

	env = EnvGen.kr( Env.asr( 0.1, 0.9, 0.1 ), trig,  doneAction: 0 );
	sig = PinkNoise.ar( amp ) * env;
	Out.ar( out, Pan2.ar( sig ) );

}).add;


/*foreground sound
(also too boring for use in this piece
but different enough to be a noticeable
change upon receiving a switch message)
*/

SynthDef( \foreground, { | amp = 0.0, dur = 4, freq = 300, out = 0, trig = 0 |
	var env, sig;

	env = EnvGen.kr( Env.linen( 0.01, dur, 0.01 ), trig, doneAction: 2 );
	sig = SinOsc.ar( freq, 0.0, amp ) * env;
	Out.ar( out, Pan2.ar( sig ));

}).add;


// switcher function

~switcher = { | msg, tm, addr |

	var dens = msg[1], dur = msg[2], rPos, bufNumber;
	postln( "pins and splits "++msg );

	~back.set(\trig, 0 ); // turns background off

	// foreground goes here

	Synth(\foreground, [\amp, ~foreAmp.asMap, \dur, dur, \trig, 1, \freq, { rrand(200.0, 500.0).asFloat }.value ]);

	SystemClock.sched(dur, {

		// turn the background synth back on after dur

		~back.set( \trig, 1 );

	});
};


)


// GUI

(

~window = Window.new("pins&splits", Rect(0,0,470,280))
    .onClose_({
	"CLOSING".postln;
	OSCdef.freeAll;
	~back.free;

});


// background sound controls
~button = Button(~window, Rect( 10, 10, 50, 50))
        .states_([
            ["OFF", Color.white, Color.black],
            ["ON", Color.white, Color.red]
        ])

.action_({ arg butt;
    if( butt.value == 1,
        {
			"START THE SWITCHER".postln;
			OSCdef(\whatever, ~switcher, \switch );
			"RUN BACKGROUND".postln;
			~back = Synth( \background, [ \trig, 1, \amp, ~backAmp.asMap ]);
        },
        {
			"STOPPED BACKGROUND".postln;
			~back.set(\trig, 0);
			~back.free;
			"KILLED SWITCHER".postln;
			OSCdef(\whatever).free;
        }
    );
});

~backAmpSlider = Slider.new(~window, Rect(65, 10, 50, 200))
.action_({ |slider|
	var val = slider.value;

	~backAmp.set(val);
	~backAmpVal.value_(val); // show slider value in number box
});


~backAmpVal = NumberBox(~window, Rect(65, 215, 50, 25));
~backAmpVal.align = \center;
~backAmpVal.value = 0.0;

~backAmpLabel = StaticText(~window, Rect( 65, 245, 50, 25));
~backAmpLabel.align = \center;
~backAmpLabel.string = "back";
~backAmpLabel.background = Color.white;


~foreAmpSlider = Slider.new(~window, Rect(120, 10, 50, 200))
.action_({ |slider|
	var val = slider.value;

	~foreAmp.set(val);
	~foreAmpVal.value_(val); // show slider value in number box
});


~foreAmpVal = NumberBox(~window, Rect(120, 215, 50, 25));
~foreAmpVal.align = \center;
~foreAmpVal.value = 0.0;

~foreAmpLabel = StaticText(~window, Rect( 120, 245, 50, 25));
~foreAmpLabel.align = \center;
~foreAmpLabel.string = "fore";
~foreAmpLabel.background = Color.white;


// network control

//select person to send to

~sendto = Knob.new(~window, Rect(185, 10, 50, 50))
.action_({ |knobval|
	// replace maxval

	var maxval, val;
	maxval = (~listofnames.size) - 1;
	val = [0, maxval, \lin, 1].asSpec.map(knobval.value);
	{ ~whom.value_(val) }.defer;
});


// display sendto's hostname

~whom = Button(~window, Rect( 245, 10, 100, 50))
.states_(~states);


// send the message!

~sendNow = Button(~window, Rect( 185, 65, 160, 50))
.states_([
	["SEND", Color.white, Color.grey],
	["", Color.red, Color.red]
])
.action_({ |val|
	var num = val.value;
	if( num == 1, {
		// send here
		// Changes are here:
		var addr = ~addresses[~whom.value];
		("//send to " ++ ~listofnames[~whom.value] ++ "!!").postln;
		~duration.get({ |durValue|
			var dens, dur = durValue, ip;
			~density.get({ |densValue|
				dens = densValue;
				// and here
				addr.sendMsg(\switch, dens, dur);
				SystemClock.sched( 0.25, {
					{ ~sendNow.value_(0) }.defer; // this resets sendNow
				});
			});
		});
	});
});


// density

~densSlider = Slider.new(~window, Rect(355, 10, 50, 200))
.action_({ |slider|
	var val = [0.01, 1.0, \lin, 0.01].asSpec.map(slider.value);
	//set bus
	~density.set(val);
	~densNumber.value_(val); // show slider value in number box
});

~densNumber = NumberBox(~window, Rect(355, 215, 50, 25));
~densNumber.align = \center;
~densNumber.value = 0.0;

~densLabel = StaticText(~window, Rect( 355, 245, 50, 25));
~densLabel.align = \center;
~densLabel.string = "dens";
~densLabel.background = Color.white;


// duration

~durSlider = Slider.new(~window, Rect(410, 10, 50, 200))
.action_({ |slider|
	var val = [5.0, 25.0, \lin, 0.01].asSpec.map(slider.value);
	//set bus
	~duration.set(val);
	~durNumber.value_(val); // show slider value in number box
});

~durNumber = NumberBox(~window, Rect(410, 215, 50, 25));
~durNumber.align = \center;
~durNumber.value = 0.0;

~durLabel = StaticText(~window, Rect( 410, 245, 50, 25));
~durLabel.align = \center;
~durLabel.string = "dur";
~durLabel.background = Color.white;

~window.front;

)
