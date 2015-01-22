 #!/bin/sh
without="--without-icu --without-gmp --without-libffi --without-pcre --without-opengl"
for f in float __float128 "long double" double; do
  make -s clean archclean; perl Configure.pl --floatval="$f" $without --m=32 >/dev/null && \
  make -s -j4 parrot parrot_config pbc_dump && echo $f
  tools/dev/mk_native_pbc --noconf
done
