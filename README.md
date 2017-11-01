# nasearch-ruby

Search engine for shownotes for the [No Agenda Show](http://www.noagendashow.com/). Live at [search.nashownotes.com](http://search.nashownotes.com).

This is a Ruby on Rails + PostgreSQL rewrite of the
[original Django project](https://github.com/lifenoodles/nasearch)
which was later forked [by me](https://github.com/mcclymont/nasearch).

Rake tasks
-----------
+ shownotes:fetch Downloads any shownotes not in the database and processes them
+ shownotes:process Re-processes all shownotes already in the database

TODO
-----------
+ Consistent presentation of audio links. Sometimes they are &lt;a&gt; tags and sometimes &lt;audio&gt;
+ Add an API if there is demand for it
+ Find a way to parse shownotes prior to 489
+ Add better instructions in README to get started
+ De-duplication of topics (e.g. JCD Clips, JCD CLIPS, JCD Clip)
