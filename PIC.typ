#import "@preview/cetz:0.3.4": canvas, draw

// TODO: starts-with -> starts-with with other things

#let primitives = ("box", "circle", "ellipse", "arc", "line", "arrow", "spline", "move")
#let dirs = ("up", "down", "left", "right")

#let drop(code, len) = code.slice(len).trim(" ")

#let parse-in-array(code, array) = {
  for prefix in array  {
    if code.starts-with(prefix) and (code.len() == prefix.len() or code.at(prefix.len()).match(regex("[a-zA-Z]")) == none) {
      return (drop(code, prefix.len()), prefix)
    }
  }
  (code, "")
}

#let parse-direction(code) = parse-in-array(code, dirs)
#let parse-primitive(code) = parse-in-array(code, primitives)
#let parse-placement(code) = parse-in-array(code, ("center", "ljust", "rjust", "above", "below"))
#let parse-dot-corner(code) = parse-in-array(code, (".n", ".e", ".w", ".s", ".ne", ".nw", ".se", ".sw", ".c", ".start", ".end"))

#let parse-label(code) = {
  let m = code.match(regex("^([A-Z][a-zA-Z0-9]*)"))
  if m != none {
    let label = m.captures.at(0)
    return (drop(code, label.len()), label)
  }
  (code, "")
}

#let parse-text(code) = {
  let m = code.match(regex("^\"(.*)\"")) // TODO: escape "
  if m != none {
    let text = m.captures.at(0)
    let placement = ""
    (code, placement) = parse-placement(code)
    return (code, (text:text, placement:placement))
  }
  // TODO: sprintf
  (code, none)
}


#let parse-place(code) = {
  let label = ""
  (code, label) = parse-label(code)
  if label != "" {
    let place = (label:label)
    let dot-cor = ""
    (code, dot-cor) = parse-dot-corner(code)
    if dot-cor != "" {
      place.dot-cor = dot-cor
    }
    return (code, place)
  }
  (code, none)
}

#let parse-expr(code) = {
  let parse-op-expr(code, lhs) = {
    if lhs == none {
      return (code, none)
    }
    for op in ("+", "-", "*", "/", "%", "^", "!=", "==", "<", ">", ">=", "<=", "||", "&&") {
      if code.starts-with(op) {
        code = drop(code, op.len())
        let subexpr = none
        (code, subexpr) = parse-expr(code)
        if subexpr == none {
          return (code, none)
        }
        let expr = (:)
        expr.insert(op, (lhs, subexpr))
        return (code, expr)
      }
    }
    return (code, lhs)
  }

  let expr = (:)
  let subexpr = none

  for prefix in ("!", "-") {
    if code.starts-with(prefix) {
      code = drop(code, prefix.len())
      (code, subexpr) = parse-expr(code)
      if subexpr == none {
        return (code, none)
      }
      expr.insert(prefix, subexpr)
      return parse-op-expr(code, expr)
    }
  }

  if code.starts-with("(") {
    code = drop(code, 1)
    (code, subexpr) = parse-expr(code)
    if subexpr == none {
      return (code, none)
    }
    if not code.starts-with(")") {
      return (code, none)
    }
    code = drop(code, 1)
    return parse-op-expr(code, subexpr)
  }

  // TODO: variable

  let m = code.match(regex("^([0-9]+(\.[0-9]+([eE][0-9]+)?)?)"))
  if m != none {
    let num = m.captures.at(0)
    return parse-op-expr(drop(code, num.len()), float(num))
  }

  let place = none
  (code, place) = parse-place(code)
  if place != none {
    for suf in (".x", ".y", ".ht", ".wid", ".rad") {
      if code.starts-with(suf) {
        expr.insert(suf, place)
        return parse-op-expr(drop(code, suf.len()), expr)
      }
    }
  }

  if code.starts-with("rand()") {
    return parse-op-expr(drop(code, 6), ("rand"))
  }

  if code.starts-with("atan2(") {
    code = drop(code, 6)
    (code, subexpr) = parse-expr(code)
    if subexpr == none {
      return (code, none)
    }
    if not code.starts-with(",") {
      return (code, none)
    }
    code = drop(code, 1)
    let expr2 = none
    (code, expr2) = parse-expr(code)
    if expr2 == none {
      return (code, none)
    }
    if not code.starts-with(")") {
      return (code, none) 
    }
    return parse-op-expr(drop(code, 1), ("atan2": (subexpr,expr2)))
  }

  for f in ("min(", "max(") {
    if code.starts-with(f) {
      code = drop(code, f.len())
      let args = ()
      (code, subexpr) = parse-expr(code)
      while subexpr != none {
        args.push(subexpr)
        if code.starts-with(")") {
          break
        }
        if not code.starts-with(",") {
          return (code, none)
        }
        code = drop(code, 1)
        (code, subexpr) = parse-expr(code)
      }
      if not code.starts-with(")") {
        return (code, none)
      }
      expr.insert(f.slice(0,-1), args)
      return parse-op-expr(drop(code, 1), expr)
    }
  }

  for f in ("sin(", "cos(", "log(", "exp(", "sqrt(", "int(") {
    if code.starts-with(f) {
      code = drop(code, f.len())
      (code, subexpr) = parse-expr(code)
      if subexpr == none {
        return (code, none)
      }
      expr.insert(f.slice(0,-1), subexpr)
      return parse-op-expr(code, expr)
    }
  }

  (code, none)
}

#let parse-pos(code) = {
  let place = none
  (code, place) = parse-place(code)
  if place != none {
    if code.starts-with("+") or code.starts-with("-") {
      let op = code.at(0)
      code = drop(code, 1)
      if code.starts-with("(") {
        code = drop(code, 1)
        let expr1 = none
        let expr2 = none
        (code, expr1) = parse-expr(code)
        if expr1 != none { return (code, none) }
        if not code.starts-with(",") { return (code, none) }
        code = drop(code, 1)
        (code, expr2) = parse-expr(code)
        if expr2 != none { return (code, none) }
        if not code.starts-with(")") { return (code, none) }
        code = drop(code, 1)
        place.insert(op, (expr1, expr2))
        return (code, place)
      }
    }
  }
  (code, place)
}

#let parse-corner(code) = {
  (code, none)
}


#let parse-attribute(code) = {
  let attr = ""
  (code, attr) = parse-in-array(code, ("<->", "->", "<-", "then", "invis", "solid", "same"))
  if attr != "" {
    return (code, attr)
  }

  for attr in ("ht", "height", "wid", "width", "rad", "radius", "diam", "diameter", "fill") {
    if code.starts-with(attr) {
      code = drop(code, attr.len())
      let expr = none
      (code, expr) = parse-expr(code)
      if expr == none {
        return (code, none)
      }
      let a = (:)
      a.insert(attr, expr)
      return (code, a)
    }
  }
  for attr in ("up", "down", "left", "right", "dotted", "dashed", "chop") {
    if code.starts-with(attr) {
      code = drop(code, attr.len())
      let expr = none
      (code, expr) = parse-expr(code)
      let a = (:)
      a.insert(attr, expr)
      return (code, a)
    }
  }
  for attr in ("from", "to", "at") {
    if code.starts-with(attr) {
      code = drop(code, attr.len())
      let pos = none
      (code, pos) = parse-pos(code)
      if pos == none {
        return (code, none)
      }
      let a = (:)
      a.insert(attr, pos)
      return (code, a)
    }
  }
  if code.starts-with("with") {
    code = drop(code, 4)
    let corner = none
    (code, corner) = parse-corner(code)
    if corner == none {
      return (code, none)
    }
    return (code, (with:corner))
  }
  if code.starts-with("by") {
    code = drop(code, 2)
    let expr1 = none
    (code, expr1) = parse-expr(code)
    if expr1 == none {
      return (code, none)
    }
    let expr2 = none
    (code, expr2) = parse-expr(code)
    if expr2 == none {
      return (code, none)
    }
    return (code, (by:(expr1, expr2)))
  }
  let text = none
  (code, text) = parse-text(code)
  if text != none {
    return (code, text)
  }
  parse-expr(code)
}

#let parse-command(code) = {
  let cmd = (cmd:"")

  let label = ""
  (code, label) = parse-label(code)
  if label != "" {
    if not code.starts-with(":") {
      return (code, none)
    }
    code = drop(code, 1)
    cmd.insert("label", label)
  }

  let primitive = ""
  (code, primitive) = parse-primitive(code)
  if primitive == "" {
    let dir = ""
    (code, dir) = parse-direction(code)
    if dir == "" {
      return (code, none)
    }
    primitive = dir
  }
  cmd.cmd = primitive

  let attrs = ()
  let attr = none
  (code, attr) = parse-attribute(code)
  attrs.push(attr)

  if attrs.len() > 0 {
    cmd.insert("attrs", attrs)
  }

  (code, cmd)
}

#let parse-statement(code) = {
  if code.starts-with(regex("[;\n]")) {
    code = drop(code, 1)
  }
  parse-command(code)
}

#let parse(code) = {
  let statements = ()
  let st = none
  (code, st) = parse-statement(code)
  while st != none and code.len() > 0 {
    (code, st) = parse-statement(code)
    statements.push(st)
  }
  statements.push((rest:code))
  statements
}

#let render(commands, debug:false) = {
  let (boxw, boxh) = (1.5,1)
  let (x,y) = (0,0)

  figure(canvas({
    import draw:*
    stroke(.5pt)

    for command in commands {
    }
  }))
}

#let pic(code, debug:false) = {
  let commands = parse(code)
  render(commands, debug:debug)
  [#commands]
}

#let read_roff_file(path) = read(path).matches(regex("(?s:\.PS\s*\n(.*?)\.PE)")).map(x => x.at("captures").at(0))
