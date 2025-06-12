#import "@preview/tidy:0.4.3" as tidy
#import "PIC.typ": pic

#place(
  top + center,
  scope: "parent",
  float: true,
  text(2em)[*PIC typst*]
)

#let docs = tidy.parse-module(read("PIC.typ"))
#tidy.show-module(docs, style:tidy.styles.default)

