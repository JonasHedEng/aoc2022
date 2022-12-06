import gleam/list
import gleam/int
import gleam/io
import gleam/order
import gleam/string
import gleam/erlang/file

const marker_size = 4

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
}

fn index_unique(indexed_seen: #(Int, List(String))) -> Result(Int, Nil) {
  let #(index, recently_seen) = indexed_seen
  let uniques =
    recently_seen
    |> list.unique
    |> list.length

  case int.compare(uniques, marker_size) {
    order.Eq -> Ok(index)
    _ -> Error(Nil)
  }
}

fn scan_line(line: String) -> Int {
  let recently_seens =
    line
    |> string.to_graphemes
    |> list.window(by: marker_size)

  assert Ok(index) =
    recently_seens
    |> list.index_map(fn(i, recently_seen) { #(i+marker_size, recently_seen) })
    |> list.find_map(index_unique)

  index
}

pub fn main() {
  let lines = load_input_lines()

  lines
  |> list.map(scan_line)
  |> io.debug
}
