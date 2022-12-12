Server.killAll
s.boot;
ServerOptions.devices;
s.options.inDevice_("MME : Line (Steinberg UR22mkII )");
s.meter;
Buffer.freeAll;
~myPath = PathName.new(thisProcess.nowExecutingPath);
~myPath = ~myPath.pathOnly;
 // read ONE Channe;l
f = Buffer.readChannel(s, "floot.wav".resolveRelative, channels: [0])
f.play;
b = Buffer.alloc(s, s.sampleRate * 5, 1);

(
~micBus = Bus.audio(s, 1);
~ptrBus = Bus.audio(s, 1);
)

(
SynthDef.new(\mic, {
	arg in=0, out=0, amp=1;
	var sig;
	sig = SoundIn.ar(in) * amp;
	Out.ar(out, sig);
}).add;

SynthDef.new(\ptr, {
	arg out=0, buf=0;
	var sig;
	sig = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
	Out.ar(out, sig);
}).add;

SynthDef.new(\rec, {
	arg ptrIn=0, micIn=0, buf=0;
	var ptr, sig;
	ptr = In.ar(ptrIn, 1);
	sig = In.ar(micIn, 1);
	BufWr.ar(sig, buf, ptr);
}).add;
)

(
SynthDef.new(\gran, {
	arg amp = 0.5, buf = 0, out = 0,
	atk=1, rel=1, gate=1,
	sync=1, dens=40, baseDur=0.05, durRand = 1,
	rate = 1, rateRand = 1,
	pan = 0, panRand = 0,
	grainEnv=(-1), ptrBus=0, ptrSampleDelay = 20000,
	ptrRandSamples=5000, minPtrDelay = 1000;

	var sig, env, densCtrl, durCtrl, rateCtrl, panCtrl, ptr, ptrRand, totalDelay, maxGrainDur;

	env = EnvGen.kr(Env.asr(atk, 1, rel), gate, doneAction:2);
	densCtrl = Select.ar(sync, [Dust.ar(dens), Impulse.ar(dens)]);
	durCtrl = baseDur * LFNoise1.ar(100).exprange(1/durRand, durRand);
	rateCtrl = rate * LFNoise1.ar(100).exprange(1/rateRand, rateRand);
	panCtrl = pan + LFNoise1.kr(100).bipolar(panRand);

	ptrRand = LFNoise1.ar(100).bipolar(ptrRandSamples);
	totalDelay = max(ptrSampleDelay - ptrRand, minPtrDelay);

	ptr = In.ar(ptrBus, 1);
	ptr = ptr - totalDelay;
	ptr = ptr / BufFrames.kr(buf);
	ptr = ptr % 1;

	maxGrainDur = (totalDelay / rateCtrl) / SampleRate.ir;
	durCtrl = min(durCtrl, maxGrainDur);

	sig = GrainBuf.ar(
		2,
		densCtrl,
		durCtrl,
		buf,
		rateCtrl,
		ptr,
		2,
		panCtrl,
		grainEnv
	);
	sig = sig * env * amp;
	Out.ar(out, sig);
}).add;
)

(
~micGrp = Group.new;
~ptrGrp = Group.after(~micGrp);
~recGrp = Group.after(~ptrGrp);
~granGrp = Group.after(~recGrp);
)



b.zero;
~g = Synth(\gran, [
	\amp, 0.5,
	\buf, b,
	\out, 0,
	\atk, 1,
	\rel, 1,
	\gate, 1,
	\sync, 1,
	\dens, 40,
	\baseDur, 0.05,
	\durRand, 1,
	\rate, 1,
	\rateRand, 12.midiratio,
	\pan, 0,
	\panRand, 0.5,
	\grainEnv, -1,
	\ptrBus, ~ptrBus,
	\ptrSampleDelay, s.sampleRate/3,
	\ptrRandSamples, s.sampleRate/6,
	\minPtrDelay, 1000,
], ~granGrp);

s.defaultGroup.deepFree;

