 #!/bin/sh
without="--without-icu --without-gmp --without-libffi --without-pcre --without-opengl"
for f in float __float128 "long double" double; do
  make -s archclean; perl Configure.pl --floatval="$f" $without --m=32 >/dev/null && \
    make -s parrot && echo $f && prove -v t/native_pbc/number.t; 
done
