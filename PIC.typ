#import "@preview/cetz:0.3.4": canvas, draw

#let vecsum(a,b) = a.zip(b).map(x => x.sum())

#let parse_statement(tokens) = {
  let command = tokens.pop()
  let statement = (command:command, text:())
  if tokens.len() > 0 {
    for t in tokens {
      if type(t) == array and t.first() == "str" {
        assert(t.len() == 2)
        statement.text.push(t.last())
      }
    }
  }
}

/// This function renders code from a subset of roff's module PIC
#let pic(
  /// the PIC code
  /// -> raw
  code) = {

  let kws = ("box", "arrow", "down", "up", "right", "left")

  let statements = ()
  let tokens = ()
  while code.len() > 0 {
    let c = code.at(0)
    if c in " \t\r" {
      code = code.slice(1)
    } else if c in "\n;" {
      statements.push(parse_statement(tokens))
      tokens = ()
      code = code.slice(1)
    } else if c == "\"" {
      let m = code.match(regex("\"[^\"]*\""))
      tokens.push(("str", m.at("text").slice(1,-1)))
      code = code.slice(m.at("end"))
    } else {
      let found = false
      for kw in kws {
        if code.starts-with(kw) {
          tokens.push(kw)
          code = code.slice(kw.len())
          found = true
          break
        }
      }

      if not found {
        panic("unable to tokenize", code)
      }
    }
  }
  if tokens.len() > 0 { statements.push(tokens); }

  canvas({
    import draw: *
    stroke(.5pt)

    let dirs = (right: (1,0), left: (-1,0), up: (0, 1), down: (0, -1))
    let (boxw, boxh) = (2, 1)
    let (arroww, arrowh) = (2,1)
    let mark = (end:">", fill:black, scale:.75)
    let (x,y,dir) = (0, 0, "right")

    let last = none

    for (i,st) in statements.enumerate() {
      if last == none {
        let (x,y) = (0,0)
      } else if dir == "right" {
        let (_x,_y,w,h) = last
        (x,y) = (_x + w, _y)
      } else if dir == "down" {
        let (_x,_y,w,h) = last
        (x,y) = (_x, _y + h)
      }

      if st.first() == "box" {
        //let (dx, dy) = (center:(0,0), left:(-boxw/2,0), up:(0,-boxh/2)).at(anchor)
        let(dx,dy) = (0,0)
        group({
          translate((x,y))
          rect((-boxw/2, -boxh/2), (rel:(boxw, boxh)))
        })
        //rect((x - boxw/2 + dx, y - boxh/2 + dy), (rel:(boxw, boxh)))
        for v in st.slice(1) {
          if type(v) != str and v.first() == "str" {
            content((x,y), v.last())
          }
        }
        last = (x,y,boxw,boxh)
      } else if st.first() == "arrow" {
        // let (dx, dy) = (center:(0,0), left:(-arroww/2,0), up: (0,-arrowh/2)).at(anchor)
        let(dx,dy) = (0,0)
        let (dirx, diry) = dirs.at(dir)
        let l = (arroww * dirx, arrowh * diry)
        line((x + dx - l.at(0)/2,y + dy - l.at(1)/2), (rel:l), mark:mark)
        last = (x,y,..l)
      } else if st.first() == "down" {
        dir = "down"
      }

      circle((x,y), radius:1pt, fill:red, stroke:none)
      content((x,y), text(7pt)[#i], anchor:"south-west", anchor-sep:10pt)
    }
  })

  [#statements]
}


#let read_roff_file(path) = read(path).matches(regex("(?s:\.PS\s*\n(.*?)\.PE)")).map(x => x.at("captures").at(0))


#figure(block(
  stroke: .5pt,
  inset: (x: -7cm, bottom: -20cm),
  image("test.png")
))
#pic(read_roff_file("test.roff").at(0))
