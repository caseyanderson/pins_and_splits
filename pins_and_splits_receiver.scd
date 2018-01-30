/*

pins and splits, Mark Trayle, 2014
code by Casey Anderson


density range = 0.01..1.0
trayle duration range = 1.0..10.0
bitpanic duration range = 5.0..25.0

*/

s.boot;

(

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


(
///////// OSC /////////

OSCdef(\listener, { | msg |
	msg.postln;
	switch( msg[1],
		'/dens', {
			("dens "++msg[2]).postln;
			~density.set(msg[2]);
		},
		'/dur', {
			("dur "++msg[2]).postln;
			~duration.set(msg[2]);
		},
		'/run', {
			"START SYNTH, SWITCHER!".postln;
			~back = Synth( \background, [ \trig, 1, \amp, ~backAmp.asMap ]);
			OSCdef(\whatever, ~switcher, \switch );
		},
		'/play', {
			"play back".postln;
			~back.set(\trig, 1);
		},
		'/stop', {
			"stop back".postln;
			~back.set(\trig, 0);
		},
		'/back', {
			switch( msg[2],
				'/vol', {
					("vol "++msg[3]).postln;
					~backAmp.set(msg[3]);
			});
		},
		'/fore', {
			switch( msg[2],
				'/vol', {
					("vol "++msg[3]).postln;
					~foreAmp.set(msg[3]);
		});
		},
		'/free', {
			"freeing synth".postln;
			~back.set(\amp, 0.0);
			~back.free;
	});
}, '/deployed');


)