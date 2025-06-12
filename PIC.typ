#import "@preview/cetz:0.3.4": canvas, draw

#let vecsum(a,b) = a.zip(b).map(x => x.sum())

#let dir-anchor(dir) = (right:"west", left:"east", up:"south", down:"north").at(dir)
#let dirs-delta(dir) = (right: (1,0), left: (-1,0), up: (0,1), down: (0,-1)).at(dir)

#let obj-open = ("arrow", "line", "arc", "splice")
#let obj-close = ("box", "circle", "ellipse")
#let dirs = ("right", "left", "up", "down")
#let obj = (obj-open, obj-close).join()

#let checktoken(t, kind, image) = {
  assert(type(t) == array and t.len() == 2)
  return t.first() == kind and t.last() == image
}

#let pop-loc(tokens) = {
  let t = tokens.pop()
  let loc = (name: none, rel:none, mod:none)
  if t.first() == "id" {
    loc.name = t.last()
  } else if checktoken(t, "kw", "last") {
    t = tokens.pop()
    assert(t.first() == "kw")
    assert(t.last() in obj-open or t.last() in obj-close)
    loc.rel = (n:-1, obj:t.last())
  } else if t.first() == "nth" {
    let n = t.last()
    if checktoken(tokens.last(), "kw", "last") { tokens.pop(); n *= -1 } else { n -= 1 }
    t = tokens.pop()
    assert(t.first() == "kw")
    assert(t.last() in obj-open or t.last() in obj-close)
    loc.rel = (n:n, obj:t.last())
  } else {
    panic("")
  }
  if tokens.len() > 0 {
    if tokens.last().first() == "dot-corner" {
      loc.mod = tokens.pop()
    } else if tokens.last() == ("op", "+") {
      tokens.pop()
      assert(checktoken(tokens.pop(), "op", "("))
      t = tokens.pop()
      assert(t.first() == "num")
      let x = t.last()
      assert(checktoken(tokens.pop(), "op", ","))
      t = tokens.pop()
      assert(t.first() == "num")
      let y = t.last()
      assert(checktoken(tokens.pop(), "op", ")"))
      loc.mod = ("sum", (x,y))
    }
  }
  assert(loc.name != none or loc.rel != none)
  return (loc, tokens)
}

#let parse_statement(tokens) = {
  tokens = tokens.rev()
  let label = if tokens.last().first() == "label" { tokens.pop().last() } else { none }
  let command = if tokens.last().first() == "kw" {
    tokens.pop().last()
  } else {
    panic("not a command", tokens.last())
  }

  let statement = (command:command, text:(), dirs:(), label:label, at:none, from:none, to:none, with:none, rem:(), mod:())

  while tokens.len() > 0 {
    let t = tokens.pop()
    if t.first() == "str" {
      statement.text.push(t.last())
    } else if checktoken(t, "kw", "at") {
      (statement.at,tokens) = pop-loc(tokens)
    } else if checktoken(t, "kw", "from") {
      (statement.from, tokens) = pop-loc(tokens)
    } else if checktoken(t, "kw", "to") {
      (statement.to, tokens) = pop-loc(tokens)
    } else if checktoken(t, "kw", "with") {
      assert(tokens.len() > 0)
      t = tokens.pop()
      assert(t.first() == "dot-corner")
      statement.with = t.last()
    } else if t.first() == "kw" and t.last() in dirs {
      statement.dirs.push((t.last(), 1))
    } else if checktoken(t, "kw", "dashed") {
      statement.mod.push("dashed")
    } else if t.first() == "arrow-kind" {
      if t.last() == "<->" {
        statement.mod.push("->")
        statement.mod.push("<-")
      } else {
        statement.mod.push(t.last())
      }
    } else {
      statement.rem.push(t)
    }
  }

  if statement.command == "arrow" and not "->" in statement.mod and not "<-" in statement.mod {
    statement.mod.push("->")
  }
  if statement.command in dirs and statement.text.len() > 0 {
    panic(statement.command, "cannot have text")
  }
  statement
}


#let compute-loc(loc, labels, history) = {
  let (x,y,w,h) = if loc.name != none {
    labels.at(loc.name)
  } else {
    history.at(loc.rel.obj).at(loc.rel.n)
  }
  if loc.mod == none { return (x,y) }
  if loc.mod.first() == "dot-corner" {
    let cor = loc.mod.last()
    if cor in ("start","end") { panic("todo") }
    x += if "w" in cor { -w/2 } else if "e" in cor { w/2 } else { 0 }
    y += if "s" in cor { -h/2 } else if "n" in cor { h/2 } else { 0 }
  } else if loc.mod.first() == "sum" {
    let (dx,dy) = loc.mod.last()
    x += dx + (if dx != 0 { w } else { 0 })
    y += dy + (if dy != 0 { h } else { 0 })
  } else {
    panic("unknown")
  }
  return (x,y)
}

/// This function renders code from a subset of roff's module PIC
#let pic(
  /// the PIC code
  /// -> raw
  code) = {
  let statements = ()
  let tokens = ()
  while code.len() > 0 {
    let c = code.at(0)
    if c in " \t\r" {
      code = code.slice(1)
    } else if c in "\n;" {
      if tokens.len() > 0 {
        statements.push(parse_statement(tokens))
        tokens = ()
      }
      code = code.slice(1)
    } else if c in "+()," {
      tokens.push(("op",c))
      code = code.slice(1)
    } else if c == "\"" {
      let m = code.match(regex("\"[^\"]*\""))
      tokens.push(("str", m.at("text").slice(1,-1)))
      code = code.slice(m.at("end"))
    } else {
      let found = false
      for kw in ("box", "arrow", "down", "up", "right", "left", "move", "at", "from", "to", "with", "dashed", "last") {
        if code.starts-with(kw) {
          tokens.push(("kw", kw))
          code = code.slice(kw.len())
          found = true
          break
        }
      }

      if not found {
        for ak in ("<->", "->", "<-") {
          if code.starts-with(ak) {
            tokens.push(("arrow-kind", ak))
            code = code.slice(ak.len())
            found = true
          }
        }
      }

      if not found {
        let m = code.match(regex("^[1-9][0-9]*?(st|nd|rd|th)"))
        if m != none {
          let n = if m.text == "1st" { 1 }
          else if m.text == "2nd" { 2 }
          else if m.text == "3rd" { 2 }
          else if not m.text.ends-with("th") { panic(m.text) }
          else { int(m.text.slice(-2)) }
          tokens.push(("nth", n))
          code = code.slice(m.text.len())
          found = true
        }
      }

      if not found {
        let m = code.match(regex("^[0-9]+(\.[0-9]+)?"))
        if m != none {
          tokens.push(("num", float(m.text)))
          code = code.slice(m.text.len())
          found = true
        }
      }

      if not found {
        for kw in (".start", ".end", ".ne", ".nw", ".se", ".sw", ".n", ".e", ".w", ".s", ".c") {
          if code.starts-with(kw) {
            tokens.push(("dot-corner", kw.slice(1)))
            code = code.slice(kw.len())
            found = true
            break
          }
        }
      }

      let m = code.match(regex("^([A-Z][a-zA-Z_0-9]*)\s*:"))
      if not found and m != none {
        tokens.push(("label", m.captures.first()))
        code = code.slice(m.end)
        found = true
      }
      let m = code.match(regex("^[a-zA-Z][a-zA-Z_0-9]*"))
      if not found and m != none {
        tokens.push(("id", m.text))
        code = code.slice(m.end)
        found = true
      }

      if not found {
        panic("unable to tokenize", code)
      }
    }
  }
  if tokens.len() > 0 { statements.push(parse_statement(tokens)); }

  set text(8pt)

  figure(canvas({
    import draw: *
    stroke(.5pt)

    let (boxw, boxh) = (2, 1)
    let (arroww, arrowh) = (1.5,1)
    let (movew, moveh) = (1,1)
    let mark = (fill:black, scale:.75)
    let (x,y,lastx,lasty,dir,anchor) = (0,0,0,0,"right","center")
    let labels = (:)
    let history = (box:(), arrow:())

    for (i,st) in statements.enumerate() {
      circle((x,y), radius:1pt, fill:red, stroke:none)
      content((x,y), text(7pt)[#i], anchor:"south-west", anchor-sep:10pt)

      let (dirx, diry) = dirs-delta(dir)
      let (w,h) = (
        box:(boxw,boxh),
        arrow:(calc.abs(arroww*dirx), calc.abs(arrowh*diry)),
        move:(movew,moveh),
      ).at(st.command, default:(0,0))

      if st.from != none and st.to != none and st.command in ("arrow", "line", "arc") {
        if st.command == "arc" { panic("todo") }
        (x,y) = compute-loc(st.from, labels, history)
        let (tx,ty) = compute-loc(st.to, labels, history)
        w = tx - x
        h = ty - y
      } else if st.from == none and st.to != none {
        assert(st.command == "move")
        (x,y) = compute-loc(st.to, labels, history)
        (w,h) = (0,0)
        anchor = "center"
      } else if st.from != none {
        (x,y) = compute-loc(st.from, labels, history)
        anchor = "center"
      } else if st.at != none {
        (x,y) = compute-loc(st.at, labels, history)
        anchor = "center"
      }

      let (dx,dy) = (center:(0,0), west:(w/2,0), east:(-w/2,0), north:(0,-h/2), south:(0,h/2)).at(anchor)

      if st.with != none {
        if st.with == "start" {}
        else if st.with == "end" { x -= w; y -= h }
        else {
          dx = if "w" in st.with { w/2 } else if "e" in st.with { -w/2 } else { 0 }
          dy = if "s" in st.with { h/2 } else if "n" in st.with { -h/2 } else { 0 }
        }
      }

      group({
        if "dashed" in st.mod { stroke((thickness:.5pt, dash:"dashed")) }

        translate((x, y))
        if st.command in ("box", "circle", "ellipse") { translate((dx, dy)) }

        if st.command == "box" {
          rect((-boxw/2,-boxh/2), (rel:(boxw,boxh)))
          content((0,0), align(center, st.text.join([\ ])))
          history.box.push((x,y,w,h))

        } else if st.command == "arrow" {
          let _mark = mark
          if "->" in st.mod { _mark.insert("end", ">") }
          if "<-" in st.mod { _mark.insert("start", ">") }

          line((0,0), (rel:(w*dirx, h*diry)), mark:_mark)
          content((0,0), align(center, st.text.join([\ ])))
          history.arrow.push((x + w/2,y + h/2,w,h))

        } else if st.command == "move" {
          if st.dirs.len() > 0 {
            (w,h) = (0,0)
            for d in st.dirs {
              dir = d.first()
              let (_x,_y) = dirs-delta(dir)
              w += movew * _x * d.last()
              h += moveh * _y * d.last()
            }
            (dirx, diry) = (1,1)
          }
          content((w*dirx/2, h*diry/2), align(center, st.text.join([\ ])))

        } else if st.command in ("down", "up", "right", "left") {
          dir = st.command
        }
      })

      if st.label != none {
        let _x = x + dirx * w * (if anchor == "center" { 0 } else { 0.5 })
        let _y = y + diry * h * (if anchor == "center" { 0 } else { 0.5 })
        labels.insert(st.label, (_x,_y,w,h))
      }
      // TODO: maybe remove dirx diry

      x += dirx * w * (if anchor == "center" and st.command in obj-close { 0.5 } else { 1 })
      y += diry * h * (if anchor == "center" and st.command in obj-close { 0.5 } else { 1 })
      anchor = dir-anchor(dir)
    }

    content((-1,0), [#labels], anchor:"east")
  }))

  [#statements]
}


#let read_roff_file(path) = read(path).matches(regex("(?s:\.PS\s*\n(.*?)\.PE)")).map(x => x.at("captures").at(0))


#figure(block(
  stroke: .5pt,
  inset: (x: -7cm, top:-1cm, bottom: -20cm),
  clip: true,
  image("test-0.png")
))
#pic(read_roff_file("test.roff").at(0))

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
