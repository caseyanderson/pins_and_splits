/*

pins and splits, Mark Trayle, 2014

distributed version: Sender/Controller for pins and splits
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
		"mypi", "10.4.25.223"
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
			"START THE SWITCHER, RUN BACKGROUND".postln;
			~addresses[0].sendMsg(\control, '/run');
        },
        {
			"STOPPED BACKGROUND".postln;
			~addresses[0].sendMsg(\control, '/stop');
			~addresses[0].sendMsg(\control, '/free');
        }
    );
});

~backAmpSlider = Slider.new(~window, Rect(65, 10, 50, 200))
.action_({ |slider|
	var val = slider.value;

	~addresses[0].sendMsg(\control, '/backvol', val.asFloat);
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

	~addresses[0].sendMsg(\control, '/forevol', val.asFloat);
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
		var addr = ~addresses[~whom.value];
		("//send to " ++ ~listofnames[~whom.value] ++ "!!").postln;
		~duration.get({ |durValue|
			var dens, dur = durValue, ip;
			~density.get({ |densValue|
				dens = densValue;
				addr.sendMsg(\switch, dens, dur);
				SystemClock.sched( 0.25, {
					{ ~sendNow.value_(0) }.defer; // resets sendNow
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
