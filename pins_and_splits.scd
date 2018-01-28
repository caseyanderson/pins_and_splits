/*

pins and splits, Mark Trayle, 2014
code by Casey Anderson


density range = 0.0..1.0
duration range = 5.0..25.0


*/

s.boot;

(
// setup database of IPs

~listofnames = List.new(2);

~ips = Dictionary.newFrom(
	List[
		\partner, "10.4.18.101",
		\me, "10.4.25.80"
	]
);

~names = ~ips.keys;

~names.do({|key|
	~listofnames.add(key);
});

// control bus

~density = Bus.control(s, 1).set(0.25);
~duration = Bus.control(s, 1).set(5.0);

)

///////// SYNTH /////////

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
	sig = LFTri.ar( freq, 0.0, amp ) * env;
	Out.ar( out, Pan2.ar( sig ));

}).add;
)


// GUI

(
~window = Window.new("pins&splits", Rect(0,0,405,220));

// background sound controls
~button = Button(~window, Rect( 10, 10, 50, 50))
        .states_([
            ["OFF", Color.white, Color.black],
            ["ON", Color.white, Color.red]
        ])

.action_({ arg butt;
    if( butt.value == 1,
        {
			"background running".postln;
			~back = Synth( \background, [ \trig, 1, \amp, 0.7 ]);
        },
        {
			"background stopped".postln;
			~back.set(\trig, 0);
			~back.free;
        }
    );
});

~number = NumberBox(~window, Rect(10, 10 + 60, 50, 50));
~number.align = \center;
~number.value = 0.0;

~slider = Slider.new(~window, Rect(65, 10, 50, 200))
.action_({ |slider|
	var val = slider.value;
	~back.set(\amp, val);
	~number.value_(val); // show slider value in number box
});


// network control

//select person to send to

~sendto = Knob.new(~window, Rect(125, 10, 50, 50))
.action_({ |knobval|
	// replace maxval
	var val = [0, 1, \lin, 1].asSpec.map(knobval.value);
	{ ~whom.value_(val) }.defer;
});


// display sendto's hostname

~whom = Button(~window, Rect( 185, 10, 100, 50))
        .states_([
	[~listofnames[0], Color.white, Color.grey],
	[~listofnames[1], Color.white, Color.grey]
]);


// send the message!

~sendNow = Button(~window, Rect( 125, 65, 160, 50))
.states_([
	["SEND", Color.white, Color.grey],
	["", Color.red, Color.red]
])
.action_({ |val|
	var num = val.value;
	if( num == 1, {
		// send here
		var host = ~whom.string;
		("//send to "++host++"!!").postln;
		~duration.get({ |value|
			var dur = value, ip;

			ip = ~ips.at(host);

			NetAddr(ip, 57120).sendMsg(\switch, 0.05, dur);

			SystemClock.sched( 0.25, {
			{ ~sendNow.value_(0) }.defer; // this resets sendNow
		});
		});
	});

});

// set the duration
~durNumber = NumberBox(~window, Rect(345, 10 , 50, 50));
~durNumber.align = \center;
~durNumber.value = 0.0;

~durSlider = Slider.new(~window, Rect(290, 10, 50, 200))
.action_({ |slider|
	var val = [5.0, 25.0, \lin, 0.01].asSpec.map(slider.value);
	//set bus
	~duration.set(val);
	~durNumber.value_(val); // show slider value in number box
});


~window.front;

)


// OSC //

(
~switcher = { | msg, tm, addr |

	var dens = msg[1], dur = msg[2], rPos, bufNumber;
	postln( "pins and splits "++msg );

	~back.set(\trig, 0 ); // turns background off

	// foreground goes here

	Synth(\foreground, [\amp, 0.9, \dur, dur, \trig, 1, \freq, { rrand(200.0, 500.0).asFloat }.value ]);

	SystemClock.sched(dur, {

		// turn the background synth back on after dur

		~back.set( \trig, 1 );

	});
};

// respond to the switch statement by running the switcher function

OSCdef(\whatever, ~switcher, \switch );

)


///////////////

//send to myself
//
x.to( \mdp, [ \switch, 0.9, 10.0 ] );



