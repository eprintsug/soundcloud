## Soundcloud Import

Import podcasts from SoundCloud using the '/tracks' API (https://developers.soundcloud.com/docs/api/reference#tracks).

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
