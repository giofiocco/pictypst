# PIC for typst

This is a super rough implementation of a little subset of [PIC](<https://en.wikipedia.org/wiki/PIC_(markup_language)>) for [Typst](https://typst.app/docs/) language.

## Testing:

- add `.PS ... .PE` block in test.roff
- run `perl build.pl` (it creates files in `images/`)
- update the `files-count` variable in `pictest.typ`
