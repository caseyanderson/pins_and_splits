## ////// PINS & SPLITS!!!!
Mark Trayle, 2014

In *pins&splits* players alternate between a single 'background' sound and a set of one or more 'foreground' sounds. A player's foreground sound can be triggered by another player at any time, causing the background sound to stop. After a relatively short period of time, say, in the 1 - 10 second range, the foreground sound stops, and the background sound starts again.

Players have no control over their own foreground/background switching, that's done by other players in the group.

Players do have control over certain parameters of the sounds they make.

My intention is to create quickly changing instrumental groupings and sonic textures through a limitation of sonic material and the interruption of the performers' musical flow.

### Messaging and Musical Flow

This section is primarily intended for the laptop players. It’s rather technical.

Start by making the background sound. When you receive an OpenSoundControl message of the form… `/<yourname> /<sender> /switch /density <float 0…1> /dur <float 1…10>`

Check to make sure that `<yourname>` identifies you, and if it does, start the foreground sound and apply the `/density` value to it in a way you deem appropriate. After `/dur` expires the foreground sound should stop and you should return to the background sound. Send `/switch` messages to anyone in the group at any time you wish. You should have direct control of the timing of the messages and the value of the `/density` and `/dur` parameters, i.e., a performer interface rather than an algorithm.

### Notes and a Variation (for all)

* Background sounds should be relatively quiet (p-pp) and static.
* Foreground sounds should stand out from the background.
* You could decide to pick a different range of foreground duration, as the occasion sees fit.
* You can react to /switch messages with as many different sounds, sound-events, sound-aggregates, etc., as you like.

### Specifics for Laptopists

You’re free to use any sounds you like. However, keep in mind that this should be a very active piece, I suggest avoiding sounds that take a long time to develop, anything too “drone-y”, for your foreground palette. Drones are fine for background sounds. Samples are okay, maybe even encouraged as the rest of the concert contains 0% sampled material. Shorter samples would be better, and they can always be stretched out. And samples would be better in the foreground palette.

### Specifics for Instrumentalists

You'll be alternating between background and foreground sounds as well. In
front of you will be an iPad (or similar) on a music stand. You'll know
when to switch from background to foreground when you see something like this…

<insert image>

… on the screen in front of you.

You’ll only receive the image if it was meant for you (as in "Messaging and Musical Flow" above).
