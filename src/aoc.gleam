import gleam/list
import gleam/int
import gleam/io
import gleam/string
import gleam/erlang/file

const max_dir_size = 100_000

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
}

type Command {
  CdUp
  Cd(path: String)
  Ls
}

type FsTree {
  Dir(name: String, size: Int, sub_trees: List(FsTree))
  File(name: String, size: Int)
}

fn fs_size(node: FsTree) -> Int {
  case node {
    Dir(_, size, _) -> size
    File(_, size) -> size
  }
}

fn parse_command(command: String) -> Command {
  let command_parts = string.split(command, " ")
  case command_parts {
    ["$", "ls"] -> Ls
    ["$", "cd", ".."] -> CdUp
    ["$", "cd", path] -> Cd(path: path)
  }
}

fn parse_directory_entry(raw_entry: String) -> Result(FsTree, Nil) {
  let [specifier, name] = string.split(raw_entry, " ")

  case specifier {
    "dir" -> Error(Nil)
    raw_size -> {
      assert Ok(size) = int.parse(raw_size)
      Ok(File(name, size))
    }
  }
}

fn parse_inner(lines: List(String)) -> #(List(FsTree), List(String)) {
  let [cmd, ..rest] = lines

  let #(output_lines, commands) =
    rest
    |> list.split_while(fn(line) { !string.starts_with(line, "$") })
  let dir_content =
    output_lines
    |> list.filter_map(parse_directory_entry)

  case parse_command(cmd), commands {
    CdUp, _ -> #([], commands)
    Ls, [] -> #(dir_content, commands)
    Ls, _ -> {
      let #(inner, cmds) = parse_inner(commands)
      #(
        [dir_content, inner]
        |> list.flatten,
        cmds,
      )
    }
    Cd(rel_dir), [] -> #([Dir(name: rel_dir, size: 0, sub_trees: [])], commands)
    Cd(rel_dir), _ -> {
      let #(inner, cmds) = parse_inner(rest)
      let size =
        inner
        |> list.map(fs_size)
        |> int.sum
      #([Dir(name: rel_dir, size: size, sub_trees: inner)], cmds)
    }
  }
}

fn parse_file_system(lines: List(String)) -> List(FsTree) {
  let [command, ..lines_rest] = lines

  let #(output_lines, commands) =
    lines_rest
    |> list.split_while(fn(line) { !string.starts_with(line, "$") })

  let dir_content =
    output_lines
    |> list.filter_map(parse_directory_entry)

  let #(current, rest) = case parse_command(command) {
    Ls -> {
      let #(inner, cmds) = parse_inner(commands)
      #(
        [dir_content, inner]
        |> list.flatten,
        cmds,
      )
    }
    CdUp -> #([], commands)
    Cd(rel_dir) -> {
      let #(inner, cmds) = parse_inner(commands)
      let size =
        inner
        |> list.map(fs_size)
        |> int.sum
      #([Dir(name: rel_dir, size: size, sub_trees: inner)], cmds)
    }
  }

  case rest {
    [] -> current
    _ ->
      [current, parse_file_system(rest)]
      |> list.flatten
  }
}

fn get_dir_sizes(fs: FsTree) -> List(#(String, Int)) {
  case fs {
    File(_, _) -> []
    Dir(name, size, subs) ->
      subs
      |> list.map(get_dir_sizes)
      |> list.flatten
      |> list.prepend(#(name, size))
  }
}

fn format_fs(tree: FsTree, indent: String) -> List(String) {
  case tree {
    File(name, size) -> {
      let output =
        ["File", name, int.to_string(size)]
        |> string.join(" ")
      [indent <> output]
    }
    Dir(name, size, sub_trees) -> {
      let dir_output = indent <> "Dir " <> name <> " " <> int.to_string(size)
      let sub_fs_output =
        sub_trees
        |> list.map(fn(fs) { format_fs(fs, "  " <> indent) })
        |> list.flatten
      [dir_output, ..sub_fs_output]
    }
  }
}

pub fn main() {
  let [_, ..lines] = load_input_lines()

  let file_system =
    lines
    |> parse_file_system
  let total_size =
    file_system
    |> list.map(fs_size)
    |> int.sum
  let root = Dir(name: "/", size: total_size, sub_trees: file_system)

  format_fs(root, "")
  |> list.each(io.println)

  let dir_sizes = get_dir_sizes(root)
  let small_dirs =
    dir_sizes
    |> list.filter(fn(s) { s.1 <= max_dir_size })
  small_dirs
  |> list.map(io.debug)
  small_dirs
  |> list.map(fn(s) { s.1 })
  |> int.sum
  |> io.debug
}
