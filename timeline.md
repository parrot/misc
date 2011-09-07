Dukeleto asked me to put together a general timeline or checklist of changes
that we need to make to Parrot, organized by size and scope of the work, the
effort required, and the relative ordering that (I think) is a pretty good way
to go about it.

This isn't an "official" timeline or anything like that. It's just my own
personal idea for what we should probably be doing, and how hard it will be to
do. The items below are listed in a quasi-chronological order in the sense
that, left to my own devices, I will probably approach these problems myself
in this order. Other people are welcome to tackle things in any order, so
long as dependencies are met.

[from Pm:  I've updated the original gist with Rakudo-related notes below.]

### GC: Convert to Precise GC

* Extent of change: small
* Effort required: moderate
* Relative priority: moderate

We need to convert our GC to be precise. We have some good ideas floating
around for how to do that, and implementation of the code won't be hard. What
will be challenging is tracking down places where PMCs are used on the stack
and converting those to use a new API/macro to be anchored. This could
have a positive impact on performance and will help make things more
thread-safe when we get to tasks that require that.

* Upgrade effort for HLLs: minor (fixes to C code)
* Benefits for HLLs: Better GC performance
* Benefit to Rakudo: Better performance
* Rakudo priority: high if it results in performance improvements, low otherwise

### Packfiles: Rewrite packfile loading

* Extent of change: large
* Effort required: large
* Relative priority: large

See my blog post about the problem with Subs for examples:

http://whiteknight.github.com/2011/08/15/sub_problems.html

We need to rip a hell of a lot of stuff out of the Sub PMC, make IMCC smarter
about how it serializes some things (like NameSpaces and MultiSubs) and make
the packfile loader a hell of a lot smarter about how things get unpacked.
Fix NameSpace to not be terrible. Remove all sorts of extra PIR flags like
:nsentry, :anon, :multi, etc.

This is a *very* big project, but represents an extremely central portion of
Parrot. User code is going to be forced to pick up the slack from all the
magic we're going to be removing from key systems. This is going to require
changes to Winxed and NQP to keep code working.

* Upgrade effort for HLLs: Need to change code generation to avoid using removed
    flags. Need to generate code to explicitly add Subs to NameSpaces or to
    MultiSubs if desired.
* Benefits for HLLs: Improved packfile loading performance. Improved NameSpace
    PMC performance. Decreased binary code size overall. Better control over
    how Sub PMCs are used and stored in the system.
* Benefit to Rakudo: Improved packfile loading (low importance) and loading 
    size (low-medium importance).  The others are non-benefits to Rakudo.
* Rakudo priority: low

### PCC: Redo PIR ops for call conventions

* Extent of change: moderate
* Effort required: high
* Relative priority: moderate

See my blog post series about redoing PCC (first is most important):

http://whiteknight.github.com/2011/05/11/pcc_refactors_and_improvements.html
http://whiteknight.github.com/2011/05/10/timings_vtable_overrides.html
http://whiteknight.github.com/2011/05/12/pcc_refactor_timings.html

We need to replace the get_params, set_args, set_returns and get_results ops
with a fast way to access the current CallContext and specialized ops for 
reading named/positional values from the context. We have most of the ops we
would need already. What we don't have yet are the necessary slice/splice ops
for doing :slurpy and :slurpy/:named.

There are real performance benefits to be had. This change is going to
primarily require changes to IMCC to generate new sequences of ops. It could
lead to some significant improvements there. User code that uses PIR syntax
for sub/method calls and .param syntax for parameters should be safe. Lots of
tests written in PASM are going to die.

* Upgrade effort for HLLs: None (changes are internal to IMCC only)
* Benefits for HLLs: Improved invoke performance for all PIR->PIR calls.
    Improved performance for generating backtraces. Easier to build tools like
    debuggers and static analyzers. Improved PBC disassembly potential. Ability
    to fetch parameters lazily.
* Upgrade effort for Rakudo:  According to whiteknight, nil.
* Benefit to Rakudo:  Improved invoke performance.  (We already do lazy 
    parameter fetching, although this might give us the ability to do more.)
* Rakudo priority:  high if it results in performance improvements, low otherwise

### Packfiles: Debugging

* Extent of change: low
* Effort required: moderate
* Relative priority: moderate

* Upgrade effort for HLLs: none.
* Benefits for HLLs: New tools for debugging and analysis, and the possibility
    to make more new custom tools.
* Rakudo priority:  high if it results in performance analysis, moderate otherwise

### Interp: Sandboxing

* Extent of change: low
* Effort required: low
* Relative priority: high

I've got a few ideas about how to implement basic sandboxing that need to be
blogged about more, designed, and prototyped.

* Upgrade effort for HLLs: minor (PIR code and above will be unchanged. Some
    C-level APIs will change. New sandboxing/security standards will need to
    be followed internally.)
* Benefits for HLLs: Addition of basic sandboxing and security features. 
* Benefit to Rakudo:  Long term benefit, possibly -- short term benefit, zero.
* Rakudo priority: zero.

### OO: 6model

* Extent of change: large
* Effort required: large
* Relative priority: high

Need to merge 6model ideas into the Parrot object model at the ground up. Need
to completely redo some fundamental parts of the system, such as PMCs, type
bootstrapping at startup, vtables, etc. 

* Upgrade effort for HLLs: Unknown/variable. The first attempt will try to be
    compatible at C and PIR levels with the 6model version being used in NQP.
    NQP will need to be changed to use the version built-in to Parrot instead
    of building and linking its own. Languages running on NQP should be
    mostly unaffected.
* Benefits for HLLs: Better overall performance of objects and data operations,
    especially as integration improves. Far better interoperability between
    6model and Class/Object for systems that want to use both. Possibly
    improved libparrot startup time.
* Benefit to Rakudo:  Rakudo would again be able to better use non-Rakudo
    and non-NQP libraries.
* Rakudo priority: low

[Note from Pm and jnthn:  "better interoperability with Class/Object" is a non-starter for us.  Class/Object needs to die, it's terribly inefficient and 6model can do everything it does (only better).]

### Exceptions: Cleanup and Optimizations

* Extent of change: high
* Effort required: moderate
* Relative priority: high

See some blog posts on the subject:

http://whiteknight.github.com/2011/01/26/exception_handler_redux.html
http://whiteknight.github.com/2010/02/24/pdd23_exceptions_critique.html
http://whiteknight.github.com/2010/02/23/parrots_exceptions_system.html

The exceptions subsystem is a mess and needs to be re-thought. We need to
remove the scheduler from the lookup for handlers. We need a lot of stuff,
and need to keep a close eye on performance, especially if exceptions are
going to continue to be used for normal control flow.

* Upgrade effort for HLLs: none (first wave of changes are internal only)
* Benefits for HLLs: Better performance for exceptions and handlers. Possibly
    better able to use custom subclasses for both.
* Rakudo priority: high if it results in better performance, low otherwise.

### Interp: Make Thread-Safe

* Extent of change: moderate
* Effort required: low
* Relative priority: high

* Upgrade effort for HLLs: Minor (some C code which pokes into Interp* directly
    will need to be changed. PIR code should be unaffected)
* Benefits for HLLs: Nothing immediate
* Rakudo priority: low

### Threads: Rip Out and Replace

* Extent of change: moderate
* Effort required: moderate
* Relative priority: moderate

* Upgrade effort for HLLs: None (unless you are using threads, or are relying
    on vestigial C-level details of the threading system)
* Benefits for HLLs: Modest performance improvements. Improved security
    and separation between interps at the C level.
* Rakudo priority: low

### IO: Proper Asynchronous IO

* Extent of change: low
* Effort required: moderate
* Relative priority: low

* Upgrade effort for HLLs: None (but can add AIO features as desired)
* Benefits for HLLs: new IO features
* Rakudo priority: high

### MMD: Napalm Death

* Extent of change: large
* Effort required: moderate
* Relative priority: low

We need to stop referring to Class objects by string name. Not all of them can
be stringified and some classes aren't known at compile time. We need to be
able to associate a Sub with more than one multi sigs (which means not storing
multi_sig in the Sub PMC). We need to create Multis at compile time or at load
time in user :load subs, not in the packfile loader.

We need to expand MMD to be able to handle the full range of PCC capabilities.
We should be able to specify :optional/:opt_flag, :slurpy, and :named
varieties in multisigs so we can make more intelligent dispatches.

We should be smarter about lookups and cacheing. We probably would like to
move to a DAG to search for candidates, or something better than an in-place
manhattan sort. We would probably like to do some kind of call-site caching,
although that may want to wait until JIT.

In short, the system needs to be redone from the ground up.

* Upgrade effort for HLLs: If you are using Parrot's MMD from PIR code, you
    will need to write code to add Subs to MultiSubs explicitly. If you are
    using NQP or Winxed, those code generators will be updated to do the right
    thing. If you are not using Parrot's built-in MMD, you will be unaffected
* Benefits for HLLs: Better performance of MMD system. More feature-full
    default MMD system. More control over how Subs are associated with
    signatures. The ability to use Subs with more than one signature without
    cloning.
* Benefit to Rakudo:  Zero, as Rakudo and NQP already have their own type-based MMD.
* Rakudo priority: zero.

[Pm:  Also note that "write code to add Subs to MultiSubs explicitly" is
definitely headed in the wrong direction -- it takes what is currently a compile-time
operation and turns it into a runtime-startup operation, unless there's a
compile-time mechanism to do the explicit adds.]

### PCC: Inside-Out Contexts

Details to come.

### Exceptions: Expose ExceptionHandler lookup and dispatch

* Extent of change: moderate
* Effort required: moderate
* Relative priority: low

* Upgrade effort for HLLs: Unknown. New interface may be same, old interface
    may be kept for backwards compatibility. Additional PIR (or new ops) might
    need to be generated for exception throw and catch. The basic common
    case should probably be unchanged.
* Benefits for HLLs: Improved control over exception dispatch. Improved
    ability to subclass Exception and ExceptionHandler. Ability to use
    features like MMD with exception dispatch. Simplified exception resume.
* Benefits for Rakudo:  Same as for HLLs above.
* Relative priority: low to medium

### Strings: None

### Embedding API: None

### NCI: None