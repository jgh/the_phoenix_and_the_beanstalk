# ThePhoenixAndTheBeanstalk

This is a series of  notes taken as I deploy a Phoenix application to a docker container running on AWS Elastic Beanstalk.


##Prerequisites
  1. [Phoenix](http://www.phoenixframework.org/)   (I'm using 0.17 )
  2. [git](https://git-scm.com/)
  3. [EB CLI](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html)
  4. An  [AWS](https://aws.amazon.com/)  account
  5. [Docker](https://www.docker.com/) (if you  want to test the container locally)

## Create a  new  phoenix application

```
$mix phoenix.new the_phoenix_and_the_beanstalk
$ cd  the_phoenix_and_the_beanstalk/
$ mix phoenix.server
```

## Create  git  repo

```
$git  init
```

## Create a  EXRM release

Install Exrm, follow the [phoenix  deployment guides](http://www.phoenixframework.org/docs/advanced-deployment).

I used '{:exrm, "~> 0.15.3"}' I found that some versions didn't create the  tar.gz file correctly which caused the docker build not to work. The ADD command just copied the archive and didn't expand  it.

The container  we will use contains an ERTS  to  lets  exclude  it from our release
Create a file called rel/relx.config with this content: {include_erts, false}.

$MIX_ENV=prod mix  release

We now have a release package in:
rel/the_phoenix_and_the_beanstalk//the_phoenix_and_the_beanstalk-0.0.1.tar.gz

```
  cache_static_manifest: "priv/static/manifest.json",
  server: true
```
## Docker file
Now we  need  a  docker  file  to  deploy  our  app  to  EB.  I have placed mine in the  rel directory. This is the  Dockerfile  used for  EB,  this  way if  you need  another Dockerfile for dev  for  example this can be placed  in the root project directory.

This Dockerfile uses [Alpine Linux](http://alpinelinux.org/),  it  is  adapted  from Marlus Saraiva's  excellent [docker alpine  examples](https://github.com/msaraiva/docker-alpine-examples/tree/master/hello_phoenix)

To  use it you  will  need  to update the  APP_NAME  and APP_VERSION environment propertie to  match  your application.

There are  a  few points  to  note  in the file

You can not use a ENV variable in  the EXPOSE command. EB parses the  EXPOSE  value  in this file and  uses  to generate  nginx config. You will get  a  nginx  error.
```
EXPOSE 4000
```
Add the release file  we just craeted.
```
ADD $APP_NAME/$APP_NAME-$APP_VERSION.tar.gz  /$APP_NAME
```

Now I  had  to  do  so  funky stiuff  to  get it to  work for  me.

Use alpine crypto lib. to avoid error message about  missing openssl. I  suspect the the .so  used  by  the library is different when compiled for alpine  compared  to my dev  environment  (Ubuntu).
```
RUN rm -rf  /$APP_NAME/lib/crypt0-3.6  && cp  -r  /usr/lib/erlang/lib/crypto-3.6 /$APP_NAME/lib
```

Update the  generated script  to point  to container's  version of  ERTS. This  is  a symptom  of my dev  environment  (has ERTS  in 7.0)  and  the ERTS in  the Docker  container  having a  different path
```
RUN sed -i s/ERTS_VSN=.\*/ERTS_VSN=\"7.0.2\"/   /$APP_NAME/bin/$APP_NAME
```

You can test locally if you have  docker installed:
```
$MIX_ENV=prod mix release
$sudo docker build -t the_phoenix_and_the_beanstalk  ./rel
$sudo docker run --rm -it -p 4000:4000  the_phoenix_and_the_beanstalk
```
or to get to a shell in the container
```
$sudo docker run --rm -it -p 4000:4000  the_phoenix_and_the_beanstalk /bin/sh
```

##Set up  our  Elastic Beanstalk environment

```
$eb init
```
eb init thinks you are using nodejs (because of brunch I suspect). Select No and then choose Docker.

See the [configure  the  EB CLI](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html)


Next [create  a elasticbeanstalk environment](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-getting-started.html#ebcli3-basics)
```
$eb create
```
The deployment will fail  at  this  point,  don't  worry this is ok.  

By  default  EB  deploy will upload  the  source  code  from the latest  git  commit. This is not what we want,  fortunately  you can configure it  to  [deploy a  zip  file](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html#eb-cli3-artifact) instead.

#Create zip for EB  deployment
To create this  zip  lets  create  a  mix  task.

To create a  zip  file  easily create a  mix  the_phoenix_and_the_beanstalk
Create:  lib/mix/tasks/
and  copy lib/mix/tasks/eb_zip_release.ex from this  repository.

Creates  a  zip file  in  the  rel director for  upload to  Amazon Elastic Beanstalk

#Update the elasticbeanstalk config to deploy our zip.
Update  .elasticbeanstalk/config.yml
Add the  following (replacing the application name  and  version):
```
deploy:
  artifact: rel/#{name}-#{version}.zip
```
#Create  the release and  zip  for  upload
Run:
```
$MIX_ENV=prod mix do phoenix.digest, release, eb.zip_release
```

#Deploy to  elasticbeanstalk
Then deploy with
```
$eb  deploy
```

There is a  gotcha here. When  you do eb deploy it will only  upload  the zip file if there  has a commit to git since the last time eb  deploy was run. Even if you  are deploying an  artifact not your source from  git. If it does upload you will see a progress bar.






:34:03.277 [error] Could not find static manifest at "/the_phoenix_and_the_beanstalk/lib/the_phoenix_and_the_beanstalk-0.0.1/priv/static/manifest.json". k
