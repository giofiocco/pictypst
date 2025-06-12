test.png: test.roff
	groff -p -t -ms $< -Tps > $<.ps
	magick $<.ps $@
	# groff -p -t -ms $< -Tascii

