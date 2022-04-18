XEROX	 System Sciences Lab
Palo Alto Research Center	 LSI Systems Area

A Hardware Model of Human Auditory Processing

Richard F. Lyon -- May 16, 1979
 DRAFT -- for Xerox internal use only -- DRAFT


file: [ivy]<Lyon>design.report


INTRODUCTION

Summarize and reference A Signal-Processing Model of
Hearing.  Auditory processing part of hearing, up to
extraction of features in the cortex, and feature
comparison.  Scope of the hardware: Cochlear mechanics,
transduction, adaptation, timbre demodulation, timbre as
image, feature measurement, distance measurement.  The value
of emulation by hardware.  This paper to document the
design.  The rest of the recognizer: pattern matching
network search, based on any of various levels of
recognition model (phonemes, words, sentences, etc.).


THE SIGNAL PROCESSING MODEL

Pre limit/compress/AGC as needed (more than the tympanic
reflex).  Cascade filterbank is an accurate cochear model.
Spatial difference is detected signal, modelling shearing
force?  Half-wave rectifier bank models hair cells.  Coupled
adaptation/inhibition AGC models ATP ion pump, ion
diffusion, lateral inhibition, and nerve adaptation.
Per-channel autocorrelation (which is beyond the cochlea)
models cochlear nuclei, etc.  Rate reduction to 60 sps
models critical rate perception.  (Oversample to 120 sps for
better time alignment accuracy).  4D display (X, Y,
intensity, time), analogy to vision, models projection on
the cortex.  Extraction of feature vectors (a more central
process) by linear feature extraction techniques models
associational cortex.  Perceptually relevant distance
measurement, to facilitate recognition, is the goal of this
design.


SOFTWARE SIMULATION

The value of software simulation before commitment to
hardware.
	Validate concepts and algorithms.
	Validate hardware design.
	Measure and document system performance (but hard to
do in non-realtime).  Valuable information gained from early
simulation efforts.
	Simulator can be tuned beyond an optimum point by
limited data.
	Speech envelope detection should be half-wave for
consistent pitch representation.
	Logarithmic compression emphasizes noisy valleys and
flattens clean peaks.
	For compression of dynamic range, a time and space
AGC is needed.
	Envelope bandwidths should be the same for all
cochlear places, not proportional to CF.
	Ear-model spectrograms still have plenty of
interesting fine time structure.  Problems with simulation
-- speed and accuracy.
	Simulation is slow (simple spectral analysis at 200
times real time with careful assembly coding).
	Accurate representation to the bit level is hard on
a word-oriented machine.
	Can't get a feel for a real system from a
non-realtime simulation.  Hardware that needs no simulation;
or special hardware as an efficient simulator of itself.


DEVELOPMENT, INTERFACE, AND TEST STRATEGIES

Interface to Alto through Auburn, or similarly to another
machine.  Use stored or real-time digital audio for input.
Slow (scope mode) Alto display of results.  Conventional
sonogram output via hardcopy is first step.  Real-time Alto
display of timbre image is next.  Integration into real-time
recognizer.


SERIAL ARCHITECTURE AND IMPLEMENTATION CONVENTIONS

Multiplexed filter architecture--over channels and
functions.  Timing and clocking conventions for both LSI and
MSI sections of serial, channel multiplexed, signal
processing components.  Conventions for specification of
function and delay of components.  LSB-time signal for word
timing, in and out.  Words of all lengths right-normalized
to LSB-time.  Counter for channel timing.  Fixed clock
cycles per word, number or channels, and clock rate (24
cycles per word, 31 channels, 15360 sps, 11,427,840 Hz
clock; or 12 cpw, 31x16 channels, 1920 sps, same clock, at
autocorrelator; or 12 cpw, 16x992 channels, 60 sps, same
clock, at DPM).  Delay always in integral bit times, LSB in
to LSB out.  Logic families: LS (or S) TTL MSI, and 4 micron
NMOS LSI (NSIL II).  LSI: Two-phase with external changes
during phase 2.  All logic inputs sampled on phase 1.
External TTL synchronizers where needed.  MSI:
Edge-triggered D-registers, clocked on early phase 2 (show
clock derivation circuit).

The entire signal processing section (everything but host
interface & such) will be implemented in an architecture
evolved from that presented by Jackson, Kaiser, and McDonald
in their 1968 paper "An Approach to the Implementation of
Digital Filters" (knowledge of their work is a prerequisite
to reading this section).  This architecture involves the
use of bit-serial arithmetic processing components, all
operating at a fixed throughput rate (words per second), and
multiplexed over several channels or functions to match
hardware rate to the signal sample rate.  In this
architecture, its is important that the throughput of an
adder be the same as that of a multiplier, which is in turn
the same as that of second-order filter section, or any
other component.  Even the delay elements (logically shift
registers) have the same throughput speed, and enough delay
to provide a word of storage per multiplexed channel.  In
general, both the bit rate and number of bits per word, and
hence the word rate, are fixed early in the design phase and
are constant throughout the system; our system is actually
divided in two parts with different word sizes, but the same
bit rate.

Jackson et.al. describe two types of multiplexing of
arithmetic hardware which is configured to look just like
the block diagram of a digital filter.  Type 1 multiplexing
means using the same filter hardware to process several
input channels identically (by providing more words of
delay, at a faster word rate, to keep the state of all the
filters separate, and interleaving the inputs from the
channels).  Type 2 multiplexing means using the same filter
hardware to implement different filters (by additionally
changing the filter coefficients during the different time
slots).  The latter technique is typically used with the
filters cascaded (by feeding the output back to the input
during some time slots), to implement high-order filters
from second-order sections.  A combination of these
techniques is also useful; for example, 4 identical channels
of 6th-order filters can be built from a second-order
section multiplexed 12 ways.  In either case, the only
special hardware needed to effect the multiplexing is a unit
delay element (enough memory to make the delay equal to the
audio sample time, or the multiplexing factor time the word
time), some simple switches on the filter inputs, and
appropriate coefficient memory.

We propose to use 24 bits per word (some of which are
redundant, for an effective 22 bit word), to operate at
11.427840 Mbps, resulting in 476.160 k words/sec.  The word
rate must equal the sample rate times the multiplexing
factor in each part of the system; for example, in the
audio-bandwidth sections, the sample rate will be 15.36
ksps, with multiplexing over 31 channels (carefully chosen
to keep the clock just less than twice the Alto clock rate).
Lower rate parts of the system will be more heavily
multiplexed.  Some later parts of the system (after much
dynamic range compression) will run with only 12-bit words,
with twice as many words per second.  The lowest-rate part
of the system will be the linear transformation and distance
measurement, at 120 sps (equal to twice the Alto video field
rate), with 12 bits per word, and multiplexed 7936 ways, for
a total 952.32 k words/sec.

This brings up another type of multiplexing, useful in low
sample rate applications, where a section configured like a
block diagram would have too high a multiplexing factor.
For example, at a multiplexing factor of 7936, if only 992
channels are needed, each multiplier, etc., can be
multiplexed over 8 different uses in the block diagram.  We
call this Type 3 multiplexing for reference.  Implementation
of this type of multiplexing requires more switched data
paths and fewer arithmetic units, such that the hardware
does not look like a block diagram of the function
implemented.

In a general purpose computer, a single multiplier is used,
with flexible programmable data paths, for all possible
appearances of a multiplier in a block diagram.  We avoid
this concept religiously to keep data paths and control
simple, and to simplify exploitation of parallelism.  Clean
separation of data and control also makes pipelining work
out much more easily.

System-wide timing conventions are needed in order to start
to design a system of the magnitude of the speech processor.
The basic approach adopted for this system is to have
system-wide synchronous clocks at the bit rate, and a
central time counter that keeps track of bits, words, etc.
on a cycle equal to the slowest period of interest in the
system.  For example, with a bit clock of 11.427840 MHz, a
19-bit counter is used for a total cycle of 1/30 second
(Alto frame rate).  The counter is organized as a 12-counter
for bits of a short word, 2-counter to reach bits of a
24-bit word, 31-counter for words within an audio sample
time, and 9 more bits (512-counter) to reach the 30 Hz rate.
The 19 counter output bits Time.00 through Time.18 are used
to address various ROMs and PLAs to generate timing signals
and coefficients for all the filters, data-path switches,
etc.  This control section may be thought of as a
microprogram store with no conditional branching, a very
wide control word output, and a 380928-step linear program.
The actual encoding will be much more efficient than this,
since the control and coefficient bits for the high-rate
sections do not depend on the high-order Time bits.

The synchronous clocking scheme will include several
versions of the bit clock, provided to accomodate the
different types of technology from which the system will be
constructed.  These technologies and clock types are (1)
LSTTL with positive edge triggered clocking, and (2)
high-performance NMOS (HMOS or NSIL-II) with nonoverlapping
two phase clocking.  The relative clock phasing and data
timing across technology boundaries will be fixed
system-wide.  In the NMOS part, the first clock gate
encountered by a signal entering a subsystem will be
designated Phase1, which will be high (open, on, or 1)
during the latter (low) part of the TTL clock cycle, when
data bits are stable.  Phase 2 will be the last clock gate
encountered by a signal leaving an NMOS subsystem, and it
will be timed such that output data, stable during Phase1,
meets the TTL setup and hold requirements.

In many cases, it is convenient to generate control signals
for each functional unit locally, rather than import them
from the central control section.  Most arithmetic
processing units need only clock, data, and one control
input to identify the first bit of a new word.  Thus, we
adopt a convention to use an 'LSBtime' signal wherever
applicable; this line is to be asserted to identify the
first (least significant) bit of a new word.  Units that
accept this control input should also produce a delayed
version of it to identify the LSBtime of their output.  Thus
most data paths from one unit to another carry their own
timing information, and units can be arbitrarily
interconnected without concern about connection to the
central controller.  Still, the designer must take care to
assure that merging signal paths (e.g. at an adder) and
loops (e.g. in a recursive filter) have the correct total
delay (or a special stretchable queue could be designed to
automatically adjust delays).

Some units, such as multipliers, may take two input operands
of different lengths.  In such cases, the convention is that
both operands are aligned to the same LSBtime signal (words
of different lengths are right-adjusted).  For short words,
the bit slots between the sign bit of one word and the LSB
of the next should generally be filled with sign extensions.
Values of words of any length can be described by their
two's-complement binary integer interpretation, written in
binary, octal, or decimal.

Of the 24 (or 12) clock cycles per word, the first
(coincident with LSBtime) will be the least significant bit,
the 24th will be unused (may need to be zero for the
convenience of multipliers), and the 23rd is a sign
extension (copy of the 22nd).  Thus only 22 bits are
independent, and numbers from -221 to +221-1 (about
-2,000,000 to +2,000,000) can be represented.  The
operations of adding two numbers together, scaling a number
up by a factor of two, or multiplying by a factor between
one and two in magnitude can cause a detectable overflow by
creating a number in which the sign extension bit is not
equal to the sign bit; in such a case, the sign extension
bit is the result's correct sign, and the number should be
replaced by a legal value with the correct sign.


SYSTEM PARTITIONING AND BLOCK DIAGRAMS

Top view: the central interface box concept.  Acoustic
Analyzer:
	Filterbank.
		Bandpass filters.
		Detectors.
		Lowpasss.
		Decimators.
		Programmable coefficient memory.
	Adapter.
		Variable gains.
		AGC filters.
		Programmable coefficient memory.
	Autocorrelator.
		Delay filters.
		Correlator multipliers.
		Lowpass smoother.
		Decimator.
		Programmable coefficient memory.
	Timre image display.  Pattern Matcher:
	Transformation.
		Input circulator.
		Multiplier/accumulator.
		Programmable coefficient memory.
	Euclidean distance unit.
		Input circulator.
		Difference.
		Squarer.
		Accumulator with limiter.
	Dynamic Programming Machine.
		Add/Compare/Select unit.
		State metric memory.
	Pattern Memory.


THE BUILDING BLOCKS -- LOGIC SPECIFICATION

Adder.  Multiplier.  Double and Complex Multipliers.
Scaler.  Squarer.  Coefficient Memory.  Overflow Limiter.
Rectifiers, half-wave and full-wave.  Delays.  Interchannel
connection.  Multichannel fanout.  Multichannel summation.
Sample rate reduction.  Sum-and-dump filter.  S/P and P/S
Auburn interfaces.


THE BUILDING BLOCKS -- LSI AND MSI DESIGNS

same blocks as above.


NUMERICAL PARAMETERS

First pole-zero section: preemphasis, or whatever.  CF and Q
of poles and zeroes of 31 cochlear sections.  Unity DC gain
adjustments of cochlear sections.  Worst-case signal
amplitudes before and after rectifiers and adapter.  Filter
coefficients, time constants, gains, scaling, etc.
Calculated performance curves, etc.


IMPLEMENTATION DETAILS

Pointers to supplementary artifacts: drawings, lists, design
files.  Record of progress and problems.  this report
started: Dec 13, '78.



EXPERIMENTAL RESULTS

Does it act like an ear?

