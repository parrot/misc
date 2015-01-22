 #!/bin/sh
conf="--without-icu --without-gmp --without-libffi --without-pcre --without-opengl"
for f in float __float128 "long double" double; do
  make -s clean archclean 2>/dev/null
  echo perl Configure.pl --floatval=\'$f\' --cc=\'ccache cc\' --ld=\'ccache g++\' --link=\'ccache g++\' $conf $*
  perl Configure.pl --floatval="$f" --cc='ccache cc' --ld='ccache g++' --link='ccache g++' $conf $* >/dev/null && \
    make -s parrot && echo $f && prove -v t/native_pbc/number.t; 
done
