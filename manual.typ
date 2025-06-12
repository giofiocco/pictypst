#import "@preview/tidy:0.4.3" as tidy

#let docs = tidy.parse-module(read("PIC.typ"))
#tidy.show-module(docs, style: tidy.styles.default)
