#import "PIC.typ": pic, read_roff_file

#figure(block(
  stroke: .5pt,
  inset: (x: -7cm, top:-1cm, bottom: -20cm),
  clip: true,
  image("test-0.png")
))
#pic(read_roff_file("test.roff").at(0), debug:true)

*Objects* are _box_, _line_, _arrow_, _circle_, _ellipse_, _arc_, _splines_ and _block composition_.
Box, circle and ellipse are *closed*; lines, arrow, arc and splines are *open*.
Arc changes the direction accordingly with its shape, `cw` (clockwise) can be specified as modifier.

#figure(table(columns: (1fr,)*2, stroke:none, 
  [], [size modifier],
  [box], [widht, height],
  [circle], [rad, diam],
  [ellipse], [widht, height],
  [arc], table.cell([rad])
))

The `same` kw give the object the same size as the previous onoe of its type.
Diagonal lines with `line up left 1.5`.

`dashed` or `dotted` change the line style from solid, circle and ellipse can be dashed or dot, in some cases also splines can be dashed.
The number after the modifier is the interval between dashes or dots.

`rad` modifier on box changes the corners radius.

arrowhead ...

`thickness`

`invis` to make the object invisible.

`fill[ed]`for close object followed by the value (0 - 1 for grayscale value).
`solid` is equivalent to fill with the darkest value.

`ljust`, `rjust`, `above`, `below` (or combinations of those) changes the text positions.

`last` can be followed by box, circle, ellipse, line, arrow, spline or [], can be specified `3rd last ellipse`, `1st last ...` or `'expr'th last ...`.
`nth` numbers can be used without last.

`A: A + (1,0)` is valid.

text alone is valid

`here` refers to the current location.

cartesian system with `(0,0)` at the lower left corner with x and y increasing up and right.

`.ne` etc of circle and ellipse are on the figure.

For open objects there are `.center` `.start` and `.end`.

To combine location: 
- vector sum: `last box .ne + (1,0)`
- interpolation `1/3 of the way between ... and ...` (fraction or number) or `1/3 <..., ...>`
If A and B are points (A,B) is the point with the x of A and the y of B

Locations are used with `at`, `from`, `to` and `with`,
- `at`: for close obj tells the center, for open obj tells the starting point.
- `to` alone: has effect only on as move destination.
- `from` alone: as `at`.
- `from` - `to`: with line, arrow or arc to tell the starting and ending point.
- `with ... at ...`: allows to specify the attachment point

When drawing lines between circles and cannot be able to spec a specific point on the circunference can use `chop` so lines from the center will start from the first point on the circumference (the arrowhead is move accordingly), it shorten both ends by value hold by circlerad, with `line ... chop l1 chop l2` you can specify how much to short.

Brace grouping, after the closing brace the current position and direction are restored.

Block composite (with square braces) threated as an object with the size of the bounding box.
All variable assingments done in the block are undone after it, to use them `last [].name`, those can be used with `with`.
Can be nested, the last kw refers to the outermost.

`.wid`, `.ht`, `.rad` are valid

Macros: `define name { body }` or with arguments `name(arg1, ..., argn)` that can be used in the body with `$n`, macros can be undefined with `undef`.

import ...

forloop ...

scaling ...

eqn ...
