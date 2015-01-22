#!/bin/sh
# these are the compilers being tests. need adjustment
# g++-4.5 g++-4.6 g++-4.7 g++-4.8 g++-4.9
# gcc-4.5 gcc-4.6 gcc-4.7 gcc-4.8 gcc-4.9 
CCs=g++-4.4 g++-5.0 gcc-4.4 gcc-5.0 clang-3.5 clang3.5++ clang-3.4 clang++-3.4 clang-3.0

# use the fastest perl available (5.22 is ~1.8x faster than 5.14)
PERL=perl5.21.8-nt@blead

# -------------------------

set -x
export TEST_JOBS=4

$PERL -e1
if [ $? -gt 0 ]; then
    PERL=perl
fi

$PERL Configure.pl --silent --debugging --cage && make -j4 -s && \
    make -j4 -s fulltest

#  this is very specific to my amd64 debian multilib setup for -m32
(
    export LD_LIBRARY_PATH=/usr/local/lib32
    $PERL Configure.pl --silent --m=32 --linkflags=-L/usr/local/lib32 && make -j4 -s smoke
    unset LD_LIBRARY_PATH
)

for args in --debugging --optimize --m=32; do
    for cc in $CCS; do
        $PERL Configure.pl --silent --cc=$cc --ld=$cc --link=$cc $args && make -j4 -s smoke
    done
done

make -j4 -s smoke VALGRIND="valgrind --suppressions=tools/dev/parrot.supp --log-file=valgrind.log"
make -j4 -s smoke VALGRIND="helgrind --suppressions=tools/dev/parrot.supp --log-file=helgrind.log"

if [ -f ../asan.sh ]; then
    ../asan.sh && make -j4 -s smoke
fi

for lib in icu libffi pcre gmp readline gettext opengl zlib core-nci-thunks extra-nci-thunks; do
    $PERL Configure.pl --silent --without-$lib && make -j4 -s smoke
done

$PERL Configure.pl --silent --with-llvm && make -j4 -s smoke

for feat in threads shared static rpath; do
    $PERL Configure.pl --silent --disable-$feat && make -j4 -s smoke
done

# gms is the default gc
for gc in ms2 ms inf; do
    $PERL Configure.pl --silent --gc=$gc && make -j4 -s smoke
done

for floatval in float double "long double" __float128; do
    $PERL Configure.pl --silent --floatval="$floatval" && make -j4 -s smoke
done

for intval in short int long "long long"; do
    $PERL Configure.pl --silent --intval="$intval" && make -j4 -s smoke
done

for opcode in int long "long long"; do
    $PERL Configure.pl --silent --opcode="$opcode" && make -j4 -s smoke
done

for flags in -DMEMORY_DEBUG -DTHREAD_DEBUG -DRESOURCE_DEBUG -DSTRUCT_DEBUG; do
    $PERL Configure.pl --silent --debugging --ccflags=$flags && make -j4 -s smoke
done
