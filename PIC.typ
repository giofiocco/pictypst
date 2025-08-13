#import "@preview/cetz:0.3.4": canvas, draw

#let primitives = ("box", "circle", "ellipse", "arc", "line", "arrow", "spline", "move")
#let dirs = ("up", "down", "left", "right")

#let parse-expr(code) = {
  return (0, (:))
}

#let parse(code) = {
  let statements = ()

  let commands = code.split(regex("[\n;]")).filter(x => x.len() > 0)
  for command in commands {
    let statement = (cmd:"none", text:())
    command = command.trim()

    let m = command.match(regex("^([a-zA-Z]+):(.*)$"))
    if m != none {
      statement.insert("label", m.captures.at(0))
      command = m.captures.at(1).trim()
    }

    for primitive in primitives {
      if command.starts-with(primitive) {
        statement.cmd = primitive
        command = command.slice(primitive.len()).trim()

        while command.len() > 0 {
          if command.starts-with("height") {
            statement.insert("H", true)
            command = command.slice(6).trim()

          } else if command.starts-with("width") {
            statement.insert("W", true)
            command = command.slice(6).trim()

          } else if command.starts-with("dashed") {
            statement.insert("dashed", true)
            command = command.slice(6).trim()

          } else if command.match("^\".*?\"") != none {
            let m = command.match("^\"(.*?)\"(.*)$")
            if m != none {
              statement.text.push(m.captures.at(0))
              command = m.captures.at(1).trim()
            } else {
              panic()
            }

          } else {
            break
          }
        }

        break
      }
    }

    if statement.cmd == "none" {
      for dir in dirs {
        if command.starts-with(dir) {
          statement.cmd = dir
          command = command.slice(dir.len()).trim()
          break
        }
      }
    }

    if command.len() > 0 {
      statement.insert("rest", command)
    }
    statements.push(statement)
  }

  return statements
}

#let pic(code) = {
  [#parse(code)]
}

#let read_roff_file(path) = read(path).matches(regex("(?s:\.PS\s*\n(.*?)\.PE)")).map(x => x.at("captures").at(0))
