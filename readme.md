
Scrive Petitions
----------------

Quick and dirty prototype/UI mockup.

Installation
============

If you do not have Bundler installed, do this:

    gem install bundler

Get the code and install dependencies:

    git clone https://github.com/martineriksson/scrive-petitions.git
    cd scrive-petitions
    bundle install

Run the web app:

    rackup


Deploy to Heroku
================

Before deploying for the first time:

    git remote add heroku git@heroku.com/scrive-petitions.git

After that, re-deploy by doing:

    git push heroku master
