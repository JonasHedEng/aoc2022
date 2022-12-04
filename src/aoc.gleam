import gleam/list
import gleam/int
import gleam/io
import gleam/iterator
import gleam/pair
import gleam/set.{Set}
import gleam/string
import gleam/erlang/file

const item_types = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
}

fn priority(for item_type: String) -> Int {
  let item_type_list =
    item_types
    |> string.to_graphemes
  let enumerated =
    item_type_list
    |> iterator.from_list
    |> iterator.index

  assert Ok(#(index, _)) =
    enumerated
    |> iterator.find(fn(en) { pair.second(en) == item_type })

  index + 1
}

fn overlapping_sets(among sets: List(Set(String))) -> Set(String) {
  case sets {
    [x] -> x
    [x, ..rest] -> set.intersection(x, overlapping_sets(rest))
  }
}

fn find_overlap(among group: List(String)) -> String {
  let groups_types: List(Set(String)) =
    group
    |> list.map(string.to_graphemes)
    |> list.map(set.from_list)

  let overlap_set = overlapping_sets(among: groups_types)
  let overlap =
    overlap_set
    |> set.to_list
    |> string.concat
  overlap
}

pub fn main() {
  let lines = load_input_lines()

  let groups =
    lines
    |> list.sized_chunk(into: 3)

  let overlapping =
    groups
    |> list.map(find_overlap)
  let scores =
    overlapping
    |> list.map(priority)

  io.debug(
    scores
    |> int.sum,
  )
}
