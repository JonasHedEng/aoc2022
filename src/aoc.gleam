import gleam/list
import gleam/int
import gleam/io
import gleam/order.{Eq, Gt, Lt}
import gleam/string
import gleam/erlang/file

fn load_input_lines() -> List(String) {
  assert Ok(content) = file.read("input.txt")

  string.split(content, on: "\n")
  |> list.filter(fn(line) { !string.is_empty(line) })
}

type Range {
  Range(from: Int, to: Int)
}

type Relation {
  Disjoint
  Overlapping
  Contained
}

fn relation_between(range_pair: #(Range, Range)) -> Relation {
  let #(a, b) = range_pair
  let from_comp = int.compare(a.from, b.from)
  let to_comp = int.compare(a.to, b.to)

  let is_disjoint = b.from - a.to > 0 || a.from - b.to > 0

  case is_disjoint {
    True -> Disjoint
    False -> case from_comp, to_comp {
      Eq, _ | _, Eq -> Contained
      Lt, Gt | Gt, Lt -> Contained
      Lt, Lt | Gt, Gt -> Overlapping
    }
  }
}

fn parse_range(raw: String) -> Range {
  assert Ok([from, to]) =
    raw
    |> string.split(on: "-")
    |> list.try_map(int.parse)

  Range(from: from, to: to)
}

fn parse_range_pairs(lines: List(String)) -> List(#(Range, Range)) {
  lines
  |> list.map(fn(line) {
    assert Ok(#(first, second)) =
      line
      |> string.split_once(on: ",")

    #(parse_range(first), parse_range(second))
  })
}

pub fn main() {
  let lines = load_input_lines()

  let parsed =
    lines
    |> parse_range_pairs

  let contained =
    parsed
    |> list.map(relation_between)
    |> list.filter(fn(r) { r == Contained || r == Overlapping })

  io.debug(list.length(contained))
}
