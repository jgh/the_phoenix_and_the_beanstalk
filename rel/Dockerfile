FROM msaraiva/alpine-elixir-base:18.0

RUN apk --update add erlang-sasl && rm -rf /var/cache/apk/*

# The following two  ENV must  match  the app: and  version: configuration items  in the mix.exs file.
ENV APP_NAME the_phoenix_and_the_beanstalk
ENV APP_VERSION 0.0.1

ENV PORT 4000

#RELX  Dynamic configuration
# https://www.rebar3.org/docs/releases
ENV RELX_REPLACE_OS_VARS true

#Changing  to  not use variable for  eb
#EB parses the  EXPOSE  value  in this file and  uses  to generate  nginx config.  It  can't  be  a ENV  variable
EXPOSE 4000

ADD $APP_NAME/$APP_NAME-$APP_VERSION.tar.gz  /$APP_NAME

#Use alpine crypto lib. to avoid error message about  mi  ssing openssl. Asuming the .so is different when compiled for alpine
RUN rm -rf  /$APP_NAME/lib/crypt0-3.6  && cp  -r  /usr/lib/erlang/lib/crypto-3.6 /$APP_NAME/lib
#Update script  to point  to container's  version of  ERTS
RUN sed -i s/ERTS_VSN=.*/ERTS_VSN=\"7.0.2\"/   /$APP_NAME/bin/$APP_NAME

CMD trap exit TERM; /$APP_NAME/bin/$APP_NAME foreground & wait
