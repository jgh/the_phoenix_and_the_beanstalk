# The Phoenix And The Beanstalk

This is a series of notes taken as I deploy a Phoenix application to a docker container running on AWS Elastic Beanstalk.

##Prerequisites
 1. [Phoenix](http://www.phoenixframework.org/)  (I'm using 0.17 )
 2. [git](https://git-scm.com/)
 3. [EB CLI](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-install.html)
 4. An [AWS](https://aws.amazon.com/) account
 5. [Docker](https://www.docker.com/) (if you want to test the container locally)

## Create a new phoenix application

```
$mix phoenix.new the_phoenix_and_the_beanstalk
$ cd the_phoenix_and_the_beanstalk/
$ mix phoenix.server
```

## Create git repo

```
$git init
```

## Create a EXRM release

Install Exrm, follow the [phoenix deployment guides](http://www.phoenixframework.org/docs/advanced-deployment).

The container we will use contains an ERTS so lets exclude it from our release
Create a file called rel/relx.config with this content:
```
{include_erts, false}.
```
And execute  the  release
```
$MIX_ENV=prod mix release
```
We now have a release package in: rel/the_phoenix_and_the_beanstalk/

Don't forget  to update the prod  config, I did.
```
 cache_static_manifest: "priv/static/manifest.json",
 server: true
```
## Docker file
Next we need a docker file to deploy our app to EB. I have placed mine in the rel directory. This is the Dockerfile used for EB, this way if you need another Dockerfile for dev for example this can be placed in the root project directory.

This Dockerfile uses [Alpine Linux](http://alpinelinux.org/), it is adapted from Marlus Saraiva's excellent [docker alpine examples](https://github.com/msaraiva/docker-alpine-examples/tree/master/hello_phoenix)

To use it you will need to update the APP_NAME and APP_VERSION environment properties to match your application.

There are a few points to note in the file

You can not use a ENV variable in the EXPOSE command. EB parses the EXPOSE value in this file and uses to generate nginx config. You will get a nginx error from  elasticbeanstalk.
```
EXPOSE 4000
```
Add the release files we just created.
```
RUN mkdir  /$APP_NAME

ADD $APP_NAME /$APP_NAME/
```
Make our script  executable otherwise  it  will fail  when  it  hits  elasticbeanstalk.
```
RUN  chmod +x /$APP_NAME/bin/$APP_NAME
```

Now I had to do so funky stuff to get it to work for me.

Use alpine crypto lib. To avoid error message about missing openssl. I suspect the the .so used by the library is different when compiled for alpine compared to my dev environment (Ubuntu).
```
RUN rm -rf /$APP_NAME/lib/crypt0-3.6 && cp -r \
  /usr/lib/erlang/lib/crypto-3.6 /$APP_NAME/lib
```

Update the generated script to point to container's version of ERTS. This is a symptom of my dev environment (has ERTS in 7.0) and the ERTS in the Docker container having a different path
```
RUN sed -i s/ERTS_VSN=.\*/ERTS_VSN=\"7.0.2\"/
  /$APP_NAME/bin/$APP_NAME
```

You can test locally if you have docker installed:
```
$MIX_ENV=prod mix release
$sudo docker build -t the_phoenix_and_the_beanstalk ./rel
$sudo docker run --rm -it -p 4000:4000 the_phoenix_and_the_beanstalk
```
or to get to a shell in the container
```
$sudo docker run --rm -it -p 4000:4000 \
   the_phoenix_and_the_beanstalk /bin/sh
```

##Set up our Elastic Beanstalk environment

```
$eb init
```
eb init thinks you are using nodejs (because of brunch I suspect). Select No and then choose Docker.

See the [configure the EB CLI](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html)

Next [create a elasticbeanstalk environment](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-getting-started.html#ebcli3-basics)
```
$eb create
```
This will  take  you through  the  options required when  creating and  environment.
The deployment will fail at this point, don't worry this is ok.

By default EB deploy will upload the source code from the latest git commit. This is not what we want, fortunately you can configure it to [deploy a zip file](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb-cli3-configuration.html#eb-cli3-artifact) instead.

Alternatively  you  can  specify all the options with  the command
```
$eb create  the-phoenix-and-the2 \
  --cname the-phoenix-and-the2 \
  --platform docker-1.6.2 \
  --region ap-southeast-2 \
  --database \
  --database.engine postgres \
  --database.instance db.t2.micro \
  --database.username username \
  --database.password password \
  --database.size 5

```
This creates a new  enviroment  with a postgres database attached.  We  will use  that a  little later.
See http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb3-create.html

Use  ```$eb  platform list```  to  determine  the platform code to  use
http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/eb3-platform.html

##Create zip for EB deployment
To create this zip lets create a mix task.

To create a zip file easily create a mix the_phoenix_and_the_beanstalk
Create: lib/mix/tasks/
and copy lib/mix/tasks/eb_zip_release.ex from this repository.

Creates a zip file in the rel director for upload to Amazon Elastic Beanstalk

##Update the elasticbeanstalk config to deploy our zip.
Update .elasticbeanstalk/config.yml
Add the following (replacing the application name and version):
```
deploy:
 artifact: rel/#{name}-#{version}.zip
```
##Create the release and zip for upload
Run:
```
$MIX_ENV=prod mix do phoenix.digest, release, eb.zip_release
```

##Deploy to elasticbeanstalk
Then deploy with
```
$eb deploy
```

There is a gotcha here. When you do eb deploy it will only upload the zip file if there has been a commit to git since the last time eb deploy was run. Even if you are deploying an artifact not your source from git. If it does upload you will see a progress bar.

To open the application in a browser run:
```
$eb open
```

#Using an RDS database
Essentially we  now  have  a  very  complicated static website. Next  make  it  more  dynamic by connecting
our application to Amazon's RDS database service.

##Create an Ecto Model class
To test interacting with the database
```
$mix phoenix.gen.html Inventory inventory name:string quantity:integer
$vi web/router.ex
$mix ecto.create
$mix ecto.migrate
$mix phoenix.server
```

We should now have a database backed application running locally

#Create a RDS instance
You can  skip  this  step  if  you specified the database options  to  ```eb create ``` when  creating  the eb  environment.

Open up the console.
```
$eb console
```
will do the job.

Go to configuration
Scroll down to the Data Tier
And select 'Create a new RDS Database'

DB Engine: postgres

Instance type:db.t2.micro


##Update relx config
 When a release is created all the config  files are transformed into a sys.config file. This file contains Erlang terms only. If your esx config file conftins dynamic content e.g. ``` System.get_env("PORT") ``` these will be executed at the time the release is created not at runtime.

However you can make the script generated by relx replace tokens with env variables  by setting the ```ELX_REPLACE_OS_VARS=true``` env variable.
So add this to the Dockerfile:

```
ENV RELX_REPLACE_OS_VARS true
```

For more info see [RELX Dynamic configuration](https://www.rebar3.org/docs/releases#dynamic-configuration)

##Configure application to use RDS environment variables

Because we are using environment variables we can move the database configuration from config/prod.secret.esx into config/prod.esx

Update the data base config to use the RDS environment variables.

```
config :the_phoenix_and_the_beanstalk, ThePhoenixAndTheBeanstalk.Repo,
 adapter: Ecto.Adapters.Postgres,
 hostname:  "${RDS_HOSTNAME}",
 port:    "${RDS_PORT}",
 username:  "${RDS_USERNAME}",
 password:  "${RDS_PASSWORD}",
 database:  "${RDS_DB_NAME}",
 pool_size: 20

```

The tokens in the ${} will be replaced with envionment variables at runtime.

##Configure external access to database
We have a database set up now but it is empty. In order to be  able to use we  need to run the database migrations.
First of all grant access to the database from your local machine.

1. Log into RDS
1. Click Instances
1. Click on the instance
1. Details (the tab on the left with magnifying glass icon)
1. Click on the security group  with the (sg-xxxxxx)
1. go to the Inbound tab
1. Edit
1. Add Rule.
 Type = Postgres and
 Source = 'My IP'
1. Save

You  now have network access to the database from you local machine.

##Create a data migration environment
The ${} placeholders created for RELX don't work when using mix. To get around this create another mix environment.

Create config/prod_dbm.esx from the prod.esx and update the database config.

E.g.
```
# Configure your database
config :the_phoenix_and_the_beanstalk, ThePhoenixAndTheBeanstalk.Repo,
 adapter: Ecto.Adapters.Postgres,
 hostname:  System.get_env("RDS_HOSTNAME"),
 port:    System.get_env("RDS_PORT"),
 username:  System.get_env("RDS_USERNAME"),
 password:  System.get_env("RDS_PASSWORD"),
 database:  System.get_env("RDS_DB_NAME"),
 pool_size: 1

```
Create a environment source file
For an example see rds_prod_env.source

```
#These values are found on RDS console in the instance Configuration Details
#Endpoint:
export RDS_HOSTNAME=aa1i6h0jg8spac5.cjvsybyxlbrw.ap-southeast-2.rds.amazonaws.com
#Port (usually always standard postgres port 5432)
export RDS_PORT=5432
#DB Name (usually always ebdb)
export RDS_DB_NAME=ebdb
#Username:
export RDS_USERNAME=thephoenix
#Needs to be the password entered when creating the database.
echo Enter RDS_PASSWORD:
read -s RDS_PASSWORD

export RDS_PASSWORD

```

Source the file
```
$source rds_prod_env.source
```
The reason I extracted all the configuration to environment variables is so if you have the postgres client locally then test the connection like so:
```
$psql --host=$RDS_HOSTNAME --port=$RDS_PORT \
 --username=$RDS_USERNAME --password --dbname=$RDS_DB_NAME  
```
You can also use it to test running a local docker instance connecting to RDS.

##Run migrations
Execute the db migrations using the new environment
```
$MIX_ENV=prod_dbm mix ecto.migrate
```
Now if we check the database:
```
$psql --host=$RDS_HOSTNAME --port=$RDS_PORT \
 --username=$RDS_USERNAME --password --dbname=$RDS_DB_NAME  
ebdb=> \dt
        List of relations
 Schema |    Name    | Type |  Owner
--------+-------------------+-------+------------
 public | inventory     | table | thephoenix
 public | schema_migrations | table | thephoenix
(2 rows)

```
Our inventory table  has been created.

##Rebuild release

```
$MIX_ENV=prod mix do phoenix.digest, release, eb.zip_release
```

##Redploy
```
$eb deploy
```
and check out the new database backed pages

http://the-phoenix-and-the.elasticbeanstalk.com/inventory
