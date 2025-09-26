#import "@preview/cetz:0.3.4": canvas, draw

#let primitives = ("box", "circle", "ellipse", "arc", "line", "arrow", "spline", "move")
#let dirs = ("up", "down", "left", "right")

#let drop(code, len) = code.slice(len).trim()

#let parse-direction(code) = {
  for dir in dirs {
    if code.starts-with(dir) {
      return (drop(code, dir.len()), dir)
    }
  }
  (code, "")
}

#let parse-primitive(code) = {
  for primitive in primitives {
    if code.starts-with(primitive) {
      return (drop(code, primitive.len()), primitive)
    }
  }
  (code, "")
}

#let parse-label(code) = {
  let m = code.match(regex("^([a-zA-Z]+):"))
  if m != none {
    let label = m.captures.at(0)
    return (drop(code, label.len()+1), label)
  }
  (code, "")
}

#let parse-command(code) = {
  let cmd = (cmd:"")

  let label = ""
  (code, label) = parse-label(code)
  if label != "" {
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

  let direction = ""
  let dir = ()
  (code, direction) = parse-direction(code)
  while direction != "" {
    dir.push(direction)
    (code, direction) = parse-direction(code)
  }
  if dir.len() > 0 {
    cmd.insert("dir", dir)
  }

  (code, cmd)
}

#let parse-statement(code) = {
  if code.starts-with(";") {
    code = drop(code, 1)
  }
  parse-command(code)
}

#let parse(code) = {
  let statements = ()
  let st = (:)
  while st != none and code.len() > 0 {
    (code, st) = parse-statement(code)
    statements.push(st)
  }
  statements.push((rest:code))
  statements
}

#let pic(code, debug:false) = {
  let commands = parse(code)

  let (boxw, boxh) = (1.5,1)
  let (x,y) = (0,0)

  figure(canvas({
    import draw:*
    stroke(.5pt)

    for command in commands {
    }
  }))

  [#commands]
}

#let read_roff_file(path) = read(path).matches(regex("(?s:\.PS\s*\n(.*?)\.PE)")).map(x => x.at("captures").at(0))
