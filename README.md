## Soundcloud Import

Import podcasts from SoundCloud using the '/tracks' API (https://developers.soundcloud.com/docs/api/reference#tracks).

Developed in conjunction with the London School of Hygiene and Tropical Medicine (http://www.lshtm.ac.uk).

In order to use this plugin you will need to register for a Client ID http://soundcloud.com/you/apps

Example usage:

```
$ cat > soundcloud.ids # create list of soundcloud user ids
bmjpodcasts
http://soundcloud.com/theeconomist
22699976
$ bin/import foo archive SoundCloud soundcloud.ids --user admin --enable-web-imports --arg client_id=12345
```

To see whats going on in greater detail use --scripted and --arg debug=1.

By default if a podcast has already been imported, it won't be imported again.

To force the plugin to update existing podcasts, run:

```
$ bin/import foo archive SoundCloud soundcloud.ids --user admin --enable-web-imports --verbose --arg client_id=12345 --update --arg update=1
```

(Yes, I know, having to specify --update and --arg update=1 isn't ideal :-)

### Embedded player

Add the following to your archives/foo/cfg/citations/eprint/summary_page.xml:

````
  <epc:if test="source and substr(source,0,34) = 'https://api.soundcloud.com/tracks/'">
    <iframe width="100%" height="166" scrolling="no" frameborder="no" src="https://w.soundcloud.com/player/?url={source}&amp;color=7339a4&amp;auto_play=false&amp;hide_related=true&amp;show_comments=false&amp;show_user=true&amp;show_reposts=false"></iframe>
  </epc:if>
````

See https://soundcloud.com/pages/embed for further options.
